# AnkiAnna V2 功能设计

日期: 2026-03-09

## 概述

5 个功能模块 + 技术债务修复，将 AnkiAnna 从基础记忆卡片升级为完整的游戏化学习平台。

## 架构方案

**Card + CharacterStats 双模型**：保持 Card 用于学习机制，新增 CharacterStats 跟踪每字掌握状态。

## 1. 数据模型

### 新增 CharacterStats

```swift
@Model final class CharacterStats {
    var character: String        // 单个汉字
    var grade: Int               // 年级 1-5
    var semester: String         // "upper" / "lower"
    var lesson: Int              // 课号
    var lessonTitle: String      // 课文标题
    var words: [String]          // 组词

    // 掌握状态
    var masteryLevel: MasteryLevel  // .new / .learning / .mastered
    var practiceCount: Int
    var correctCount: Int
    var errorCount: Int
    var lastPracticed: Date?
    var isManuallyReset: Bool

    // SM-2 调度
    var ease: Double             // 默认 2.5
    var interval: Int            // 间隔天数
    var repetition: Int          // 连续正确次数
    var nextReviewDate: Date?
}

enum MasteryLevel: String, Codable {
    case new        // 从未练习
    case learning   // 正在学习 (repetition < 3)
    case mastered   // 已掌握 (repetition >= 3 且 interval >= 21天)
}
```

### DailySession 修复

```swift
@Model final class DailySession {
    var date: Date
    var targetCount: Int
    var completedCount: Int
    var correctCount: Int
    var newMastered: Int         // 今日新掌握字数
    var streak: Int
    var gameMode: String?
}
```

### Card 模型不变

继续用于所有学习模式。首次启动时从课本 JSON 预生成。

## 2. 预装字库

### 预装流程

App 首次启动时：
1. 遍历 10 个课本 JSON（1-5 年级上下册），为每字创建 CharacterStats（约 1500+ 字）
2. 为每字自动生成 Card + CardContexts（组词填空，使用 `phrasesFromTextbookWords`）
3. `@AppStorage("hasSeededTextbook")` 标记完成

### 数据来源

现有 JSON 格式：
```json
{ "lesson": 1, "title": "春夏秋冬", "type": "识字", "unit": 1,
  "characters": [{ "char": "春", "words": ["春天","春风","春雨"] }] }
```

用 `phrasesFromTextbookWords` 生成填空：春→["___天","春___"]。完全离线，不需 AI。

## 3. 字库浏览器（替代卡片库 tab）

### 导航结构

```
字库 tab
├── 搜索栏（汉字搜索）
├── 筛选器：年级(1-5) × 学期(上/下) × 掌握状态(全部/未学/学习中/已掌握)
├── 统计概览栏：已掌握 X/总数 Y | 学习中 Z | 易错字 W
└── 字符列表（按课文分组）
    ├── 第1课 春夏秋冬
    │   ├── 春 ✅ 练习12次 正确率92%
    │   ├── 风 🔄 练习5次 正确率60% ⚠️易错
    │   └── 雪 ⬜ 未练习
    └── ...
```

### 字符详情页

- 基本信息：字、年级、课文、组词
- 练习统计：总练习数、正确率、最后练习时间
- SM-2 状态：当前间隔、下次复习日期
- 操作按钮：「标记为未掌握」/「立即练习」

## 4. 游戏模式

### 入口

学习 tab 改为模式选择页：

| 模式 | 图标 | 说明 |
|------|------|------|
| 快速学习 | ⭐ | 每日任务，SM-2 智能选卡 |
| 限时挑战 | ⏱️ | 60/90/120秒可选 |
| 生存模式 | ❤️ | 3条命，看能走多远 |
| 闯关模式 | 🏰 | 按年级课文逐关解锁 |
| 连连看 | 🔗 | 字-词配对 |

### 4.1 快速学习（每日任务）

- 设置中配置：「每日练习数」(10/20/30) 或「每日掌握数」(5/10/15)
- SM-2 选卡：优先到期复习卡 → 不足则加入新字
- 流程与现有学习流程相同（听写/拼写）
- 进度条显示 "已完成 X/20"
- 完成后显示今日简报

