# 学习流程重设计

## 背景

当前学习流程过于简单：每个字答一次就过，答错可重试但无强化机制。需要引入练习模式、动态队列、三级掌握状态，让学习更有效。

## 设计目标

1. 答错的字通过练习环节强化，并在后续随机重现
2. 三级掌握状态（学习/疑难/熟识）跨 session 持久化
3. 练习环节不计入 SM-2 统计
4. 疑难字优先出现，熟识字不再自动出现

## 确认的设计决策

- 连续答对次数阈值：**3次**
- 练习模式：同步阻塞，对着字写对2次 + 盲写对1次
- 练习环节不算 SM-2
- 连续计数只在当前 session 内有效
- 首次学习和复习 session 走同样流程

---

## 掌握状态（MasteryLevel）

### 枚举值

| 值 | 含义 | 复习行为 |
|---|---|---|
| `.new` | 从未练习 | 正常出现 |
| `.learning` | 学习中 | 按 SM-2 间隔复习 |
| `.difficult` | 疑难 | 优先出现 |
| `.mastered` | 熟识（用户确认） | 不再自动出现 |

### 状态转移

```
new ──(首次练习)──→ learning
learning ──(session内连续对3次 + 用户确认)──→ mastered
learning ──(session内连续错3次)──→ difficult
difficult ──(session内不错且连续对3次)──→ learning
mastered ──(用户手动重置)──→ learning
```

### 模型变更

文件：`AnkiAnna/AnkiAnna/Models/CharacterStats.swift`

```swift
enum MasteryLevel: String, Codable {
    case new
    case learning
    case difficult   // 新增
    case mastered
}
```

- 移除 `isDifficult` 计算属性（被 `.difficult` 状态替代）
- 移除 `isManuallyReset`（被状态转移替代）
- `updateMasteryLevel()` 改为不自动计算，由 session 逻辑显式设置
- 新增 `markMastered()` / `markDifficult()` 方法

---

## Session 内状态追踪

### CharacterSessionState

ViewModel 内部结构，不持久化：

```swift
struct CharacterSessionState {
    var consecutiveCorrect: Int = 0   // 本 session 连续答对（主流程计数，练习模式不算）
    var consecutiveWrong: Int = 0     // 本 session 连续答错
    var hasError: Bool = false        // 本 session 是否出过错
}
```

### 主队列管理

- `queue: [Card]` — 动态队列，初始随机排列，疑难字排前面
- 不再使用 `currentIndex` 线性遍历，改为 `queue.removeFirst()` 消费式
- 答错的字练习完成后，随机插入 `queue[1...]` 中的某个位置

---

## 流程状态机

### 主流程

```
┌─────────────────────────────────────────────────────┐
│                    显示题目                           │
│              （自动朗读语境）                          │
└───────────┬─────────────────────────┬───────────────┘
            │ 答对                     │ 答错
            ▼                         ▼
    ┌───────────────┐         ┌──────────────────┐
    │ consecutiveC++│         │ consecutiveW++   │
    │ consecutiveW=0│         │ consecutiveC=0   │
    │ hasError不变  │         │ hasError=true    │
    │ SM-2(quality=4)│        │ SM-2(quality=1)  │
    └───────┬───────┘         └───────┬──────────┘
            │                         │
            ▼                         ▼
    ┌───────────────┐         ┌──────────────────┐
    │ 判断退出条件    │         │ 连续错几次？      │
    └───────┬───────┘         └───┬────┬────┬────┘
            │                  1/2次  │   3次
            │                     │   │    │
            │                     ▼   │    ▼
            │          进入练习模式    │  进入练习模式
            │          练习完成后     │  练习完成后
            │          插回队列随机位置│  标记疑难
            │                        │  移出队列
            ▼                        │
    ┌───────────────────────┐        │
    │ 连续对3次？             │        │
    │                       │        │
    │ 是 + 状态=difficult:  │        │
    │   → 移入learning      │        │
    │   → 本次结束          │        │
    │                       │        │
    │ 是 + 状态=learning:   │        │
    │   → 询问"完全掌握？"   │        │
    │   → 是: 标mastered    │        │
    │   → 否: 本次结束      │        │
    │                       │        │
    │ 否 + hasError         │        │
    │   + 连续对>=2:        │        │
    │   → 本次结束          │        │
    │                       │        │
    │ 否: 继续队列下一个     │        │
    └───────────────────────┘        │
                                     │
    ◄────────────────────────────────┘
```

### 练习模式（PracticeMode）

答错后同步进入，阻塞主流程：

```
Phase 1: 看字写（显示正确答案 + 手写区）
  → 写对: phase1Count++
  → 写错: 重来（不计数，不限次）
  → phase1Count == 2 时进入 Phase 2

Phase 2: 盲写（隐藏正确答案 + 手写区）
  → 写对: 练习完成，回到主流程
  → 写错: 回到 Phase 1 重新开始（phase1Count 归零）
```

