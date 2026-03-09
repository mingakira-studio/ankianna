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
  - `Models/` — SwiftData 数据模型
  - `Services/` — 业务逻辑 (SM2Engine, TTSService, HandwritingRecognizer, AIGenerator, PointsService, BadgeService, LevelService)
  - `Views/` — SwiftUI 视图 (Learning/, AddCard/, CardLibrary/, Stats/)
    - `Learning/` — MascotView, CelebrationEffects (confetti/fire/encouragement), ResultFeedbackView (combo/points animations)
- `AnkiAnna/AnkiAnnaTests/` — 单元测试 (68 tests)
- `AnkiAnna/AnkiAnnaUITests/` — E2E 测试 (23 tests)
- `docs/plans/` — 设计文档和实施计划

## 开发约定
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
- 有 iPad Simulator（iPad Pro 13-inch M5 等），可用于自动化 UI 测试
- 真机测试设备：盛明的iPad（需解锁）
- CocoaPods MLKit 依赖需要 test target 添加 `inherit! :search_paths`
- AnkiAnnaTests target 需要 DEVELOPMENT_TEAM = SSG79B289M

### E2E 测试 (XCUITest)
- UITests target 不需要 pod 依赖（独立进程运行）
- MLKit simulator 兼容：Podfile post_install 保留 MLKit targets 的 EXCLUDED_ARCHS，移除其他 targets 的，xcconfig simulator override 不含 $(inherited)
- iPad TabView 不是 UITabBar，用 `app.buttons[label].firstMatch` 导航
- LaunchHelper 封装 tab 导航处理 iPad/iPhone 差异
