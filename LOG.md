# Anna 记忆卡片 App - 操作日志

## 2026-03-16
- 09:32 [project-next] 完成「报告系统」, 设置 NEXT=互动角色设计
  - TodayOverviewView: 今日练习/正确率/新掌握/连续打卡 四格卡片 + 快速练习完成状态(✅/未完成) + goalStreak(连续达成dailyGoal天数)
  - MasteryProgressView: 自定义Canvas donut圆环图(掌握/学习中/疑难/未学) + 1-5年级ProgressView进度条
  - DifficultCharactersView: 错误率>30%且练习≥3次的Top 10排行
  - TrendChartView: SwiftUI Charts 7天/30天切换, 练习数BarMark + 正确率LineMark+AreaMark
  - StatsView重构: 6个section(今日概览→掌握进度→易错字→趋势→等级徽章→打卡日历)
  - 161 unit tests + 6 screenshot tests 回归通过

## 2026-03-15
- 21:37 [project-quick] 完成「设置页与橡皮擦」
  - SettingsView: 新tab页，测试模式开关(@AppStorage) + 重播引导按钮
  - WritingCanvasWithTools: 画笔/橡皮擦(PKEraserTool.vector)/清除 三按钮工具栏
  - LearningView/SurvivalView/TimeAttackView/LevelsView: 模拟按钮从#if DEBUG改为testModeEnabled控制
  - LaunchHelper: UITest自动设置testModeEnabled=1
  - 161 unit + 56 UI tests 回归通过; NEXT=互动角色设计

## 2026-03-13
- 22:37 [project-next] 完成「UI优化 P4: 进阶优化」, 设置 NEXT=报告系统
  - SpriteKit粒子替换confetti: SKEmitterNode多色粒子系统替代SF Symbols, 保留reducedMotion
  - Dynamic Type支持: DesignTokens.Font改用.system(.textStyle)自动缩放, CharSize固定不变
  - Claymorphism设计风格: 多层阴影ViewModifier(light/dark自适应), GameModeCard+WritingCanvas应用
  - 暗色模式调优: canvas改systemBackground, Claymorphism阴影随colorScheme适配
  - Onboarding引导: 3页引导动画+AppStorage首次检测, UITest模式自动跳过
  - 161 unit tests + 6 screenshot tests 回归通过
- 19:46 [adhoc] 修复 /project-next + e2e-guard 流程缺陷: 纯UI变更跳过test-guard后连带跳过e2e-guard导致无截图验收; project-next Step 5/10新增纯UI独立调用e2e-guard规则, e2e-guard新增UI变更强制验收规则; 更新两个skill的CHANGELOG.md
- 10:49 [project-next] 完成「UI优化 P3: 布局与内容」, 设置 NEXT=UI优化 P4: 进阶优化
  - 4游戏模式横屏适配: GeometryReader检测横屏, questionView改HStack左右分栏(限时/生存/闯关), MatchView横屏6列
  - GameModeCard: 去掉frame(height:160)硬编码, 改minHeight(140)+flexible padding
  - MascotView: 修复bounce双重赋值bug(删除withAnimation外冗余bouncing=true)
  - sessionCompleteView: 添加ShareLink文本分享按钮(学习成绩+字符+正确率+时长+积分)
  - 161 unit tests 回归通过
- 08:13 [adhoc] UIScreenshotTests 截图测试工具: UIScreenshotTests.swift(6个XCUITest截图+设计要求) + ios-ui-screenshot-test.sh(运行+提取脚本) + triggerWrongAnswer()支持中英文卡片; 161 unit tests + 6 screenshot tests 回归通过

## 2026-03-12
- 19:20 [adhoc] UI/UX Pro Max 全局审查: 审查全部 28 个 SwiftUI 视图文件，基于 10 大 UX 规则类别(Accessibility/Touch/Style/Layout/Typography/Animation/Forms/Navigation/Charts/Performance)逐项评估，总评 C+（功能完整、设计粗糙），产出 24 项分级优化清单(P0可访问性+触控6项/P1设计系统4项/P2交互5项/P3布局4项/P4进阶5项)，推荐 Claymorphism 风格 + SF Rounded 字体。报告保存到 docs/plans/2026-03-12-ui-ux-review.md

## 2026-03-11
- 21:59 [adhoc] 疑难字 bug 修复 + 跳过功能删除 + 卡片库 UI 重设计
  - 疑难字判定从连续错3次改为累计错3次（新增 totalWrong 字段），修复跳过路径不触发疑难标记的 bug
  - 删除"跳过"按钮，答错后只能"再试一次"进入练习模式（ResultFeedbackView + LearningViewModel.next()）
  - 卡片库 UI 重设计：大字(36pt)+badge 左侧，正确率/练习次数/上次学习时间居中，去掉类型和语境数；正确率按高中低变色(绿/橙/红)，相对时间(今天/昨天/N天前)
  - 更新 LearningFlowTests(合并重复+去 skipButton)、FullJourneyTests(去 skipButton fallback)
  - 156 unit tests 回归通过
- 14:58 [adhoc] 卡片库列表增强: CardLibraryView 每行显示掌握状态 badge + 正确率 + 正确✓/错误✗ 计数 + 红色删除按钮（带确认 alert）; @Query CharacterStats 获取学习数据; 保留原有 swipe-to-delete; 155 unit + 3 CardLibrary UI tests 回归通过