练习模式中所有书写不调用 SM-2，不记录 ReviewRecord，不更新 CharacterStats。

---

## 队列生成逻辑

### 初始队列构建

```swift
func buildSessionQueue(cards: [Card], characterStats: [CharacterStats]) -> [Card] {
    // 1. 过滤掉 mastered 的字
    // 2. SM-2 选出到期的字
    // 3. difficult 排前面
    // 4. 其余随机排列
}
```

### 答错后插回

```swift
func reinsertCard(_ card: Card) {
    guard !queue.isEmpty else {
        queue.append(card)
        return
    }
    // 随机插入 queue[0...] 中的某个位置（不插在最前面，至少间隔1个字）
    let insertIndex = Int.random(in: 1...queue.count)
    queue.insert(card, at: insertIndex)
}
```

注意：如果队列只剩0个字，直接 append。

---

## 退出条件汇总

| 字的情况 | 退出条件 | 后续 |
|---------|---------|------|
| 从未出错 + 连续对3次 + 学习中 | 询问熟识 → 是=mastered / 否=退出 | mastered 不再自动复习 |
| 从未出错 + 连续对3次 + 疑难 | 移入learning + 退出 | 按 SM-2 正常复习 |
| 有过错误 + 连续对2次 | 退出 | 按 SM-2 正常复习 |
| 连续错3次 | 练习后标疑难 + 退出 | 下次优先出现 |

---

## 涉及文件变更

### 模型层
- `Models/CharacterStats.swift` — MasteryLevel 新增 `.difficult`，移除 `isDifficult`/`isManuallyReset`，新增 `markMastered()`/`markDifficult()`

### ViewModel 层
- `Views/Learning/LearningViewModel.swift` — **大幅重写**
  - 新增 `CharacterSessionState` 结构
  - 新增 `PracticeState` 结构（phase/count）
  - 改为动态队列消费模式
  - 练习模式提交逻辑（不走 SM-2）
  - 主流程退出判定逻辑
  - 队列插回逻辑

### 视图层
- `Views/Learning/LearningView.swift` — 新增练习模式 UI
  - 练习模式：显示正确字符 + 手写区（Phase 1）/ 仅手写区（Phase 2）
  - 练习进度指示（"对着写 1/2" / "盲写"）
  - 熟识确认 Alert
  - 疑难标记反馈

### 测试
- `AnkiAnnaTests/LearningViewModelTests.swift` — 需大量新增
  - 连续答对3次触发熟识询问
  - 连续答错3次标疑难
  - 答错后队列插回
  - 练习模式不计SM-2
  - 有错误连续对2次退出
  - 疑难→学习状态转移
- `AnkiAnnaTests/CharacterStatsTests.swift` — MasteryLevel 新枚举测试

### 不涉及
- TextbookSeeder / TextbookDataProvider — 无变更
- SM2Engine — 算法不变，只是调用时机变化
- CardLibraryView / AddCardView — 无变更

---

## 现有代码分析

### LearningViewModel 当前结构（需重写的部分）

| 现有 | 问题 | 新设计 |
|------|------|--------|
| `dueCards: [Card]` + `currentIndex` | 线性遍历，无法插回 | `queue: [Card]` 消费式 |
| `submitAnswer()` 直接算 SM-2 | 练习模式也会走 SM-2 | 主流程 `submitMainAnswer()` + 练习 `submitPracticeAnswer()` 分离 |
| `next()` 简单 +1 | 无退出判定 | `processNextInQueue()` 含状态判定 |
| `retry()` 简单重试 | 无练习模式 | 移除，改为练习模式 |
| `combo` 计数 | 可保留 | 保留，练习模式中不变 |
| `completedCount/totalCount` | 固定计数 | totalCount 动态（队列可能增长），completedCount 按退出的字计 |

### CharacterStats 需调整的部分

| 现有 | 调整 |
|------|------|
| `isDifficult` 计算属性 | 移除，用 `masteryLevel == .difficult` |
| `isManuallyReset: Bool` | 移除，状态转移由 session 逻辑管理 |
| `updateMasteryLevel()` 自动计算 | 改为只在显式调用 `markMastered()`/`markDifficult()` 时变更 |
| `recordReview()` 调用 `updateMasteryLevel()` | 移除自动调用，由 ViewModel 决定何时变更状态 |

---

## 实现顺序建议

1. **CharacterStats 模型变更** — 新增 `.difficult`，调整方法
2. **LearningViewModel 重写** — 核心状态机 + 队列管理 + 练习模式逻辑
3. **LearningView 练习模式 UI** — 看字写/盲写界面 + 熟识确认 Alert
4. **单元测试** — ViewModel 状态机各路径覆盖
5. **UI 测试更新** — 现有 LearningFlow UI 测试适配
