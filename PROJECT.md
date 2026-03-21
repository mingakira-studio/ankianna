# Project: ankianna — Anna 记忆卡片

## Meta
- Area: education
- Status: active
- Path: ~/Projects/ankianna
- Created: 2025-05-01
- Last Updated: 2026-03-18

## 目标
为 Anna 打造个性化的记忆卡片应用，基于间隔重复算法帮助高效记忆学习内容。

## 原则
- 间隔重复：科学的记忆曲线算法
- 儿童友好：简洁直观的界面
- 个性化：针对 Anna 的学习内容定制

## 任务大纲
1. [x] 项目初始化 — 创建目录和虚拟环境 (迁移前)
2. [x] 需求分析与设计 — brainstorming + 设计文档
3. [x] 核心功能开发 — SwiftUI iPad App (2026-03-05)
4. [x] 功能迭代 — 英语键盘输入、题库系统、卡片编辑 (2026-03-06)
5. [x] 界面游戏化 — 吉祥物动画、combo 特效、徽章系统、进度可视化 (2026-03-07)
6. [x] V2 设计 — 5 功能模块设计 + 实施计划 (2026-03-09)
7. [x] 基础重构 — CharacterStats 模型、SM-2 修复、技术债清理、课本预装 (Phase 1, Task 1-6) (2026-03-09)
8. [x] 字库浏览器 — 添加tab内嵌课本字库浏览(年级→课文→字)，单字/整课加入卡片库；移除首次启动自动填充；卡片库仅显示用户已选卡片 (Phase 2, Task 7-9) (2026-03-10)
9. [x] 学习流程重设计 — 练习模式、动态队列、三级掌握状态（学习/疑难/熟识） (2026-03-10)
10. [x] 游戏模式 — 快速学习 + 限时挑战 + 生存模式 + 闯关模式 + 连连看 (Phase 3, Task 10-16) (2026-03-11)
11. [x] UI优化 P0: 可访问性与触控安全 — 触控目标≥44pt、accessibilityLabel、reducedMotion、按压反馈、Haptic、exitFeedback可跳过 (SwiftUI Expert) (2026-03-12)
12. [x] UI优化 P1: 设计系统基础 — DesignTokens.swift(颜色/字号/间距/圆角)、SF Rounded字体、emoji吉祥物替换、游戏模式视觉统一 (SwiftUI Expert) (2026-03-12)
13. [x] UI优化 P2: 交互体验 — 游戏结束返回首页、过渡动画、颜色辅助指示、学习tab badge、答对显示对应字 (ui-ux-pro-max + SwiftUI Expert) (2026-03-12)
14. [x] UI优化 P3: 布局与内容 — iPad横屏适配、GameModeCard adaptive布局、Session分享功能、MascotView bug修复 (ui-ux-pro-max + SwiftUI Expert) (2026-03-13)
15. [x] UI优化 P4: 进阶优化 — Claymorphism风格、SpriteKit粒子替换confetti、暗色模式调优、Dynamic Type、onboarding动画 (ui-ux-pro-max + SwiftUI Expert) (2026-03-13)
16. [x] 设置页与橡皮擦 — 设置页(测试开关隐藏DEBUG按钮)、写字界面橡皮擦工具 (2026-03-15)
17. [x] 报告系统 — 今日概览、学习趋势图、掌握进度、易错字排行 (Phase 4, Task 17-20) (2026-03-16)
18. [x] 互动角色设计 — 3D卡通龙角色，指导/评价/鼓励学习过程 (2026-03-16)
19. [x] 闯关模式重设计 — 战斗化闯关体验（具体研究后设计） (2026-03-16)
20. [x] 集成收尾 — 全量测试修复、文档更新 (Phase 5, Task 21-23) (2026-03-18)
21. [>] 用户测试与迭代 — 记录安娜每日学习、检查记录、设计新功能、记录bug
- [ ] [evolve] 优先做 Phase 4 报告系统（或至少做「今日概览」部分），在游戏模式之前。原因：报告让家长/孩子能看到 SRS 是否有效，形成正反馈循环。没有数据可视化，Anna 和家长都看不到进步。
- [ ] [evolve] 修复 DailySession 未创建的问题。当前学习完成后不记录 DailySession，导致打卡日历为空、趋势图无数据。这直接影响用户体验——Anna 看不到连续打卡的记录就没有成就感。