## 2026-03-10
- 15:13 [project-next] 完成「学习流程重设计」, 设置 NEXT=游戏模式
  - CharacterStats: MasteryLevel 新增 .difficult, 移除 isDifficult/isManuallyReset, 新增显式 markMastered/markDifficult/markLearning, recordReview 不再自动变更 masteryLevel
  - LearningViewModel 重写: 队列消费模式(removeFirst+reinsert), CharacterSessionState 追踪连续对/错, 练习模式状态机(看字写2次+盲写1次), 主流程/练习分离(仅主流程计 SM-2)
  - 退出判定: 连续对3次→询问熟识确认, 有错连续对2次→退出, 连续错3次→标疑难
  - LearningView: 练习模式 UI(对着写/盲写), 熟识确认 Alert, DEBUG 练习模拟按钮
  - 120 unit tests + 37 UI tests, 全量通过

## 2026-03-09
- 23:43 [project-next] 完成「基础重构」(Phase 1, Task 1-6), 设置 NEXT=字库浏览器
  - CharacterStats 模型（mastery tracking + SM-2 state）+ 14 tests
  - ReviewRecord +repetition, DailySession +newMastered/gameMode
  - TextbookSeeder 首次启动预装课本字符数据 + 4 tests
  - LearningViewModel SM-2 集成修复（从 CharacterStats 读真实 ease/interval/repetition）+ 4 tests
  - UserProfile 首次启动自动初始化
  - TextbookSeeder 字符去重（同字多课文场景）
  - 104 unit tests 全绿
- 23:26 [adhoc] 更新 sp-bridge skill：新增文档引用规则（任务→Phase/Task映射、NEXT→设计/实施文档引用、子任务→计划Task引用）；修复技能自动发现问题
- 23:26 [adhoc] V2 brainstorming + writing-plans 完成，产出设计文档和 23-task 实施计划，转换为 GTD 任务大纲（task 7-11）
- 11:52 [adhoc] 补齐 AIGenerator、LearningViewModel、TextbookDataProvider 测试，修正 LearningFlow/SessionComplete UI 测试假通过，新增英文-only UITest seed；全量 105 个测试通过

## 2026-03-06
- 17:20 [project-next] 完成「功能迭代」, 设置 NEXT=界面游戏化
  - 英语拼写改键盘输入 + 逐字对比反馈（SpellingChecker）
  - 1-5 年级语文题库（8 个 JSON + 年级选择器）
  - 卡片及语境可编辑（CardDetailView 编辑模式）
  - 编译通过，iPad 锁屏未能运行测试
- 15:32 [project-next] 完成「核心功能开发」, 设置 NEXT=功能迭代, 生成 4 个子任务
  - [决策] 手写识别 Vision → ML Kit Digital Ink（Vision 对单字返回 0 obs）
  - [决策] AI 模型 Anthropic → qwen-plus（成本/可用性）
  - [决策] Canvas pencilOnly → anyInput（支持手指）
- [adhoc] 课本选课功能 + AI 生成优化 + Canvas 输入方式调整
  - 新增 TextbookDataProvider：课本课文数据加载（二年级上/下册 JSON）
  - ManualAddCardView 重构：新增"课本选课"模式，选课后批量 AI 生成卡片
  - AIGenerator 切换 Anthropic API → 阿里 qwen-plus（OpenAI 兼容格式）
  - AIGenerateView 新增 API 设置面板（endpoint/key/model 可配置）
  - Card 模型新增 .textbook source 类型
  - WritingCanvasView 改 drawingPolicy 为 .anyInput（支持手指输入）
  - 新增课本资源文件：Resources/textbook_grade2_{upper,lower}.json
  - 新增课本原文参考：docs/textbooks/语文二年级{上,下}册.{md,pdf}
- [adhoc] 手写识别引擎替换 Vision → Google ML Kit Digital Ink Recognition
  - 详见 commit fa2516a

## 2026-03-05
- 14:25 [auto-dev] completed 10/10 subtasks:
  - Task 1 "Create Xcode Project Skeleton": project.yml + XcodeGen, Worker-1 (Sonnet)
  - Task 2 "SwiftData Models": 5 models + 6 tests, Worker-2 (Sonnet)
  - Task 3 "SM-2 Engine": SM2Engine + 7 tests, Worker-3 (Sonnet)
  - Task 4 "TTS Service": TTSService + 3 tests, Worker-4 (Sonnet)
  - Task 5 "Handwriting Recognition": HandwritingRecognizer + 6 tests, Worker-5 (Sonnet)
  - Task 6 "Learning View": 5 View/ViewModel files, Worker-6 (Opus)
  - Task 7 "Card Management": 4 View files, Worker-7 (Opus)
  - Task 8 "AI Card Generation": AIGenerator + AIGenerateView, Worker-8 (Sonnet)
  - Task 9 "Stats View": PointsService + StatsView + StreakCalendarView + 4 tests, Worker-9 (Opus)
  - Task 10 "Integration & Polish": IntegrationTests + LearningViewModel integration, Worker-10 (Opus)
  - Total: 27 tests, 0 failures
- 14:00 [sp-plan] synced 10 tasks from Superpowers plan to NEXT subtasks

## 2026-02-25
- 21:20 [migration] 从 /Volumes/nvme1/code/ankianna/ 迁移到 GTD 系统（源目录仅有 venv）
