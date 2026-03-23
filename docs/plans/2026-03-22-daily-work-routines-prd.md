# PRD: GTD Daily Work — Routines 系统

日期: 2026-03-22
状态: Draft
目标系统: gtd-dashboard-cli (Python curses TUI)

## 背景

GTD 系统目前管理的是**项目任务**（一次性完成），缺少对**周期性交互任务**的支持。用户有多种需要定期执行的工作：
- 每日检查 App 使用数据（如 AnkiAnna 练习记录）
- 每周项目回顾
- evolve 建议的待决策处理
- Area 月度审视

这些任务散落在各项目 PROJECT.md 中，没有统一的提醒、记录和追踪机制。

## 目标

在 gtd-dashboard-cli 中新增 **Daily Work** 页面，聚合所有周期性任务，提供：
1. 统一视图：看到今天需要做什么
2. 结构化记录：按模板填写，自动存档
3. 完成追踪：streak 连续完成天数、本周完成率
4. 灵活调度：支持 daily/weekly/monthly/defer

## 非目标

- 不替代 org-agenda（org-agenda 管通用 TODO，routines 管 GTD 周期任务）
- 不做手机端（当前仅 terminal TUI）
- V1 不做 evolve 决策集成（后续迭代）

---

## 数据模型

### routines.yaml

位置: `~/workspace/gtd/routines.yaml`

```yaml
routines:
  - id: ankianna-daily-check
    name: "检查安娜练习"
    project: ankianna              # 关联项目（可选）
    area: education                # 关联 area（可选）
    frequency: daily               # daily | weekly | monthly
    time: "20:00"                  # 建议执行时间（用于排序和提醒）
    template:                      # 结构化记录模板
      - field: practiced
        label: "今日练习"
        type: boolean              # boolean | text | number | choice
      - field: characters
        label: "完成字数"
        type: number
      - field: accuracy
        label: "正确率%"
        type: number
      - field: mode
        label: "使用模式"
        type: choice
        options: ["快速学习", "限时挑战", "生存模式", "闯关模式", "连连看", "未使用"]
      - field: observation
        label: "观察"
        type: text
      - field: feedback
        label: "Anna反馈"
        type: text
      - field: bugs
        label: "发现Bug"
        type: text
    created: 2026-03-22
    enabled: true

  - id: weekly-project-review
    name: "项目周回顾"
    frequency: weekly
    weekday: sunday                # weekly 时指定星期几
    template:
      - field: projects_reviewed
        label: "回顾了哪些项目"
        type: text
      - field: blockers
        label: "阻塞项"
        type: text
      - field: next_week_focus
        label: "下周重点"
        type: text
    created: 2026-03-22
    enabled: true
```

### 记录文件

位置: `~/workspace/gtd/routines/{routine_id}/{YYYY-MM-DD}.yaml`

```yaml
# ~/workspace/gtd/routines/ankianna-daily-check/2026-03-22.yaml
routine_id: ankianna-daily-check
date: 2026-03-22
completed_at: "20:15"
fields:
  practiced: true
  characters: 12
  accuracy: 80
  mode: "快速学习"
  observation: "对'芬'字反复写错，需要加强"
  feedback: "恐龙很好玩"
  bugs: ""
```

### 状态索引

位置: `~/workspace/gtd/routines/_status.yaml`（自动生成，加速查询）

```yaml
ankianna-daily-check:
  last_completed: 2026-03-22
  streak: 5
  total_completed: 15
  completion_rate_7d: 0.86    # 最近7天完成率
weekly-project-review:
  last_completed: 2026-03-16
  streak: 2
  total_completed: 4
  completion_rate_30d: 1.0
```

---

## 功能需求

### FR-1: Routines 页面（新 TUI 页面）

在 gtd-dashboard-cli 新增页面，快捷键 `R` 从首页进入。

**页面布局**:

```
┌─ Daily Work ─────────────────────────────────────────────┐
│                                                          │
│  今日 Routines (2/3 完成)                   2026-03-22   │
│  ─────────────────────────────────────────────────────── │
│  ✅ 检查安娜练习          streak: 5🔥  20:15 完成        │
│  ⬜ 项目周回顾            streak: 2    (周日)            │
│  ⏸  投资持仓检查          defer → 03-25                  │
│                                                          │
│  本周完成率: ████████░░ 80%                              │
│                                                          │
│  ─────────────────────────────────────────────────────── │
│  最近记录                                                │
│  03-22 ankianna: 12字, 正确率80%, "恐龙很好玩"          │
│  03-21 ankianna: 未练习                                  │
│  03-20 ankianna: 15字, 正确率92%                        │
│                                                          │
│  [Enter] 记录  [d] defer  [n] 新建  [e] 编辑  [q] 返回  │
└──────────────────────────────────────────────────────────┘
```

**状态显示规则**:
- `✅` 今天已完成
- `⬜` 今天待完成（到期）
- `⏸` 已 defer（显示到期日）
- `⏭` 未到期（weekly 不在今天、monthly 不在本周）
- 灰色显示未到期的 routine，不计入"今日"计数

### FR-2: 记录交互（Enter 键）

选中一个未完成的 routine 按 Enter，进入**结构化表单**：

```
┌─ 记录: 检查安娜练习 ─────────────────────────────────────┐
│                                                          │
│  今日练习:    [✓] 是  [ ] 否                             │
│  完成字数:    [12        ]                               │
│  正确率%:     [80        ]                               │
│  使用模式:    [快速学习 ▼]                               │
│  观察:        [对'芬'字反复写错____________________]     │
│  Anna反馈:    [恐龙很好玩________________________]       │
│  发现Bug:     [__________________________________]       │
│                                                          │
│  [Tab] 下一字段  [Enter] 提交  [Esc] 取消                │
└──────────────────────────────────────────────────────────┘
```

