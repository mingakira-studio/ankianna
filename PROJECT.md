# Project: ankianna — Anna 记忆卡片

## Meta
- Area: education
- Status: active
- Path: ~/Projects/ankianna
- Created: 2025-05-01
- Last Updated: 2026-03-09

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
7. [ ] 基础重构 — CharacterStats 模型、SM-2 修复、技术债清理、课本预装 (Phase 1, Task 1-6)
8. [ ] 字库浏览器 — 替代卡片库，按年级/课文/掌握状态浏览筛选搜索 (Phase 2, Task 7-9)
9. [ ] 游戏模式 — 快速学习 + 限时挑战 + 生存模式 + 闯关模式 + 连连看 (Phase 3, Task 10-16)
10. [ ] 报告系统 — 今日概览、学习趋势图、掌握进度、易错字排行 (Phase 4, Task 17-20)
11. [ ] 集成收尾 — 设置页、全量测试修复、文档更新 (Phase 5, Task 21-23)

## NEXT: 基础重构
> 设计文档: docs/plans/2026-03-09-v2-features-design.md
> 实施计划: docs/plans/2026-03-09-v2-implementation.md（Phase 1, Task 1-6）

- [ ] 新增 CharacterStats 模型（掌握状态 + SM-2 调度字段）→ 计划 Task 1
- [ ] ReviewRecord 增加 repetition 字段，DailySession 增加 newMastered/gameMode → 计划 Task 2
- [ ] TextbookSeeder 服务（首次启动预生成 Cards + CharacterStats）→ 计划 Task 3
- [ ] 修复 SM-2 集成（LearningViewModel 从 CharacterStats 读实际值）→ 计划 Task 4
- [ ] 修复 DailySession 创建 + BadgeService 接入 + UserProfile 初始化 → 计划 Task 5
- [ ] App 启动时课本数据 seeding → 计划 Task 6

## Log
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
- 更新 sp-bridge skill（~/.claude/skills/sp-bridge/SKILL.md）：新增文档引用规则，要求任务大纲带 Phase/Task 映射、NEXT 带设计/实施文档引用、子任务带计划 Task 引用