## NEXT: 用户测试与迭代
> 持续性任务：安娜每日使用 App 学习，观察使用情况，收集反馈

### 跟踪清单
- [ ] 每日检查安娜的学习记录（统计 tab 数据）
- [ ] 收集使用中发现的 bug（记录到下方 Bug 列表）
- [ ] 收集新功能需求（记录到下方 Ideas 列表）

### Bug 列表
- [ ] B1: 小游戏（限时挑战/生存/闯关）里写完字没有提交按钮，无法让系统检查是否正确
- [ ] B2: 部分小游戏的汉字输入框不是正方形且不够大，需统一为与练习模式一致的标准大小（正方形、WritingCanvasWithTools）
- [ ] B3: 每日练习写完字后，统计页的练习日志未更新（显示 0/15），DailySession 可能未正确创建/更新
- [ ] B4: 写完字确认后切换tab再切回来，之前的结果画面重新显示但任务已到下一个字（showResult状态未在tab切换时清除）

### Ideas 列表
- [ ] I1: 加入更多恐龙模型供写字和闯关使用（用户已下载新模型到 Downloads）
- [ ] I2: 恐龙动画优化 — 写字时显示 idle，检查正确时显示吼叫动作（需要模型有对应动画或程序化模拟）
- [ ] I3: 恐龙解锁系统 — 升级后解锁新的恐龙模型（与现有等级制度联动）
- [ ] I4: 完成一次每日练习后解锁当日的 iPad 游戏时间（家长控制联动，练习=解锁奖励）


