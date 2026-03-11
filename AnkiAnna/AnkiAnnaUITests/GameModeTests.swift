import XCTest

final class GameModeTests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = LaunchHelper.launchApp(seed: .testData)
    }

    func testGameModeSelectionShowsAllModes() {
        XCTAssertTrue(app.staticTexts["快速学习"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["限时挑战"].exists)
        XCTAssertTrue(app.staticTexts["生存模式"].exists)
        XCTAssertTrue(app.staticTexts["闯关模式"].exists)
        XCTAssertTrue(app.staticTexts["连连看"].exists)
    }

    func testQuickLearnModeNavigatesToLearning() {
        app.staticTexts["快速学习"].firstMatch.tap()
        let hasContent = app.textFields["spellingTextField"].waitForExistence(timeout: 5)
            || app.buttons["提交"].waitForExistence(timeout: 1)
            || app.staticTexts["还没有卡片"].waitForExistence(timeout: 1)
        XCTAssertTrue(hasContent, "Quick learn should show learning interface")
    }

    func testTimeAttackShowsDurationPicker() {
        app.staticTexts["限时挑战"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["选择时长"].waitForExistence(timeout: 3)
            || app.buttons["60 秒"].waitForExistence(timeout: 3),
            "Time attack should show duration picker")
    }

    func testSurvivalModeShowsStartButton() {
        app.staticTexts["生存模式"].firstMatch.tap()
        XCTAssertTrue(app.buttons["开始挑战"].waitForExistence(timeout: 3),
            "Survival mode should show start button")
    }

    func testLevelsModeShowsLevelGrid() {
        // Levels mode needs CharacterStats to populate, use withStats seed
        app = LaunchHelper.launchApp(seed: .withStats)
        app.staticTexts["闯关模式"].firstMatch.tap()
        // Should show navigation title
        XCTAssertTrue(app.navigationBars["闯关模式"].waitForExistence(timeout: 3),
            "Levels mode should show level selection")
    }

    func testMatchModeShowsStartButton() {
        app.staticTexts["连连看"].firstMatch.tap()
        XCTAssertTrue(app.buttons["开始游戏"].waitForExistence(timeout: 3),
            "Match mode should show start button")
    }

    func testNavigationBackFromMode() {
        app.staticTexts["限时挑战"].firstMatch.tap()
        // Go back
        app.navigationBars.buttons.firstMatch.tap()
        // Should be back at mode selection
        XCTAssertTrue(app.staticTexts["快速学习"].waitForExistence(timeout: 3),
            "Should return to mode selection after back")
    }
}
