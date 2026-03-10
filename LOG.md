# Anna 记忆卡片 App - 操作日志

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