## Log
- 21:37 [project-quick] 完成「设置页与橡皮擦」— SettingsView新tab(测试模式开关+重播引导), WritingCanvasWithTools(画笔/橡皮擦/清除工具栏), 4个视图模拟按钮从#if DEBUG改为@AppStorage控制, UITest自动启用testMode; 161 unit + 56 UI tests 回归通过; NEXT=互动角色设计
- 10:49 [project-next] 完成「UI优化 P3: 布局与内容」— 4游戏模式横屏适配(GeometryReader+HStack分栏), GameModeCard去硬编码高度改minHeight+flexible, MascotView bounce双重赋值bug修复, sessionCompleteView添加ShareLink文本分享按钮; 161 unit tests 回归通过; NEXT=UI优化 P4: 进阶优化
- 08:13 [adhoc] UIScreenshotTests截图测试工具: 6个XCUITest覆盖关键页面+设计要求, ios-ui-screenshot-test.sh通用脚本, triggerWrongAnswer()支持中英文; 161 unit tests + 6 screenshot tests 通过
- 23:25 [project-next] 完成「UI优化 P2: 交互体验」— 4游戏模式结束画面+返回首页按钮(dismiss), ResultFeedbackView答对显示「X」写对了, 学习tab待复习badge(.badge(dueCount)), CardLibraryView正确率旁趋势图标+StreakCalendar打卡checkmark, 4游戏模式过渡动画(.transition+withAnimation); 161 unit tests 回归通过; NEXT=UI优化 P3: 布局与内容
- 20:28 [project-next] 完成「UI优化 P1: 设计系统基础」— DesignTokens.swift(语义颜色/SF Rounded字体/4pt间距/圆角/阴影/动画), MascotView emoji→SwiftUI绘制恐龙(5表情+弹跳), CelebrationEffects emoji→SF Symbols, 16个视图迁移到DesignTokens; 161 unit tests 回归通过; NEXT=UI优化 P2: 交互体验
- 20:01 [project-next] 完成「UI优化 P0: 可访问性与触控安全」— trash按钮/日历圆点触控≥44pt, speaker/trash accessibilityLabel, 4文件reducedMotion支持, PressableCardStyle按压反馈, HapticService(success/error/selection/impact)+5个ViewModel接入, exitFeedback点击可跳过; 156 unit tests 回归通过; NEXT=UI优化 P1: 设计系统基础
- 19:20 [adhoc] UI/UX Pro Max 全局审查: 28个视图文件审查，评分C+，产出24项优化清单(P0-P4)，保存到 docs/plans/2026-03-12-ui-ux-review.md
- 21:59 [adhoc] 疑难字 bug 修复(累计错3次标疑难+删除跳过功能) + 卡片库 UI 重设计(大字+正确率/练习次数/上次学习时间); 156 unit tests 回归通过
- 14:58 [adhoc] 卡片库列表增强: 显示掌握状态/正确率/正确错误数 + 删除按钮; CardLibraryView.swift 单文件修改, 155 unit + 3 UI tests 回归通过
- 14:06 [project-next] 完成「游戏模式」— GameModeSelectionView(5模式入口)、TimeAttack(限时挑战+加时+combo)、Survival(3命生存+难度递增)、Levels(课文闯关+星级+解锁)、Match(字词连连看); LevelProgress SwiftData模型; 25 unit tests + 7 GameModeTests passed, 全量155单元+UITests回归通过; NEXT=报告系统
- 12:09 [adhoc] 学习界面: 添加 DEBUG 模拟写对/写错按钮 + 自动朗读（进入+切题）; 学习流程重设计方案 docs/plans/2026-03-10-learning-flow-redesign.md, 插入任务大纲 NEXT=学习流程重设计
- 10:43 [project-next] 完成「字库浏览器」— TextbookSeeder.seedDefaultLesson(仅预装二年级上册第一课)、TextbookBrowserView(三级导航:年级→课文→字符+单字/整课加入卡片库)、AddCardView新增课本字库入口; 5 UI tests + 9 unit tests passed, 全量回归通过; NEXT=游戏模式
- 2026-03-09: [project-next] 完成 V2 设计，设置 NEXT=基础重构；设计文档 docs/plans/2026-03-09-v2-features-design.md，实施计划 docs/plans/2026-03-09-v2-implementation.md（23 tasks / 5 phases）
- 2026-03-07: [project-next] 完成「界面游戏化」— BadgeService(5徽章+解锁逻辑), LevelService(等级/XP进度条), combo计数器+积分弹出动画, confetti/火焰庆祝特效, 恐龙吉祥物表情状态; 68 unit tests + 23 UI tests passed
- 2026-03-06: 课本选课功能（TextbookDataProvider + 并发AI生成）、模型换 qwen-plus、Canvas 改 anyInput、手写识别优化
- 2026-03-05: [auto-dev] 完成全部 10 个子任务, 27 tests passed, BUILD SUCCEEDED
- 2026-03-05: 完成需求分析与设计，确定 SwiftUI iPad 原生方案，输出设计文档
- 2026-02-25: 从 /Volumes/nvme1/code/ankianna/ 迁移到 GTD 系统（源目录仅有 venv）

## 操作指南

### 工作流提醒
- 完成子任务的实际工作后 → 主动提醒用户: "子任务「xxx」已完成，要标记吗？(/project-done)"
- 所有子任务完成后 → 自动触发 /project-next
- 完成的工作不在任务大纲中 → 提醒用户: "这是计划外工作，要记录吗？(/project-adhoc)"
- 遇到阻塞/方案变更 → 记录到「项目备忘」并告知用户