### 4.2 限时挑战 (Time Attack)

- 选择时长：60 / 90 / 120 秒
- 倒计时内持续出题
- 答对加时 (+3秒) + 加分
- combo 翻倍加分
- 结束后显示：答对数、最高 combo、得分、历史最佳对比

### 4.3 生存模式 (Survival)

- 3 条命（❤️❤️❤️）
- 答错扣 1 命
- 连续答对 5 个回复 1 命（上限 3）
- 难度递增：前 10 个从 1-2 年级，10-20 从 2-3 年级...
- 结束后显示：存活数、最远记录

### 4.4 闯关模式 (Levels)

- 按课本结构：年级 → 学期 → 课文 = 一关
- 每关 5-8 个字
- 星级评价：0错=⭐⭐⭐，1错=⭐⭐，2+错=⭐
- 过关解锁下一关 + 奖励积分

### 4.5 连连看 (Match)

- 4×3 或 4×4 网格
- 一半是字，一半是对应词语
- 点击配对：选字 → 选对应词语，正确消除
- 计时，全部消除完成
- 不涉及书写，训练字-词认知

## 5. 报告系统

增强「统计」tab：

```
统计 tab
├── 今日概览
│   ├── 今日练习数 / 目标
│   ├── 正确率
│   ├── 新掌握字数
│   └── 连续打卡天数 🔥
│
├── 学习趋势（7天/30天切换）
│   ├── 每日练习数 柱状图
│   ├── 正确率 折线图
│   └── 累计掌握字数 折线图
│
├── 掌握进度
│   ├── 圆环图：已掌握/学习中/未学习 比例
│   └── 按年级分布进度条
│
├── 易错字排行（错误率高且练习≥3次）
│   ├── 字 | 练习数 | 错误率 | 最后练习
│   └── 点击可跳转练习
│
├── 等级 & 徽章
└── 打卡日历
```

数据来源：
- 今日/趋势 → DailySession
- 掌握进度 → CharacterStats 聚合
- 易错字 → CharacterStats 按 errorCount/practiceCount 排序

## 6. 技术债务修复

| 问题 | 修复 |
|------|------|
| SM-2 未实际选卡 | loadDueCards 改用 SM2Engine.selectDueCards；submitAnswer 从 CharacterStats 读实际 ease/interval/repetition |
| DailySession 未创建 | session 完成时创建/更新当天记录 |
| BadgeService 未接入 | session 完成后调用 checkNewBadges，解锁弹庆祝动画 |
| UserProfile 未初始化 | App 启动时自动创建 |
| dailyCompletionBonus 未使用 | 快速学习完成后奖励 50 分 |

## 7. Tab 结构调整

| 原有 | 改为 |
|------|------|
| 学习 | 学习（模式选择 → 各游戏模式） |
| 卡片库 | 字库（CharacterStats 浏览器） |
| 添加 | 添加（保留，用于 AI 生成自定义卡） |
| 统计 | 统计（增强报告 + 设置入口） |

## 调研参考

- [Duolingo Adventures](https://blog.duolingo.com/adventures/) — 沉浸式游戏化学习
- [Duolingo 2025 Product Highlights](https://blog.duolingo.com/product-highlights/) — XP 目标、角色互动
- [TypingAttack](https://www.typinggames.zone/typingattack) — 限时打字挑战
- [Spellerz](https://mrnussbaum.com/spellerz-customizable-online-spelling-and-typing-game) — 拼写挑战游戏
- [Anki Gamification Plugins](https://www.polyglossic.com/top-three-gamification-plugins-for-anki/) — Pokemanki 等
- [PlayHanzi](https://playhanzi.com/) — 汉字学习游戏
- [Hacking Chinese: Games for Learning](https://www.hackingchinese.com/10-ways-using-games-learn-teach-chinese/) — 中文学习游戏化
- [Word Games for Kids](https://www.prodigygame.com/main-en/blog/word-games-for-kids/) — 36 种儿童词汇游戏
