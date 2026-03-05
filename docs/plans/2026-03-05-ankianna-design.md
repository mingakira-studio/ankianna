# AnkiAnna 设计文档

## 概述
为 Anna（8岁）打造的个性化听写/默写记忆卡片 iPad App，基于间隔重复算法，支持中文写字和英文拼写。

## 技术方案
- **平台**: SwiftUI 原生 iPad App, iOS 17+
- **存储**: SwiftData 本地持久化
- **手写**: PencilKit (Apple Pencil) + Vision 框架手写识别
- **发音**: AVSpeechSynthesizer (iOS 系统 TTS)
- **AI 生成**: LLM API (Claude/OpenAI), API key 存 Keychain
- **分发**: TestFlight 或 Xcode 直装

## 数据模型

### Card（卡片）
| 字段 | 类型 | 说明 |
|------|------|------|
| id | UUID | 主键 |
| type | CardType | .chineseWriting / .englishSpelling |
| answer | String | 目标字/词（如"龙"、"dragon"） |
| contexts | [CardContext] | 多组语境，复习时随机选一个 |
| audioText | String | TTS 朗读内容 |
| hint | String? | 可选提示 |
| tags | [String] | 分类标签（年级、课本、主题） |
| source | CardSource | .manual / .aiGenerated |
| createdAt | Date | 创建时间 |

### CardContext（语境）
| 字段 | 类型 | 说明 |
|------|------|------|
| id | UUID | 主键 |
| type | ContextType | .phrase（组词）/ .sentence（造句） |
| text | String | 含空位的文本（如"___飞凤舞"） |
| fullText | String | 完整文本（TTS 朗读用） |
| source | CardSource | .manual / .aiGenerated |

### ReviewRecord（复习记录）
| 字段 | 类型 | 说明 |
|------|------|------|
| cardId | UUID | 关联卡片 |
| reviewedAt | Date | 复习时间 |
| result | ReviewResult | .correct / .wrong |
| ease | Double | SM-2 ease factor |
| interval | Int | 当前间隔（天） |
| nextReviewDate | Date | 下次复习日期 |
| handwritingImage | Data? | 手写笔迹（可选保存） |

### DailySession（每日学习会话）
| 字段 | 类型 | 说明 |
|------|------|------|
| date | Date | 日期 |
| targetCount | Int | 每天目标卡片数 |
| completedCount | Int | 已完成数 |
| correctCount | Int | 正确数 |
| streak | Int | 连续打卡天数 |

### UserProfile（用户档案）
| 字段 | 类型 | 说明 |
|------|------|------|
| name | String | 用户名 |
| dailyGoal | Int | 每日复习目标 |
| totalPoints | Int | 积分 |
| badges | [Badge] | 获得的徽章 |

## 核心交互流程

### 中文听写
1. 显示组词/例句（目标字用 ＿ 替代），从多组语境中随机选一个
2. TTS 朗读完整词/句（含目标字发音）
3. Anna 用 Apple Pencil 在书写区手写
4. 提交 → iOS Vision 手写识别 (VNRecognizeTextRequest)
5. 判定结果：正确 → 鼓励动画；错误 → 显示正确写法，可选"再试"或"下一张"
6. 可选保存手写笔迹用于回顾

### 英文拼写
1. 显示语境句子（目标词用 ＿＿＿ 替代），从多组语境中随机选一个
2. TTS 朗读完整句子
3. Anna 手写或键盘输入
4. 字符串匹配判定（忽略大小写）
5. 反馈同上

### 每日学习
1. 打开 App → 小恐龙欢迎 + 今日目标
2. SM-2 算法按优先级排列待复习卡片，每日定量
3. 逐张完成听写
4. 全部完成 → 结算页面（正确率、积分、连续打卡）

## 卡片生成

### 手动添加
App 内表单：类型、目标字词、组词/语境、TTS 文本、标签

### AI 自动生成
- 输入年级 + 科目 + 单元/主题
- LLM 生成 5-8 个语境（组词 + 造句）
- 用户预览 → 批量确认导入 / 逐条编辑删除

### 语境随机机制
- 同一个字/词有多组语境，复习时随机选一个
- 已用过的语境短期内不重复
- 防止死记组词，确保真正记住字

## 游戏化 & UI

### 吉祥物
- 小恐龙作为主角伴侣（不同状态有不同表情/动作）
- 神话龙、粉虫作为徽章/奖励角色

### 激励机制
- **积分**: 答对 +10，combo 加成，每日达标 +50
- **徽章**: "小恐龙学徒"（第1天）、"神龙觉醒"（连续7天）、"粉虫探险家"（100字）等
- **打卡日历**: 可视化连续记录，断卡不惩罚（儿童友好）

### 视觉风格
- 可爱卡通风，圆角卡片，柔和配色（粉色/浅蓝/薄荷绿）
- 按钮大而清晰，适合儿童
- 书写区域占屏幕 60%+（iPad 横屏）
- 轻量动画反馈

### 页面结构（TabBar 底部导航）
1. 学习 — 每日听写主界面
2. 卡片库 — 浏览/管理所有卡片
3. 添加 — 手动添加 / AI 生成
4. 统计 — 积分、徽章、打卡日历

## 项目结构
```
AnkiAnna.xcodeproj
├── Models/          — SwiftData 模型
├── Views/
│   ├── Learning/    — 听写主界面、书写区
│   ├── CardLibrary/ — 卡片浏览管理
│   ├── AddCard/     — 手动添加 & AI 生成
│   └── Stats/       — 统计、徽章、日历
├── Services/
│   ├── SM2Engine     — 间隔重复算法
│   ├── HandwritingRecognizer — Vision 框架手写识别
│   ├── TTSService    — AVSpeechSynthesizer 封装
│   └── AIGenerator   — LLM API 调用
├── Assets/          — 吉祥物素材
└── Tests/           — XCTest 单元测试
```

## MVP 范围

### 包含
- 中文听写（手写 + iOS 识别判定）
- 英文拼写（手写 + 字符串匹配）
- SM-2 间隔重复 + 每日定量
- 手动添加卡片
- AI 生成卡片（多语境）
- TTS 发音
- 基础积分 & 打卡记录
- 小恐龙吉祥物（静态图 + 简单表情切换）

### 后续迭代
- 笔顺动画引导
- 复杂徽章体系
- 数学/兴趣知识卡片
- 多用户支持
- iCloud 同步
- App Store 上架

## 测试策略
- **单元测试**: SM-2 算法、数据模型、卡片调度逻辑（xcodebuild CLI 自动化）
- **UI 测试**: 导航、按钮、页面跳转（XCUITest + Simulator）
- **手写测试**: Apple Pencil 手写识别需真机 + 真笔手动测试