### 项目备忘
- 源目录 /Volumes/nvme1/code/ankianna/ 仅含 venv，无实际代码
- 技术栈确定: SwiftUI 原生 iPad App (iOS 17+)
- 核心场景: 中文听写 + 英文拼写（听/看语境 → 手写 → 判定）
- 设计文档: docs/plans/2026-03-05-ankianna-design.md
- 实施计划: docs/plans/2026-03-05-ankianna-implementation.md
- Apple Pencil 手写识别需真机测试，无法完全自动化
- [决策] 2026-03-06: 手写识别引擎替换 — 原方案: Vision VNRecognizeTextRequest → 新方案: Google ML Kit Digital Ink Recognition（原因: Vision 对单个手写汉字返回 0 observations，穷尽调参无效）
- [决策] 2026-03-06: AI 模型切换 — 原方案: Anthropic Claude API → 新方案: 阿里 qwen-plus OpenAI 兼容格式（原因: 成本和可用性）
- [决策] 2026-03-06: Canvas 输入方式 — 原方案: pencilOnly → 新方案: anyInput（原因: 支持手指输入便于调试和非 Pencil 场景）
- 已补齐 AIGenerator、LearningViewModel、TextbookDataProvider 测试，并修正 LearningFlow/SessionComplete UI 测试假通过；新增英文-only UITest seed，当前全量 105 个测试通过
- V2 设计文档: docs/plans/2026-03-09-v2-features-design.md
- V2 实施计划: docs/plans/2026-03-09-v2-implementation.md（23 tasks / 5 phases）
- V2 技术债: SM-2 未实际选卡、DailySession 未创建、BadgeService 未接入、UserProfile 未初始化
- LearningView DEBUG 模式新增「模拟写对/写错」按钮（#if DEBUG），绕过手写识别直接调用 submitAnswer，方便模拟器测试正确率和学习曲线
- LearningView 进入学习界面自动朗读当前语境，切题时也自动朗读（onChange of showResult），喇叭按钮保留手动重听
- 学习流程重设计方案: docs/plans/2026-03-10-learning-flow-redesign.md — 练习模式(看字写2次+盲写1次)、动态队列(错字随机插回)、三级状态(学习/疑难/熟识)、退出判定(连续对3次/有错对2次/连续错3次)
- 更新 sp-bridge skill（~/.claude/skills/sp-bridge/SKILL.md）：新增文档引用规则，要求任务大纲带 Phase/Task 映射、NEXT 带设计/实施文档引用、子任务带计划 Task 引用
- [决策] 2026-03-10: 字库与卡片库分离 — 原方案: TextbookSeeder 首次启动自动填充 1000+ 字到卡片库 → 新方案: 字库作为「添加」tab 的课本浏览器，用户按年级/课文浏览后手动选择加入卡片库（原因: 卡片库是用户学习清单，不应被预制数据填满）
- CardLibraryView 列表行增强：大字+badge左侧，正确率/练习次数/上次学习时间居中，删除按钮右侧；去掉类型和语境数；正确率按高中低变色
- [bug修复] 疑难字判定：改为累计错3次即标疑难（非连续错），新增 totalWrong 字段；删除"跳过"功能，答错后只能"再试一次"进入练习模式
- UI/UX Pro Max 全局审查报告: docs/plans/2026-03-12-ui-ux-review.md — 审查全部 28 个视图文件，评分 C+，产出 24 项优化清单(P0-P4)，推荐 Claymorphism 风格 + SF Rounded 字体
- UIScreenshotTests.swift: XCUITest 截图测试工具，6个测试覆盖关键页面(首页/卡片库/统计/生存模式结束/限时挑战/答对反馈)，每个截图附带设计要求清单；triggerWrongAnswer() 同时支持中文手写和英文输入卡片；配套脚本 ios-ui-screenshot-test.sh (~/workspace/scripts/) 运行测试+提取截图到 /tmp/ui-screenshots/
- [流程修复] 纯 UI 变更时 /project-next 跳过 test-guard 后连带跳过 e2e-guard，导致 UI 修改无截图验收。已修复：project-next Step 5/10 明确 e2e-guard 独立于 test-guard，纯 UI 仍必须走 e2e-guard Step 6.5 截图验收；e2e-guard 新增「UI 变更强制验收规则」

## Ideas
- [2026-03-18] [evolve] 在开发 Phase 3 游戏模式之前，让 Anna 实际使用当前版本至少 1 周。记录她的使用频率、遇到的问题、喜欢/不喜欢什么。用真实反馈而非设计文档来决定做哪个游戏模式。
- [2026-03-18] [evolve] 立即移除 AIGenerator.swift 中硬编码的阿里云 API Key (***REMOVED***...)。从 git 历史中清除（git filter-branch 或 BFG），然后在阿里云控制台 rotate 这个 Key。改为首次使用时强制 Keychain 输入，不保留 defaultAPIKey。
