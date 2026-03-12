# AnkiAnna UI/UX 审查报告

> 审查日期: 2026-03-12
> 工具: UI/UX Pro Max (design intelligence skill)
> 审查范围: 全部 28 个 SwiftUI 视图文件

## 总体评分: C+ (功能完整，设计粗糙)

### 优点
- 导航结构清晰（TabView 4 项 + NavigationStack）
- 学习流程完整（练习→反馈→练习模式→总结）
- 空状态处理到位
- 删除操作有确认弹窗
- 答错有重试+练习流程，UX 闭环好

### 核心问题
整体停留在「工程原型」阶段，缺少设计系统、无品牌感、可访问性缺失严重。

### 推荐设计风格
- **Style**: Claymorphism — 圆润、柔软、有触感，适合儿童教育 app
- **Typography**: SF Rounded（系统内置）或 Baloo 2 / Comic Neue（Google Fonts）
- **Colors**: Primary #2563EB, Secondary #3B82F6, CTA #F97316, Background #F8FAFC, Text #1E293B
- **Effects**: 多层阴影、borderRadius 40+、弹簧动画、Haptic Light on press

---

## CRITICAL 问题 (必须修)

### 1. 可访问性 (Accessibility)

| # | 问题 | 位置 | 规则 |
|---|------|------|------|
| A1 | **无 Dynamic Type 支持** — 所有字号硬编码 `.system(size: N)`，不跟随系统字号设置 | 全部视图 | `dynamic-type` |
| A2 | **未检查 Reduced Motion** — 无 `@Environment(\.accessibilityReduceMotion)` 检查 | CelebrationEffects, MascotView, ResultFeedbackView | `reduced-motion` |
| A3 | **Icon-only 按钮无 accessibilityLabel** | CardPromptView:20 speaker, CardLibraryView:92 trash | `aria-labels` |
| A4 | **颜色是唯一信息载体** — 正确率绿/橙/红，打卡圆点绿/灰 | CardLibraryView, StreakCalendarView | `color-not-only` |
| A5 | **`.quaternary` 对比度不足** — "未学习"文字可能低于 4.5:1 | CardLibraryView:87 | `color-contrast` |

### 2. 触控交互 (Touch & Interaction)

| # | 问题 | 位置 | 规则 |
|---|------|------|------|
| T1 | **trash 按钮触控目标太小** — 15pt icon，无 hitSlop，远低于 44×44pt | CardLibraryView:92-99 | `touch-target-size` |
| T2 | **日历圆点仅 24pt** | StreakCalendarView:31-33 | `touch-target-size` |
| T3 | **GameModeCard 无按压反馈** — `.buttonStyle(.plain)` 点击无视觉变化 | GameModeSelectionView:49 | `press-feedback` |
| T4 | **全局缺少 Haptic 反馈** — 答对/答错/combo 等关键时刻 | 全局 | `haptic-feedback` |
| T5 | **cardExitFeedback 阻塞 1.5s** — 无法跳过 | LearningView:417 | `no-blocking-animation` |

---

## HIGH 问题 (强烈建议修)

### 3. 设计风格 (Style Selection)

| # | 问题 | 位置 | 规则 |
|---|------|------|------|
| S1 | **Emoji 用作结构性图标** — MascotView 🦕🤔🥳💪🎉, ConfettiView ⭐🌟✨, ComboFireView 🔥 | MascotView, CelebrationEffects | `no-emoji-icons` |
| S2 | **无统一设计语言** — List 原生 vs GameModeCard 渐变 vs 练习界面纯白 | 全局 | `consistency` |
| S3 | **无设计 token 系统** — 颜色/字号/间距全部硬编码内联 | 全局 | `color-semantic` |

### 4. 布局 (Layout & Responsive)

| # | 问题 | 位置 | 规则 |
|---|------|------|------|
| L1 | **游戏模式未适配 iPad 横屏** — 全用 VStack，横屏留白巨大 | TimeAttack, Survival, Match, Levels | `orientation-support` |
| L2 | **GameModeCard 固定高度** — iPad 大屏上偏小 | GameModeSelectionView:91 `frame(height: 160)` | `content-priority` |
| L3 | **间距不统一** — 值: 0,2,4,6,8,12,16,20,24 无规律 | 全局 | `spacing-scale` |

### 5. 导航 (Navigation)

| # | 问题 | 位置 | 规则 |
|---|------|------|------|
| N1 | **Tab 无 badge 提示** — 有待复习卡片时「学习」tab 应显示 badge | ContentView TabView | `tab-badge` |
| N2 | **游戏结束无返回导航** — 只有"再来一次"，无"返回首页" | TimeAttack/Survival/Levels/Match gameOverView | `escape-routes` |

