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
