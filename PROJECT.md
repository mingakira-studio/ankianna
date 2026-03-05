# Project: ankianna — Anna 记忆卡片

## Meta
- Area: education
- Status: active
- Path: ~/Projects/ankianna
- Created: 2025-05-01
- Last Updated: 2026-03-05

## 目标
为 Anna 打造个性化的记忆卡片应用，基于间隔重复算法帮助高效记忆学习内容。

## 原则
- 间隔重复：科学的记忆曲线算法
- 儿童友好：简洁直观的界面
- 个性化：针对 Anna 的学习内容定制

## 任务大纲
1. [x] 项目初始化 — 创建目录和虚拟环境 (迁移前)
2. [x] 需求分析与设计 — brainstorming + 设计文档
3. [>] 核心功能开发 — SwiftUI iPad App

## NEXT: 核心功能开发

### 子任务
- [ ] **Create Xcode Project Skeleton** | 预估: 10min | 类型: code
  - 所需: 设计文档
  - 产出: AnkiAnnaApp.swift + ContentView.swift + AnkiAnna.xcodeproj
  - 参考: docs/plans/2026-03-05-ankianna-implementation.md#task-1
- [ ] **SwiftData Models** | 预估: 30min | 类型: code
  - 所需: 项目骨架 (Task 1)
  - 产出: Card/CardContext/ReviewRecord/DailySession/UserProfile + ModelTests
  - 验证: `xcodebuild test -scheme AnkiAnna`
  - 参考: docs/plans/2026-03-05-ankianna-implementation.md#task-2
  - blockedBy: Create Xcode Project Skeleton
- [ ] **SM-2 Spaced Repetition Engine** | 预估: 30min | 类型: code
  - 所需: data models (Card.swift)
  - 产出: SM2Engine.swift + SM2EngineTests.swift
  - 验证: `xcodebuild test -scheme AnkiAnna`
  - 参考: docs/plans/2026-03-05-ankianna-implementation.md#task-3
  - blockedBy: SwiftData Models
- [ ] **TTS Service** | 预估: 30min | 类型: code
  - 所需: data models
  - 产出: TTSService.swift + TTSServiceTests.swift
  - 验证: `xcodebuild test -scheme AnkiAnna`
  - 参考: docs/plans/2026-03-05-ankianna-implementation.md#task-4
  - blockedBy: SwiftData Models
- [ ] **Handwriting Recognition Service** | 预估: 30min | 类型: code
  - 所需: data models
  - 产出: HandwritingRecognizer.swift + HandwritingRecognizerTests.swift
  - 验证: `xcodebuild test -scheme AnkiAnna`
  - 参考: docs/plans/2026-03-05-ankianna-implementation.md#task-5
  - blockedBy: SwiftData Models
- [ ] **Learning View (Dictation UI)** | 预估: 1h | 类型: code
  - 所需: SM2Engine + TTSService + HandwritingRecognizer
  - 产出: LearningView + WritingCanvasView + CardPromptView + ResultFeedbackView + LearningViewModel
  - 验证: `xcodebuild build -scheme AnkiAnna`
  - 参考: docs/plans/2026-03-05-ankianna-implementation.md#task-6
  - blockedBy: SM-2 Spaced Repetition Engine, TTS Service, Handwriting Recognition Service
- [ ] **Card Management (Add + Library)** | 预估: 1h | 类型: code
  - 所需: data models
  - 产出: ManualAddCardView + AddCardView + CardLibraryView + CardDetailView
  - 验证: `xcodebuild build -scheme AnkiAnna`
  - 参考: docs/plans/2026-03-05-ankianna-implementation.md#task-7
  - blockedBy: SwiftData Models
- [ ] **AI Card Generation** | 预估: 30min | 类型: code
  - 所需: AddCardView (Task 7)
  - 产出: AIGenerator.swift + AIGenerateView.swift
  - 验证: `xcodebuild build -scheme AnkiAnna`
  - 参考: docs/plans/2026-03-05-ankianna-implementation.md#task-8
  - blockedBy: Card Management (Add + Library)
- [ ] **Stats View (Points, Badges, Calendar)** | 预估: 1h | 类型: code
  - 所需: ReviewRecord model
  - 产出: StatsView + StreakCalendarView + PointsService
  - 验证: `xcodebuild test -scheme AnkiAnna`
  - 参考: docs/plans/2026-03-05-ankianna-implementation.md#task-9
  - blockedBy: SwiftData Models
- [ ] **Integration & Polish** | 预估: 10min | 类型: code
  - 所需: all views + services
  - 产出: IntegrationTests.swift + first-launch setup
  - 验证: `xcodebuild test -scheme AnkiAnna`
  - 参考: docs/plans/2026-03-05-ankianna-implementation.md#task-10
  - blockedBy: Learning View (Dictation UI), AI Card Generation, Stats View (Points, Badges, Calendar)

## Log
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