---

## MEDIUM 问题 (推荐修)

### 6. 字体排版 (Typography)

| # | 问题 | 位置 |
|---|------|------|
| F1 | **无语义文字层级** — 全用 `.system(size: N)` 而非 `.title`/`.headline`/`.body` | 全局 |
| F2 | **儿童 app 应用更友好的字体** — 推荐 SF Rounded `.design(.rounded)` | 全局 |
| F3 | **练习模式汉字 72pt 过大** — iPad 上占据过多空间 | LearningView:236 |

### 7. 动画 (Animation)

| # | 问题 | 位置 |
|---|------|------|
| M1 | **Confetti 用 emoji 而非粒子系统** — 12 个 emoji 随机散落，效果粗糙 | CelebrationEffects |
| M2 | **缺少 page transition** — start→gameplay→gameOver 切换无过渡 | 各 GameMode |
| M3 | **MascotView bounce 写法有误** — `bouncing = true` 重复赋值两次 | MascotView:56 |

### 8. 表单与反馈 (Forms & Feedback)

| # | 问题 | 位置 |
|---|------|------|
| I1 | **TextField 仅用 placeholder 做标签** — 无 visible label | TimeAttack/Survival/Levels "输入答案" |
| I2 | **答对反馈缺少对应字提示** — 只显示"太棒了！"不显示答对的字 | ResultFeedbackView |
| I3 | **Session 完成页无分享功能** — 儿童喜欢向家长展示成绩 | sessionCompleteView |

---

## 优化清单 (按优先级排序)

### P0 — 可访问性 & 触控安全 (blocking)
- [ ] (A3/T1) 所有触控目标确保 ≥44×44pt（trash 按钮加 `.frame(minWidth:44, minHeight:44)`、日历圆点扩大）
- [ ] (A3) Icon-only 按钮添加 `.accessibilityLabel()`（speaker → "朗读", trash → "删除"）
- [ ] (A2) 检查 `@Environment(\.accessibilityReduceMotion)` 并关闭非必要动画
- [ ] (T3) GameModeCard 添加按压反馈（`.scaleEffect` on press）
- [ ] (T4) 关键时刻添加 Haptic（答对 `.success`, 答错 `.error`, combo `.impact`）
- [ ] (T5) cardExitFeedback 改为可点击跳过（不要强制等 1.5s）

### P1 — 设计系统基础 (high impact)
- [ ] (S3) 创建 `DesignTokens.swift` — 统一颜色(语义 token)、字号(type scale)、间距(4/8/12/16/24/32)、圆角
- [ ] (F2) 用 SF Rounded `.font(.system(size:N, weight:.bold, design:.rounded))` 替换默认字体
- [ ] (S1) 用矢量插画/Lottie 替换 emoji 吉祥物（MascotView 最优先）
- [ ] (S2) 统一游戏模式的视觉风格

### P2 — 交互体验 (medium impact)
- [ ] (N2) 游戏结束页添加"返回首页"按钮
- [ ] (M2) 游戏模式启动/结束添加过渡动画
- [ ] (A4) 颜色信息添加辅助指示（正确率旁加 ↑↓ 箭头，打卡日历加 checkmark）
- [ ] (N1) "学习" tab 添加待复习数量 badge
- [ ] (I2) 答对反馈显示对应的字（"太棒了！「跳」写对了"）

### P3 — 布局与内容 (low-medium impact)
- [ ] (L1) 游戏模式适配 iPad 横屏（HStack 左右分栏）
- [ ] (L2) GameModeCard 用 adaptive 布局替换固定高度
- [ ] (I3) Session 完成页添加截图/分享功能
- [ ] (M3) MascotView bounce 修复双重赋值 bug

### P4 — 进阶优化 (nice to have)
- [ ] 引入 Claymorphism 设计风格（多层阴影、圆角 40+、弹簧动画）
- [ ] (M1) Confetti 替换为 SpriteKit 粒子系统
- [ ] 暗色模式专项测试和调优
- [ ] (A1/F1) 字号改用语义样式支持 Dynamic Type
- [ ] 添加 onboarding 引导动画（首次使用）

---

## 执行建议

- **快速见效**: P0 + P1-SF Rounded 字体，投入小、感知变化最大
- **每个 P 级别可作为一个独立 phase 执行**
- **P1 的 DesignTokens.swift 是后续所有优化的基础，应最先完成**
- **Lottie 吉祥物替换需要美术资源，可能需要外部支持**
