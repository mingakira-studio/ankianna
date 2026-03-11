import XCTest

/// Full user journey E2E tests — simulates real human usage from start to finish.
/// Each test is a complete session, not a fragment.
final class FullJourneyTests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Journey 1: Complete English Learning Session
    // User opens app → sees cards → types answers → gets feedback → completes session

    func testCompleteEnglishLearningSession() {
        app = LaunchHelper.launchApp(seed: .singleCard)
        LaunchHelper.enterQuickLearn(in: app)

        // 1. App opens on 学习 tab, navigate to quick learn → card ready
        let spellingField = app.textFields["spellingTextField"]
        XCTAssertTrue(spellingField.waitForExistence(timeout: 5), "Should see spelling input after entering quick learn")

        // 2. Progress indicator visible
        let progress = app.staticTexts["progressText"]
        XCTAssertTrue(progress.exists, "Progress should show")

        // 3. New flow: single card needs 3 consecutive correct answers to trigger mastery alert
        //    Each correct answer reinserts the card back into the queue until consecutiveCorrect >= 3
        for round in 1...3 {
            let field = app.textFields["spellingTextField"]
            XCTAssertTrue(field.waitForExistence(timeout: 5), "Spelling field should appear for round \(round)")

            field.tap()
            field.typeText("apple")
            app.buttons["submitButton"].tap()

            // Should see correct feedback
            let correctFeedback = app.images["correctFeedback"]
            XCTAssertTrue(correctFeedback.waitForExistence(timeout: 3), "Should see correct feedback in round \(round)")

            // Verify points on first correct answer
            if round == 1 {
                let points = app.staticTexts["pointsEarnedText"]
                XCTAssertTrue(points.exists, "Correct answer should earn points")
            }

            app.buttons["nextButton"].tap()
        }

        // 4. After 3 consecutive correct, mastery alert appears: "完全掌握了吗？"
        let masteryAlert = app.alerts["完全掌握了吗？"]
        XCTAssertTrue(masteryAlert.waitForExistence(timeout: 3), "Mastery confirmation alert should appear")

        // 5. Confirm mastery
        masteryAlert.buttons["掌握了！"].tap()

        // 6. Session complete view appears
        let completion = app.staticTexts["今天的学习完成了！"]
        XCTAssertTrue(completion.waitForExistence(timeout: 5), "Session should complete after mastery confirmation")

        // 7. Completion shows per-character summary with exit reason badge
        let masteredBadge = app.staticTexts["已掌握"]
        XCTAssertTrue(masteredBadge.waitForExistence(timeout: 3), "Completion should show mastered badge")
    }

    // MARK: - Journey 2: Wrong Answer → Retry → Correct → Next
    // User gets wrong answer, retries, gets it right, moves on

    func testWrongAnswerRetryThenCorrect() {
        app = LaunchHelper.launchApp(seed: .englishOnly)
        LaunchHelper.enterQuickLearn(in: app)

        let spellingField = app.textFields["spellingTextField"]
        XCTAssertTrue(spellingField.waitForExistence(timeout: 5))

        // 1. Read the context to figure out which card is shown
        //    We don't know the card order (randomized), so we'll just test the retry flow

        // 2. Type wrong answer
        spellingField.tap()
        spellingField.typeText("zzzzz")
        app.buttons["submitButton"].tap()

        // 3. See wrong feedback with correct answer displayed
        let correctAnswer = app.staticTexts["correctAnswerText"]
        XCTAssertTrue(correctAnswer.waitForExistence(timeout: 3), "Should show correct answer")

        // Read the correct answer text so we can use it in practice mode
        let answerText = correctAnswer.label

        let retryButton = app.buttons["retryButton"]
        XCTAssertTrue(retryButton.exists, "Retry button should be available")

        // 4. Tap retry — enters practice mode (not main spelling field)
        retryButton.tap()

        // 5. Practice mode phase 1: "look and write" with practiceTextField
        let practiceField = app.textFields["practiceTextField"]
        XCTAssertTrue(practiceField.waitForExistence(timeout: 3), "Practice mode text field should appear after retry")

        // Practice character should be visible (phase 1)
        let practiceChar = app.staticTexts["practiceCharacter"]
        XCTAssertTrue(practiceChar.exists, "Practice mode should show the correct character")

        // 6. Type correct answer in practice mode (phase 1, attempt 1 of 2)
        practiceField.tap()
        practiceField.typeText(answerText)
        app.buttons["practiceSubmitButton"].tap()

        // 7. Phase 1, attempt 2 of 2
        let practiceField2 = app.textFields["practiceTextField"]
        XCTAssertTrue(practiceField2.waitForExistence(timeout: 3), "Practice field should reappear for second attempt")
        practiceField2.tap()
        practiceField2.typeText(answerText)
        app.buttons["practiceSubmitButton"].tap()

        // 8. After 2 correct in phase 1, enters phase 2 (blind write)
        let blindMarker = app.staticTexts["practiceBlind"]
        XCTAssertTrue(blindMarker.waitForExistence(timeout: 3), "Should enter blind write phase")

        let practiceField3 = app.textFields["practiceTextField"]
        XCTAssertTrue(practiceField3.waitForExistence(timeout: 3))
        practiceField3.tap()
        practiceField3.typeText(answerText)
        app.buttons["practiceSubmitButton"].tap()

        // 9. After completing practice, should return to main learning flow
        //    Card is reinserted, so either spellingTextField or session continues
        let backToMain = app.textFields["spellingTextField"].waitForExistence(timeout: 5)
            || app.staticTexts["今天的学习完成了！"].waitForExistence(timeout: 1)
        XCTAssertTrue(backToMain, "Should return to main flow after practice completes")
    }

    // MARK: - Journey 3: Browse Card Library → View Detail → Edit → Back
    // User goes to card library, browses, taps a card, edits, returns

    func testCardLibraryBrowseEditJourney() {
        app = LaunchHelper.launchApp(seed: .testData)

        // 1. Navigate to card library
        LaunchHelper.tapTab("卡片库", in: app)

        // 2. Cards are listed (seeded data: 4 cards)
        let firstCell = app.cells.firstMatch
        XCTAssertTrue(firstCell.waitForExistence(timeout: 3), "Card library should show cards")

        // 3. Card count in title
        let titlePredicate = NSPredicate(format: "label CONTAINS '卡片库'")
        let title = app.navigationBars.staticTexts.element(matching: titlePredicate)
        XCTAssertTrue(title.waitForExistence(timeout: 3))

        // 4. Tap into card detail
        firstCell.tap()
        let editButton = app.buttons["editToggleButton"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 3), "Detail should have edit button")
        XCTAssertTrue(app.staticTexts["目标字词"].exists, "Detail should show 目标字词 label")
        XCTAssertTrue(app.staticTexts["类型"].exists, "Detail should show 类型 label")

        // 5. Enter edit mode
        XCTAssertEqual(editButton.label, "编辑")
        editButton.tap()
        XCTAssertEqual(editButton.label, "完成", "Button should say 完成 in edit mode")

        // 6. Exit edit mode
        editButton.tap()
        XCTAssertEqual(editButton.label, "编辑", "Button should revert to 编辑")

        // 7. Go back to library
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(firstCell.waitForExistence(timeout: 3), "Should return to card list")
    }

    // MARK: - Journey 4: Cross-Tab Navigation — Learn → Stats → Library → Add
    // User moves between all tabs checking each has content

    func testCrossTabNavigationJourney() {
        app = LaunchHelper.launchApp(seed: .testData)

        // 1. Start on 学习 tab — now shows game mode selection
        let quickLearn = app.staticTexts["快速学习"]
        XCTAssertTrue(quickLearn.waitForExistence(timeout: 5), "Learning tab should show game modes")
        LaunchHelper.enterQuickLearn(in: app)

        // testData seeds English + Chinese cards; look for any learning UI element
        let hasCard = app.textFields["spellingTextField"].waitForExistence(timeout: 5)
            || app.buttons["提交"].waitForExistence(timeout: 1)
            || app.staticTexts["progressText"].waitForExistence(timeout: 1)
        XCTAssertTrue(hasCard, "Quick learn should show a card")

        // 2. Switch to 统计 tab
        LaunchHelper.tapTab("统计", in: app)
        XCTAssertTrue(app.navigationBars["统计"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["积分"].waitForExistence(timeout: 3), "Stats should show 积分")
        XCTAssertTrue(app.staticTexts["连续打卡"].exists, "Stats should show 连续打卡")

        // 3. Check badges section
        let badge = app.staticTexts["小小学徒"]
        XCTAssertTrue(badge.waitForExistence(timeout: 3), "Stats should show badge names")

        // 4. Check level/XP
        let xp = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'XP'")).firstMatch
        XCTAssertTrue(xp.waitForExistence(timeout: 3), "Stats should show XP")

        // 5. Switch to 卡片库 tab
        LaunchHelper.tapTab("卡片库", in: app)
        XCTAssertTrue(app.cells.firstMatch.waitForExistence(timeout: 3), "Card library should have cards")

        // 6. Switch to 添加 tab
        LaunchHelper.tapTab("添加", in: app)
        XCTAssertTrue(app.navigationBars["添加卡片"].waitForExistence(timeout: 3))

        // 7. Return to 学习 tab — shows game mode selection or learning content
        LaunchHelper.tapTab("学习", in: app)
        let stillFunctional = app.staticTexts["快速学习"].waitForExistence(timeout: 3)
            || app.textFields["spellingTextField"].waitForExistence(timeout: 1)
            || app.buttons["提交"].waitForExistence(timeout: 1)
        XCTAssertTrue(stillFunctional, "Learning tab should still be functional")
    }

    // MARK: - Journey 5: Empty State → Add Tab Prompt
    // New user with no data sees empty state and hint

    func testEmptyStateJourney() {
        app = LaunchHelper.launchApp(seed: .none)

        // 1. Learning tab shows game mode selection (even with no cards)
        let quickLearn = app.staticTexts["快速学习"]
        XCTAssertTrue(quickLearn.waitForExistence(timeout: 5), "Game mode selection should show even with no cards")

        // Enter quick learn to see empty state
        LaunchHelper.enterQuickLearn(in: app)
        let noCards = app.staticTexts["还没有卡片"]
        XCTAssertTrue(noCards.waitForExistence(timeout: 5), "Empty state should show when no cards exist")
        let hint = app.staticTexts["去「添加」页面创建一些卡片吧"]
        XCTAssertTrue(hint.exists, "Hint to add cards should appear")

        // 2. Card library is also empty
        LaunchHelper.tapTab("卡片库", in: app)
        let emptyLibraryTitle = app.navigationBars.staticTexts.element(
            matching: NSPredicate(format: "label CONTAINS '卡片库'"))
        XCTAssertTrue(emptyLibraryTitle.waitForExistence(timeout: 3))
        // No cells should exist
        XCTAssertFalse(app.cells.firstMatch.waitForExistence(timeout: 2), "Empty library should have no cards")

        // 3. Stats tab still works
        LaunchHelper.tapTab("统计", in: app)
        XCTAssertTrue(app.navigationBars["统计"].waitForExistence(timeout: 3))

        // 4. Add tab is accessible
        LaunchHelper.tapTab("添加", in: app)
        XCTAssertTrue(app.navigationBars["添加卡片"].waitForExistence(timeout: 3))
    }

    // MARK: - Journey 6: SM-2 Path with CharacterStats
    // Tests the new Phase 1 code path: cards loaded via CharacterStats + SM-2 scheduling

    func testSM2SchedulingPathWithCharacterStats() {
        app = LaunchHelper.launchApp(seed: .withStats)
        LaunchHelper.enterQuickLearn(in: app)

        // 1. App loads — navigate to quick learn with cards (3 Chinese + 1 English from withStats seed)
        //    LearningView detects CharacterStats exist → uses SM-2 loadDueCards
        let hasLearningContent = app.textFields["spellingTextField"].waitForExistence(timeout: 5)
            || app.buttons["提交"].waitForExistence(timeout: 1)
            || app.staticTexts["progressText"].waitForExistence(timeout: 1)
        XCTAssertTrue(hasLearningContent, "SM-2 path should load cards from CharacterStats")

        // 2. Progress shows card count
        let progress = app.staticTexts["progressText"]
        XCTAssertTrue(progress.exists, "Progress should be visible")

        // 3. Navigate to card library — should have 4 cards
        LaunchHelper.tapTab("卡片库", in: app)
        XCTAssertTrue(app.cells.firstMatch.waitForExistence(timeout: 3), "Library should show seeded cards")

        // 4. Go back to learning and complete a card
        LaunchHelper.tapTab("学习", in: app)
        LaunchHelper.enterQuickLearn(in: app)

        // If English card is shown, type answer; if Chinese, we can only verify UI shows
        let spellingField = app.textFields["spellingTextField"]
        if spellingField.waitForExistence(timeout: 3) {
            spellingField.tap()
            spellingField.typeText("apple")
            app.buttons["submitButton"].tap()

            let gotResult = app.images["correctFeedback"].waitForExistence(timeout: 3)
                || app.staticTexts["correctAnswerText"].waitForExistence(timeout: 1)
            XCTAssertTrue(gotResult, "Should see result after submitting")
        } else {
            // Chinese card on simulator — verify learning UI exists (canvas + simulate buttons)
            let hasChineseUI = app.buttons["simulateCorrectButton"].waitForExistence(timeout: 3)
                || app.staticTexts["progressText"].exists
            XCTAssertTrue(hasChineseUI, "Chinese card should show learning interface")
        }
    }

    // MARK: - Journey 7: Delete Card from Library
    // User deletes a card and verifies it's gone

    func testDeleteCardFromLibrary() {
        app = LaunchHelper.launchApp(seed: .testData)

        LaunchHelper.tapTab("卡片库", in: app)
        let firstCell = app.cells.firstMatch
        XCTAssertTrue(firstCell.waitForExistence(timeout: 3))

        let initialCount = app.cells.count

        // Swipe to delete
        firstCell.swipeLeft()
        let deleteButton = app.buttons["Delete"]
        if deleteButton.waitForExistence(timeout: 2) {
            deleteButton.tap()
            // Count should decrease
            XCTAssertLessThan(app.cells.count, initialCount, "Card count should decrease after delete")
        }
    }

    // MARK: - Journey 8: Real First Launch with TextbookSeeder
    // Tests the actual first-launch path: TextbookSeeder creates cards + CharacterStats from bundled JSON

    func testFirstLaunchTextbookSeeding() {
        app = LaunchHelper.launchApp(seed: .textbook)
        LaunchHelper.enterQuickLearn(in: app)

        // 1. Learning tab → quick learn should have cards loaded from textbook data
        // Textbook cards are Chinese writing type: look for progress text or simulate buttons
        let hasCard = app.staticTexts["progressText"].waitForExistence(timeout: 10)
            || app.buttons["simulateCorrectButton"].waitForExistence(timeout: 3)
            || app.buttons["提交"].waitForExistence(timeout: 1)
            || app.textFields["spellingTextField"].waitForExistence(timeout: 1)
        XCTAssertTrue(hasCard, "Textbook seeding should produce cards for learning")

        // 2. Card library should show many cards (textbook has hundreds)
        LaunchHelper.tapTab("卡片库", in: app)
        let firstCell = app.cells.firstMatch
        XCTAssertTrue(firstCell.waitForExistence(timeout: 5), "Card library should have textbook cards")

        // Title should show non-zero count
        let zeroTitle = app.navigationBars.staticTexts["卡片库 (0)"]
        XCTAssertFalse(zeroTitle.exists, "Card count should NOT be 0 after textbook seeding")

        // 3. Cards should be Chinese writing type (textbook = 中文)
        let chineseLabel = app.staticTexts["中文"].firstMatch
        XCTAssertTrue(chineseLabel.waitForExistence(timeout: 3), "Textbook cards should be Chinese type")

        // 4. Tap into a card — should have textbook context (phrases from words)
        firstCell.tap()
        let detailLoaded = app.staticTexts["目标字词"].waitForExistence(timeout: 3)
        XCTAssertTrue(detailLoaded, "Card detail should load")

        // 5. Go back, switch to learning — enter quick learn again
        app.navigationBars.buttons.firstMatch.tap()
        LaunchHelper.tapTab("学习", in: app)
        LaunchHelper.enterQuickLearn(in: app)
        // Chinese writing card on simulator shows simulate buttons instead of "提交"
        let hasLearningCard = app.staticTexts["progressText"].waitForExistence(timeout: 5)
            || app.buttons["simulateCorrectButton"].waitForExistence(timeout: 3)
        XCTAssertTrue(hasLearningCard, "Chinese textbook card should show learning interface")
    }

    // MARK: - Journey 9: Answer Multiple Cards Until Session Complete
    // User works through all cards in a session

    func testMultiCardSessionFlow() {
        app = LaunchHelper.launchApp(seed: .englishOnly)
        LaunchHelper.enterQuickLearn(in: app)
        var cardsHandled = 0
        // Track correct answers learned from wrong-answer feedback
        var knownAnswers: Set<String> = ["apple", "book", "cat"]
        var lastPracticeAnswer = ""

        // New flow: each card needs 3 consecutive correct answers + mastery alert to exit,
        // or hasError + 2 consecutive correct to exit, or practice mode exit when
        // consecutiveWrong >= 3. With 3 English cards, we need many iterations.
        for _ in 0..<50 {
            // Check if session is already done
            if app.staticTexts["今天的学习完成了！"].waitForExistence(timeout: 1) { break }

            // Handle mastery alert if it appeared
            let masteryAlert = app.alerts["完全掌握了吗？"]
            if masteryAlert.exists {
                masteryAlert.buttons["掌握了！"].tap()
                cardsHandled += 1
                continue
            }

            // Handle difficulty feedback (appears when consecutiveWrong >= 3 after practice)
            if app.staticTexts["标记为疑难字"].waitForExistence(timeout: 0.5) {
                app.buttons["继续"].firstMatch.tap()
                cardsHandled += 1
                continue
            }

            // Handle card exit feedback (auto-dismisses after 1.5s)
            let exitPred = NSPredicate(format: "label CONTAINS '练习完成' OR label CONTAINS '不再是疑难字'")
            if app.staticTexts.matching(exitPred).firstMatch.waitForExistence(timeout: 0.5) {
                _ = app.textFields["spellingTextField"].waitForExistence(timeout: 3)
                    || app.staticTexts["今天的学习完成了！"].waitForExistence(timeout: 1)
                cardsHandled += 1
                continue
            }

            // Handle practice mode if we're in it
            let practiceField = app.textFields["practiceTextField"]
            if practiceField.waitForExistence(timeout: 1) {
                let practiceChar = app.staticTexts["practiceCharacter"]
                let blindMarker = app.staticTexts["practiceBlind"]

                if practiceChar.exists {
                    // Phase 1: type the visible character
                    lastPracticeAnswer = practiceChar.label
                    practiceField.tap()
                    practiceField.typeText(lastPracticeAnswer)
                    app.buttons["practiceSubmitButton"].tap()
                } else if blindMarker.exists {
                    // Phase 2: blind write — use the answer we learned from phase 1
                    practiceField.tap()
                    practiceField.typeText(lastPracticeAnswer)
                    app.buttons["practiceSubmitButton"].tap()
                }
                continue
            }

            // Main learning flow
            let spellingField = app.textFields["spellingTextField"]
            guard spellingField.waitForExistence(timeout: 3) else { break }

            // Try all known answers; the test seeds apple/book/cat
            // We try them all — only one will match
            spellingField.tap()
            spellingField.typeText("apple")
            app.buttons["submitButton"].tap()

            // Wait for result
            let correct = app.images["correctFeedback"]
            let wrong = app.staticTexts["correctAnswerText"]
            let gotResult = correct.waitForExistence(timeout: 3) || wrong.waitForExistence(timeout: 1)
            guard gotResult else { break }

            if correct.exists {
                app.buttons["nextButton"].tap()
            } else {
                // Wrong answer: learn the correct answer and retry to enter practice mode
                let answerLabel = wrong.label
                knownAnswers.insert(answerLabel)

                // Use retry to enter practice mode (required for wrong cards to eventually exit)
                let retryButton = app.buttons["retryButton"]
                if retryButton.exists {
                    retryButton.tap()
                } else {
                    app.buttons["skipButton"].tap()
                }
            }
            cardsHandled += 1
        }

        XCTAssertGreaterThan(cardsHandled, 0, "Should handle at least one card")

        // Session should be complete
        let completionText = app.staticTexts["今天的学习完成了！"]
        XCTAssertTrue(completionText.waitForExistence(timeout: 5), "Session should complete after all cards")

        // Verify per-character summary with exit reason badges
        let exitBadge = app.staticTexts.matching(
            NSPredicate(format: "label == '已掌握' OR label == '已完成' OR label == '疑难字'")
        ).firstMatch
        XCTAssertTrue(exitBadge.waitForExistence(timeout: 3), "Completion should show exit reason badges")
    }

    // MARK: - Helpers

    private func enterPracticeModeFromWrong() {
        let field = app.textFields["spellingTextField"]
        XCTAssertTrue(field.waitForExistence(timeout: 5), "Spelling field should appear")
        field.tap()
        field.typeText("zzzzwrong")
        app.buttons["submitButton"].tap()
        XCTAssertTrue(app.staticTexts["correctAnswerText"].waitForExistence(timeout: 3), "Wrong feedback should appear")
        app.buttons["retryButton"].tap()
    }

    private func completePracticePhase(answer: String) {
        // Phase 1, attempt 1
        var pf = app.textFields["practiceTextField"]
        XCTAssertTrue(pf.waitForExistence(timeout: 3), "Practice field should appear")
        pf.tap()
        pf.typeText(answer)
        app.buttons["practiceSubmitButton"].tap()

        // Wait for correct flash animation (0.8s) + SwiftUI re-render
        Thread.sleep(forTimeInterval: 1.5)

        // Phase 1, attempt 2
        pf = app.textFields["practiceTextField"]
        XCTAssertTrue(pf.waitForExistence(timeout: 3), "Practice field should reappear")
        pf.tap()
        pf.typeText(answer)
        app.buttons["practiceSubmitButton"].tap()

        // Wait for transition to phase 2
        Thread.sleep(forTimeInterval: 1.5)

        // Phase 2: blind write
        XCTAssertTrue(app.staticTexts["practiceBlind"].waitForExistence(timeout: 3), "Should enter blind write")
        pf = app.textFields["practiceTextField"]
        XCTAssertTrue(pf.waitForExistence(timeout: 3))
        pf.tap()
        pf.typeText(answer)
        app.buttons["practiceSubmitButton"].tap()
    }

    // MARK: - Journey 10: Difficulty Feedback After Consecutive Wrong Answers

    func testDifficultyFeedbackAfterConsecutiveWrongs() {
        app = LaunchHelper.launchApp(seed: .singleCard)
        LaunchHelper.enterQuickLearn(in: app)
        let answer = "apple"

        // 3 cycles of: wrong in main flow → practice succeeds → card reinserted
        // After 3rd cycle, consecutiveWrong >= 3 → difficulty feedback
        for cycle in 1...3 {
            enterPracticeModeFromWrong()
            completePracticePhase(answer: answer)

            if cycle < 3 {
                // Card reinserted → back to main flow
                XCTAssertTrue(
                    app.textFields["spellingTextField"].waitForExistence(timeout: 5),
                    "Should return to main flow after practice cycle \(cycle)"
                )
            }
        }

        // Difficulty feedback should appear (use text-based detection; VStack identifiers not accessible in XCUITest)
        let difficultyText = app.staticTexts["标记为疑难字"]
        XCTAssertTrue(difficultyText.waitForExistence(timeout: 5), "Difficulty feedback should appear")
        XCTAssertTrue(app.staticTexts["下次会优先复习这个字"].exists)

        // Dismiss
        app.buttons["继续"].firstMatch.tap()

        // Session should complete
        XCTAssertTrue(
            app.staticTexts["今天的学习完成了！"].waitForExistence(timeout: 5),
            "Session should complete after difficulty dismiss"
        )
    }

    // MARK: - Journey 11: Card Exit Feedback After Error Then Correct

    func testCardExitFeedbackAfterErrorThenCorrect() {
        app = LaunchHelper.launchApp(seed: .singleCard)
        LaunchHelper.enterQuickLearn(in: app)
        let answer = "apple"

        // Step 1: Wrong answer → practice → back (sets hasError=true)
        enterPracticeModeFromWrong()
        completePracticePhase(answer: answer)

        // Step 2: First correct answer (consecutiveCorrect=1, hasError=true)
        var field = app.textFields["spellingTextField"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText(answer)
        app.buttons["submitButton"].tap()
        XCTAssertTrue(app.images["correctFeedback"].waitForExistence(timeout: 3), "Should show correct feedback")
        app.buttons["nextButton"].tap()

        // Step 3: Second correct answer (consecutiveCorrect=2 → exit feedback)
        field = app.textFields["spellingTextField"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText(answer)
        app.buttons["submitButton"].tap()
        XCTAssertTrue(app.images["correctFeedback"].waitForExistence(timeout: 3))
        app.buttons["nextButton"].tap()

        // Card exit feedback should appear (use text-based detection; VStack identifiers not accessible in XCUITest)
        let exitMsg = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS '今日练习完成'")
        ).firstMatch
        XCTAssertTrue(exitMsg.waitForExistence(timeout: 3), "Card exit feedback should appear with '今日练习完成' message")

        // Wait for auto-dismiss → session complete
        XCTAssertTrue(
            app.staticTexts["今天的学习完成了！"].waitForExistence(timeout: 5),
            "Session should complete after card exit feedback"
        )
    }

    // MARK: - Journey 12: Practice Mode Correct Icon Appears

    func testPracticeCorrectIconAppears() {
        app = LaunchHelper.launchApp(seed: .singleCard)
        LaunchHelper.enterQuickLearn(in: app)

        // Enter practice mode via wrong answer
        enterPracticeModeFromWrong()

        // Type correct answer in practice
        let pf = app.textFields["practiceTextField"]
        XCTAssertTrue(pf.waitForExistence(timeout: 3))
        pf.tap()
        pf.typeText("apple")
        app.buttons["practiceSubmitButton"].tap()

        // After correct practice answer, progress updates (practicePhase1Count increments)
        // The label shows "(practicePhase1Count + 1)/2", so after 1st correct: "2/2"
        let progressText = app.staticTexts["practiceProgress"]
        XCTAssertTrue(progressText.waitForExistence(timeout: 3), "Practice progress should be visible after correct answer")
        XCTAssertEqual(progressText.label, "2/2", "Practice progress should show 2/2 after first correct")
    }
}
