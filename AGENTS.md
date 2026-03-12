# Anna 记忆卡片 App

## 项目概述
为 Anna 打造个性化记忆卡片应用，基于间隔重复算法帮助高效记忆。

## 项目路径
- 根目录: ~/Projects/ankianna

## 技术栈
- Swift / SwiftUI (iOS 17+, iPad)
- SwiftData (本地持久化)
- PencilKit (Apple Pencil 手写输入)
- Google ML Kit Digital Ink Recognition (手写识别)
- AVSpeechSynthesizer (TTS)
- XCTest (测试)

## 代码结构
- `AnkiAnna/AnkiAnna/` — 主应用代码
  - `Models/` — SwiftData 数据模型 (Card, CardContext, ReviewRecord, DailySession, UserProfile, CharacterStats, LevelProgress)
  - `Services/` — 业务逻辑 (SM2Engine, TTSService, HandwritingRecognizer, AIGenerator, PointsService, BadgeService, LevelService, TextbookSeeder, HapticService)
  - `Views/` — SwiftUI 视图 (Learning/, AddCard/, CardLibrary/, Stats/)
    - `Learning/` — GameModeSelectionView (入口), LearningView (快速学习), MascotView, CelebrationEffects, ResultFeedbackView
      - `TimeAttack/` — 限时挑战模式 (TimeAttackView + ViewModel)
      - `Survival/` — 生存模式 (SurvivalView + ViewModel)
      - `Levels/` — 闯关模式 (LevelsView + ViewModel)
      - `Match/` — 连连看模式 (MatchView + ViewModel)
    - `AddCard/` — AddCardView (入口), ManualAddCardView, AIGenerateView, TextbookBrowserView (课本字库三级导航)
- `AnkiAnna/AnkiAnnaTests/` — 单元测试
- `AnkiAnna/AnkiAnnaUITests/` — E2E 测试
- `docs/plans/` — 设计文档和实施计划

## 开发约定
- 部署到 iPad 前必须 clean build（`xcodebuild clean build`），避免安装缓存的旧版本
- 真机验证时走 `/deploy-ipad` 全流程（clean build → 安装 → 验证），不要手动拼命令
- 间隔重复算法 SM-2
- 儿童友好的 UI 设计（小恐龙/龙/粉虫吉祥物）
- 数据本地存储 (SwiftData)
- TDD: 先写测试再实现
- 依赖管理: CocoaPods (`AnkiAnna/Podfile`)
- 构建必须使用 xcworkspace（不是 xcodeproj）
- 测试命令: `xcodebuild test -workspace AnkiAnna.xcworkspace -scheme AnkiAnna`
- 构建命令: `xcodebuild build -workspace AnkiAnna.xcworkspace -scheme AnkiAnna`
- 真机部署: `xcodebuild clean build -workspace AnkiAnna.xcworkspace -scheme AnkiAnna -destination 'platform=iOS,name=盛明的iPad' -allowProvisioningUpdates`

## 跨 Session 记忆

### 用户偏好
- 并行开发时优先用 Agent Team（TeamCreate + 有 tmux panel），不用 background Agent，这样进度更直观

### 构建环境
- iPad Simulator: `iPad Pro 13-inch (M5)` (OS 26.2), 使用 `id=493C6161-D3FC-40E0-8324-1678831049EB`
- xcodegen 管理项目结构（`AnkiAnna/project.yml`），新增文件后运行 `cd AnkiAnna && xcodegen generate`
- 真机测试设备：盛明的iPad（需解锁）
- CocoaPods MLKit 依赖需要 test target 添加 `inherit! :search_paths`
- AnkiAnnaTests target 需要 DEVELOPMENT_TEAM = SSG79B289M

### E2E 测试 (XCUITest)
- UITests target 不需要 pod 依赖（独立进程运行）
- MLKit simulator 兼容：Podfile post_install 保留 MLKit targets 的 EXCLUDED_ARCHS，移除其他 targets 的，xcconfig simulator override 不含 $(inherited)
- iPad TabView 不是 UITabBar，用 `app.buttons[label].firstMatch` 导航
- LaunchHelper 封装 tab 导航处理 iPad/iPhone 差异

### [evolve] 标签规则
- 来自 evolve-engine 建议的任务/idea 必须带 `[evolve]` 标签（如 `- [ ] [evolve] 任务描述`）
- 完成 `[evolve]` 标签任务时，需将执行反馈回写到对应的 reflect 文件（参见 project-done skill Step 3.5）