提交后：
1. 写入 `~/workspace/gtd/routines/{id}/{date}.yaml`
2. 更新 `_status.yaml`（streak、completion_rate）
3. 页面刷新显示 ✅

### FR-3: Defer 机制（d 键）

选中 routine 按 `d`，弹出 defer 选项：

```
Defer 到什么时候？
[1] 明天
[2] 后天
[3] +3天
[4] +7天
[5] 自定义日期
```

Defer 后该 routine 在指定日期前不再显示为"待完成"。

存储: 在 `_status.yaml` 中记录 `deferred_until: 2026-03-25`

### FR-4: 新建 Routine（n 键）

交互式创建新 routine：

```
新建 Routine
────────────
名称: [________________________]
关联项目: [ankianna ▼]  (可选, 从活跃项目列表选)
频率: [daily ▼]  daily / weekly / monthly
时间: [20:00]  (建议执行时间)

模板字段 (至少1个):
  1. [practiced ] 类型: [boolean ▼]
  2. [characters] 类型: [number  ▼]
  3. [+] 添加字段

[Enter] 创建  [Esc] 取消
```

创建后追加到 `routines.yaml`。

### FR-5: 最近记录查看

页面下半部分显示最近 7 天的记录摘要。选中某条按 Enter 可查看完整记录。

摘要格式: `{date} {routine_name}: {field1_value}, {field2_value}, "{text_field_excerpt}"`

### FR-6: macOS 通知提醒

对每个 `daily` routine，在其 `time` 字段指定的时间发送 macOS 通知：

```
标题: GTD Routine
内容: 检查安娜练习 (streak: 5🔥)
```

实现方式: 注册一个 launchd plist，调用 `osascript` 发通知。或者在 gtd-dashboard-server 中实现定时触发。

---

## 技术实现建议

### 文件结构

```
~/workspace/gtd/routines/
├── routines.yaml                    # routine 定义（手动或 n 键创建）
├── _status.yaml                     # 状态索引（自动维护）
├── ankianna-daily-check/
│   ├── 2026-03-20.yaml
│   ├── 2026-03-21.yaml
│   └── 2026-03-22.yaml
└── weekly-project-review/
    ├── 2026-03-16.yaml
    └── 2026-03-22.yaml
```

### gtd-dashboard-cli 改动

```
gtd_dashboard_cli/
├── readers/
│   └── routines.py          # 新增: 读取 routines.yaml + _status.yaml + 记录文件
├── viewmodels/
│   └── routines.py          # 新增: RoutinesViewModel (今日待办、最近记录、streak)
├── renderers/
│   └── routines.py          # 新增: 页面渲染 + 表单渲染
├── services/
│   └── routines.py          # 新增: 创建/完成/defer 逻辑，写文件
├── keymap.py                # 修改: 首页添加 R 键绑定
└── app.py                   # 修改: 注册 routines 页面
```

### 到期判断逻辑

```python
def is_due_today(routine, status, today):
    if status.get("deferred_until") and today < status["deferred_until"]:
        return False
    freq = routine["frequency"]
    last = status.get("last_completed")
    if freq == "daily":
        return last != today
    elif freq == "weekly":
        target_weekday = routine.get("weekday", "monday")
        return today.weekday_name == target_weekday and (not last or last < today - 6days)
    elif freq == "monthly":
        target_day = routine.get("monthday", 1)
        return today.day == target_day and (not last or last.month != today.month)
```

### Streak 计算

```python
def calculate_streak(record_dir, frequency):
    """从记录文件反向计算连续完成天数"""
    dates = sorted([f.stem for f in record_dir.glob("*.yaml")], reverse=True)
    streak = 0
    expected = today
    for date in dates:
        if date == expected.isoformat():
            streak += 1
            expected = previous_due_date(expected, frequency)
        else:
            break
    return streak
```

---

## 预置 Routines

首次使用时自动创建以下 routine（用户可删除/修改）：

```yaml
- id: ankianna-daily-check
  name: "检查安娜练习"
  project: ankianna
  frequency: daily
  time: "20:00"
  template:
    - { field: practiced, label: "今日练习", type: boolean }
    - { field: characters, label: "完成字数", type: number }
    - { field: accuracy, label: "正确率%", type: number }
    - { field: mode, label: "使用模式", type: choice, options: ["快速学习", "限时挑战", "生存模式", "闯关模式", "连连看", "未使用"] }
    - { field: observation, label: "观察", type: text }
    - { field: feedback, label: "Anna反馈", type: text }
    - { field: bugs, label: "发现Bug", type: text }
```

---

## 验收标准

1. 打开 gtd-dashboard-cli 按 `R` 进入 Daily Work 页面
2. 看到今日到期的 routines 列表，显示 ✅/⬜ 状态和 streak
3. 选中 routine 按 Enter 打开结构化表单，填写后自动保存为 YAML 文件
4. 按 `d` 可以 defer routine 到指定日期
5. 按 `n` 可以创建新 routine
6. 页面下方显示最近 7 天记录摘要
7. 本周完成率进度条正确计算

## 后续迭代

- V2: evolve 决策集成（扫描 `[evolve]` 标签，在 Daily Work 页面展示待决策项）
- V3: 记录数据与项目联动（如 AnkiAnna 练习数据自动从 iPad 读取）
- V4: 手机端支持（gtdremote-dashboard 扩展）
