# Project: ankianna — Anna 记忆卡片

## Meta
- Area: education
- Status: active
- Path: ~/Projects/ankianna
- Created: 2025-05-01
- Last Updated: 2026-02-25

## 目标
为 Anna 打造个性化的记忆卡片应用，基于间隔重复算法帮助高效记忆学习内容。

## 原则
- 间隔重复：科学的记忆曲线算法
- 儿童友好：简洁直观的界面
- 个性化：针对 Anna 的学习内容定制

## 任务大纲
1. [x] 项目初始化 — 创建目录和虚拟环境 (迁移前)
2. [>] 核心功能开发 — 实现卡片系统和间隔重复

## NEXT: 核心功能开发

### 子任务
- [ ] **设计数据模型** | 预估: 30min | 类型: design
  - 所需: 需求确认（卡片内容类型）
  - 产出: 数据模型设计
- [ ] **实现基础卡片 UI** | 预估: 2h | 类型: feature
  - 所需: 数据模型
  - 产出: 可翻转的卡片界面
- [ ] **实现间隔重复算法** | 预估: 1h | 类型: feature
  - 所需: SM-2 或类似算法
  - 产出: 复习调度逻辑

## Log
- 2026-02-25: 从 /Volumes/nvme1/code/ankianna/ 迁移到 GTD 系统（源目录仅有 venv）

## 操作指南

### 工作流提醒
- 完成子任务的实际工作后 → 主动提醒用户: "子任务「xxx」已完成，要标记吗？(/project-done)"
- 所有子任务完成后 → 自动触发 /project-next
- 完成的工作不在任务大纲中 → 提醒用户: "这是计划外工作，要记录吗？(/project-adhoc)"
- 遇到阻塞/方案变更 → 记录到「项目备忘」并告知用户

### 项目备忘
- 源目录 /Volumes/nvme1/code/ankianna/ 仅含 venv，无实际代码
- 项目处于早期阶段，需从头开发
- 可能的技术栈: Python 或 Swift (iOS/iPad)
