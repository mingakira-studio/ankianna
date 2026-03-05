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
- [ ] **Xcode 项目搭建** | 预估: 30min | 类型: setup
  - 所需: 设计文档
  - 产出: SwiftUI 项目骨架 + SwiftData 模型
- [ ] **SM-2 间隔重复引擎** | 预估: 1h | 类型: feature
  - 所需: 数据模型
  - 产出: SM2Engine + 单元测试
- [ ] **TTS 发音服务** | 预估: 30min | 类型: feature
  - 所需: AVSpeechSynthesizer
  - 产出: TTSService（中英文朗读）
- [ ] **听写主界面** | 预估: 3h | 类型: feature
  - 所需: 数据模型 + TTS
  - 产出: PencilKit 书写 + Vision 手写识别 + 判定流程
- [ ] **卡片管理** | 预估: 2h | 类型: feature
  - 所需: 数据模型
  - 产出: 手动添加 + AI 生成 + 卡片库浏览
- [ ] **游戏化与统计** | 预估: 2h | 类型: feature
  - 所需: 复习记录
  - 产出: 积分、打卡日历、小恐龙吉祥物

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
- Apple Pencil 手写识别需真机测试，无法完全自动化
