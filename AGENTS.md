# Anna 记忆卡片 App

## 项目概述
为 Anna 打造个性化记忆卡片应用，基于间隔重复算法帮助高效记忆。

## 项目路径
- 根目录: ~/Projects/ankianna

## 技术栈
- Swift / SwiftUI (iOS 17+, iPad)
- SwiftData (本地持久化)
- PencilKit (Apple Pencil 手写输入)
- Vision framework (手写识别)
- AVSpeechSynthesizer (TTS)
- XCTest (测试)

## 代码结构
- `AnkiAnna/AnkiAnna/` — 主应用代码
  - `Models/` — SwiftData 数据模型
  - `Services/` — 业务逻辑 (SM2Engine, TTSService, HandwritingRecognizer, AIGenerator, PointsService)
  - `Views/` — SwiftUI 视图 (Learning/, AddCard/, CardLibrary/, Stats/)
- `AnkiAnna/AnkiAnnaTests/` — 单元测试
- `docs/plans/` — 设计文档和实施计划

## 开发约定
- 间隔重复算法 SM-2
- 儿童友好的 UI 设计（小恐龙/龙/粉虫吉祥物）
- 数据本地存储 (SwiftData)
- TDD: 先写测试再实现
- 测试命令: `xcodebuild test -scheme AnkiAnna`
- 构建命令: `xcodebuild build -scheme AnkiAnna`
