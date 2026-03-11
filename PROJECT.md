# Project: ankianna — Anna 记忆卡片

## Meta
- Area: education
- Status: active
- Path: ~/Projects/ankianna
- Created: 2025-05-01
- Last Updated: 2026-03-11

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
7. [x] 基础重构 — CharacterStats 模型、SM-2 修复、技术债清理、课本预装 (Phase 1, Task 1-6) (2026-03-09)
8. [x] 字库浏览器 — 添加tab内嵌课本字库浏览(年级→课文→字)，单字/整课加入卡片库；移除首次启动自动填充；卡片库仅显示用户已选卡片 (Phase 2, Task 7-9) (2026-03-10)
9. [x] 学习流程重设计 — 练习模式、动态队列、三级掌握状态（学习/疑难/熟识） (2026-03-10)
10. [x] 游戏模式 — 快速学习 + 限时挑战 + 生存模式 + 闯关模式 + 连连看 (Phase 3, Task 10-16) (2026-03-11)
11. [>] 报告系统 — 今日概览、学习趋势图、掌握进度、易错字排行 (Phase 4, Task 17-20) ← NEXT
12. [ ] 集成收尾 — 设置页、全量测试修复、文档更新 (Phase 5, Task 21-23)

## NEXT: 报告系统
> 实施计划: docs/plans/2026-03-09-v2-implementation.md (Phase 4, Task 17-20)

## Log
- 14:58 [adhoc] 卡片库列表增强: 显示掌握状态/正确率/正确错误数 + 删除按钮; CardLibraryView.swift 单文件修改, 155 unit + 3 UI tests 回归通过
- 14:06 [project-next] 完成「游戏模式」— GameModeSelectionView(5模式入口)、TimeAttack(限时挑战+加时+combo)、Survival(3命生存+难度递增)、Levels(课文闯关+星级+解锁)、Match(字词连连看); LevelProgress SwiftData模型; 25 unit tests + 7 GameModeTests passed, 全量155单元+UITests回归通过; NEXT=报告系统
- 12:09 [adhoc] 学习界面: 添加 DEBUG 模拟写对/写错按钮 + 自动朗读（进入+切题）; 学习流程重设计方案 docs/plans/2026-03-10-learning-flow-redesign.md, 插入任务大纲 NEXT=学习流程重设计
- 10:43 [project-next] 完成「字库浏览器」— TextbookSeeder.seedDefaultLesson(仅预装二年级上册第一课)、TextbookBrowserView(三级导航:年级→课文→字符+单字/整课加入卡片库)、AddCardView新增课本字库入口; 5 UI tests + 9 unit tests passed, 全量回归通过; NEXT=游戏模式
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
- LearningView DEBUG 模式新增「模拟写对/写错」按钮（#if DEBUG），绕过手写识别直接调用 submitAnswer，方便模拟器测试正确率和学习曲线
- LearningView 进入学习界面自动朗读当前语境，切题时也自动朗读（onChange of showResult），喇叭按钮保留手动重听
- 学习流程重设计方案: docs/plans/2026-03-10-learning-flow-redesign.md — 练习模式(看字写2次+盲写1次)、动态队列(错字随机插回)、三级状态(学习/疑难/熟识)、退出判定(连续对3次/有错对2次/连续错3次)
- 更新 sp-bridge skill（~/.claude/skills/sp-bridge/SKILL.md）：新增文档引用规则，要求任务大纲带 Phase/Task 映射、NEXT 带设计/实施文档引用、子任务带计划 Task 引用
- [决策] 2026-03-10: 字库与卡片库分离 — 原方案: TextbookSeeder 首次启动自动填充 1000+ 字到卡片库 → 新方案: 字库作为「添加」tab 的课本浏览器，用户按年级/课文浏览后手动选择加入卡片库（原因: 卡片库是用户学习清单，不应被预制数据填满）
- CardLibraryView 列表行增强：每行显示掌握状态 badge（已掌握/学习中/疑难字/新字）、正确率、正确✓/错误✗ 计数、红色删除按钮（带确认 alert）；通过 @Query CharacterStats 获取学习数据
