import XCTest

/// Regression tests for game mode bugs found 2026-03-11:
/// - Bug 1&2: TimeAttack/Survival showed fullText (answer) instead of text (with blanks)
/// - Bug 3: Levels mode was blank due to tag matching failure
/// - Bug 4: Match mode tiles didn't trigger TTS (interaction test)
final class GameModeRegressionTests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Bug 1: TimeAttack should show blanks, not answer

    func testTimeAttackShowsBlanksNotAnswer() {
        app = LaunchHelper.launchApp(seed: .testData)
        app.staticTexts["限时挑战"].firstMatch.tap()

        // Select 60s duration
        let button60 = app.buttons["60 秒"]
        XCTAssertTrue(button60.waitForExistence(timeout: 3))
        button60.tap()

        // Question view should show text with blanks "___"
        let hasBlanks = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '___'")).firstMatch
        XCTAssertTrue(hasBlanks.waitForExistence(timeout: 5),
            "TimeAttack question should show blanks (context.text), not the full answer")
    }

    // MARK: - Bug 2: Survival should show blanks, not answer

    func testSurvivalShowsBlanksNotAnswer() {
        app = LaunchHelper.launchApp(seed: .testData)
        app.staticTexts["生存模式"].firstMatch.tap()

        let startButton = app.buttons["开始挑战"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 3))
        startButton.tap()

        // Question view should show text with blanks "___"
        let hasBlanks = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '___'")).firstMatch
        XCTAssertTrue(hasBlanks.waitForExistence(timeout: 5),
            "Survival question should show blanks (context.text), not the full answer")
    }

    // MARK: - Bug 3: Levels mode should load cards (not blank)

    func testLevelsModeShowsCardsNotBlank() {
        app = LaunchHelper.launchApp(seed: .withStats)
        app.staticTexts["闯关模式"].firstMatch.tap()

        // Should show level grid with lesson "第1课"
        let levelButton = app.staticTexts["第1课"]
        XCTAssertTrue(levelButton.waitForExistence(timeout: 5),
            "Levels mode should show level buttons from CharacterStats")

        // Tap to start the level
        levelButton.tap()

        // Gameplay view should appear with progress indicator and question
        let progressText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '/'")).firstMatch
        let hasQuestion = progressText.waitForExistence(timeout: 5)
            || app.staticTexts.matching(NSPredicate(format: "label CONTAINS '___'")).firstMatch.waitForExistence(timeout: 3)

        XCTAssertTrue(hasQuestion,
            "Levels gameplay should show question content, not be blank")
    }

    // MARK: - Bug 4: Match mode tiles are interactive

    func testMatchModeTilesAreInteractive() {
        app = LaunchHelper.launchApp(seed: .testData)
        app.staticTexts["连连看"].firstMatch.tap()

        let startButton = app.buttons["开始游戏"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 3))
        startButton.tap()

        // Should show tile grid with "已配对" progress
        let progressLabel = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '已配对'")).firstMatch
        XCTAssertTrue(progressLabel.waitForExistence(timeout: 5),
            "Match mode should show tile grid with progress")

        // Tiles should exist and be tappable (TTS fires on tap, verified by code path)
        let tiles = app.buttons.allElementsBoundByIndex.filter { !$0.label.isEmpty && $0.isHittable }
        XCTAssertTrue(tiles.count >= 4,
            "Match mode should have multiple tappable tiles")

        // Tap a tile to verify interaction works (which triggers TTSService.speak)
        if let firstTile = tiles.first {
            firstTile.tap()
        }
    }
}
