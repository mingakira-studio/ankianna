import XCTest

/// UI Screenshot Tests — 自动导航到各关键页面并截图
/// 截图保存为 XCTAttachment，通过 xcresulttool 提取后 AI 审查
///
/// 运行: ios-ui-screenshot-test.sh (通用脚本)
/// 或: xcodebuild test -only-testing:AnkiAnnaUITests/UIScreenshotTests
final class UIScreenshotTests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = true
        app = LaunchHelper.launchApp(seed: .withStats)
    }

    // MARK: - Tab Screens

    func test01_HomeGameModeSelection() {
        // 首页：游戏模式选择 + 底部 tab badge
        XCTAssertTrue(app.staticTexts["快速学习"].waitForExistence(timeout: 5))
        snapshot("01_home_game_mode_selection", requirements: [
            "5 个游戏模式卡片可见（快速学习/限时挑战/闯关模式/生存模式/连连看）",
            "学习 tab 有红色数字 badge（待复习提示）",
            "卡片颜色统一使用 DesignTokens 语义色",
            "SF Rounded 字体"
        ])
    }

    func test02_CardLibrary() {
        // 卡片库：正确率图标 + 掌握状态
        LaunchHelper.tapTab("卡片库", in: app)
        sleep(1)
        snapshot("02_card_library", requirements: [
            "正确率数字旁有趋势箭头图标（↗绿/→橙/↘红）",
            "掌握状态 badge（新字/学习中/疑难字/已掌握）",
            "大字 + 正确率 + 练习次数 + 上次时间 布局合理"
        ])
    }

    func test03_StatsStreakCalendar() {
        // 统计页：打卡日历 + 徽章
        LaunchHelper.tapTab("统计", in: app)
        sleep(1)
        snapshot("03_stats_streak_calendar", requirements: [
            "打卡日历中完成日有绿色圆点 + 白色 checkmark",
            "未打卡日为灰色圆点（无 checkmark）",
            "等级/积分/连续打卡数据可见"
        ])
    }

    // MARK: - Game Over Screens (via DEBUG 模拟按钮)

    func test04_SurvivalGameOver() {
        // 生存模式 → 开始 → 答错3次 → 游戏结束
        app.staticTexts["生存模式"].firstMatch.tap()

        let startButton = app.buttons["开始挑战"]
        guard startButton.waitForExistence(timeout: 3) else {
            XCTFail("找不到开始挑战按钮")
            return
        }
        startButton.tap()
        sleep(1)

        // 答错3次触发 game over (支持中文手写 + 英文输入两种卡片类型)
        for _ in 0..<3 {
            if app.staticTexts["游戏结束"].exists { break }
            triggerWrongAnswer()
            sleep(1)
            // 点继续（答错反馈页）
            let continueButton = app.buttons["继续"]
            if continueButton.waitForExistence(timeout: 3) {
                continueButton.tap()
                sleep(1)
            }
        }

        // 等待 game over 画面
        sleep(1)
        snapshot("04_survival_game_over", requirements: [
            "游戏结束标题可见",
            "有\"返回首页\"按钮（左侧/bordered 样式）",
            "有\"再来一次\"按钮（右侧/borderedProminent 样式）",
            "统计信息卡片（存活数/最佳连击）"
        ])
    }

    func test05_TimeAttackStart() {
        // 限时挑战选择页（不实际开始游戏）
        app.staticTexts["限时挑战"].firstMatch.tap()
        sleep(1)
        snapshot("05_time_attack_start", requirements: [
            "限时挑战标题",
            "60/90/120 秒选择按钮",
            "过渡动画生效（视觉无法通过截图判断，标记 manual-only）"
        ])
    }

    func test06_AnswerCorrectFeedback() {
        // 快速学习 → 答对 → 查看反馈
        LaunchHelper.enterQuickLearn(in: app)
        sleep(1)

        let correctButton = app.buttons["模拟写对"]
        guard correctButton.waitForExistence(timeout: 5) else {
            // 可能没有卡片或直接进入了其他状态
            snapshot("06_answer_correct_feedback_unavailable", requirements: [
                "无法进入快速学习模式（可能无可学卡片）"
            ])
            return
        }
        correctButton.tap()
        sleep(1)

        snapshot("06_answer_correct_feedback", requirements: [
            "绿色 checkmark 图标",
            "\"太棒了！\" 鼓励文字",
            "「X」写对了 — 显示答对的具体字",
            "积分 +N 显示",
            "下一个按钮"
        ])
    }

    // MARK: - Levels Battle Mode

    func test07_LevelsSelection() {
        // 闯关模式关卡选择页
        app.staticTexts["闯关模式"].firstMatch.tap()
        sleep(1)
        snapshot("07_levels_selection", requirements: [
            "暗色游戏风格背景（深紫/深蓝渐变，非白色）",
            "关卡卡片使用紫蓝渐变填充+边框",
            "每个关卡显示「第N课」+ 课文标题 + 字数",
            "已完成关卡有星级评分（黄色星星）",
            "锁定关卡有锁图标",
            "右上方有龙角色（MascotView）"
        ])
    }

    func test08_LevelsBattle() {
        // 闯关模式战斗场景
        app.staticTexts["闯关模式"].firstMatch.tap()
        sleep(1)

        // 点击第一个解锁的关卡
        let firstLesson = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH '第'")).firstMatch
        guard firstLesson.waitForExistence(timeout: 3) else {
            snapshot("08_levels_battle_no_levels", requirements: [
                "无可用关卡（可能需要课本数据）"
            ])
            return
        }
        firstLesson.tap()
        sleep(1)

        snapshot("08_levels_battle_scene", requirements: [
            "暗色战场背景（深色渐变）",
            "左侧有龙角色（MascotView/DragonCharacter）",
            "右侧有字妖角色（紫色渐变圆球+红色角+红色眼+汉字）",
            "顶部 HUD: 课名 + 红色心形HP(♥) + 进度计数",
            "底部有字妖进度网格（小方块图标，当前字高亮）",
            "中间有提示文字（Capsule 样式对话框）",
            "下方有写字区域（WritingCanvasWithTools）"
        ])
    }

    func test09_LevelsBattleAttack() {
        // 闯关模式 — 攻击效果
        app.staticTexts["闯关模式"].firstMatch.tap()
        sleep(1)

        let firstLesson = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH '第'")).firstMatch
        guard firstLesson.waitForExistence(timeout: 3) else { return }
        firstLesson.tap()
        sleep(1)

        // 模拟写对触发攻击
        let correctButton = app.buttons["模拟写对"]
        guard correctButton.waitForExistence(timeout: 3) else { return }
        correctButton.tap()
        sleep(1)

        snapshot("09_levels_attack_hit", requirements: [
            "显示「命中!」文字（橙色火焰图标）",
            "字妖受击状态（可能有震动/变色效果）"
        ])
    }

    func test10_LevelsGameOver() {
        // 闯关模式 — 失败画面
        app.staticTexts["闯关模式"].firstMatch.tap()
        sleep(1)

        let firstLesson = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH '第'")).firstMatch
        guard firstLesson.waitForExistence(timeout: 3) else { return }
        firstLesson.tap()
        sleep(1)

        // 答错3次耗尽龙HP
        for _ in 0..<3 {
            if app.staticTexts["挑战失败"].exists { break }
            triggerWrongAnswer()
            sleep(2) // 等待1秒动画延迟 + 额外缓冲
        }
        sleep(1)

        snapshot("10_levels_game_over", requirements: [
            "暗红色背景渐变",
            "龙角色显示鼓励状态（encourage）",
            "「挑战失败」标题（白色大字）",
            "击败数统计（N/M 个字妖）",
            "「返回首页」按钮（半透明样式）",
            "「重新挑战」按钮（红橙渐变 Capsule）"
        ])
    }

    // MARK: - Helpers

    /// 触发一次答错（自动判断中文/英文卡片类型）
    private func triggerWrongAnswer() {
        // 中文手写卡：有 DEBUG 模拟写错按钮
        let wrongButton = app.buttons["模拟写错"]
        if wrongButton.waitForExistence(timeout: 2) {
            wrongButton.tap()
            return
        }
        // 英文输入卡：在 TextField 中输入错误答案并提交
        let textField = app.textFields["输入答案"]
        if textField.waitForExistence(timeout: 2) {
            textField.tap()
            textField.typeText("zzz\n")
            return
        }
    }

    /// 截图并附加设计要求（嵌入为 attachment 的 userInfo）
    private func snapshot(_ name: String, requirements: [String] = []) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)

        // 同时保存要求到单独的 attachment
        if !requirements.isEmpty {
            let text = requirements.enumerated()
                .map { "[\($0.offset + 1)] \($0.element)" }
                .joined(separator: "\n")
            let reqAttachment = XCTAttachment(string: text)
            reqAttachment.name = "\(name)_requirements"
            reqAttachment.lifetime = .keepAlways
            add(reqAttachment)
        }
    }
}
