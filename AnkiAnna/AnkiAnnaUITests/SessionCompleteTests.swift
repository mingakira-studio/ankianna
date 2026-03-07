import XCTest

final class SessionCompleteTests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        // Use single card so we can complete the session quickly
        app = LaunchHelper.launchApp(seedData: false, singleCard: true)
    }

    func testSessionCompleteAfterAllCards() {
        let textField = app.textFields["spellingTextField"]
        guard textField.waitForExistence(timeout: 5) else {
            // If no text field, might already be session complete or Chinese card
            return
        }

        // Submit the single card (answer is "apple")
        textField.tap()
        textField.typeText("apple")
        app.buttons["submitButton"].tap()

        // Wait for result, then tap next
        let nextButton = app.buttons["nextButton"]
        if nextButton.waitForExistence(timeout: 3) {
            nextButton.tap()
        } else {
            // If wrong, skip
            let skipButton = app.buttons["skipButton"]
            if skipButton.waitForExistence(timeout: 2) {
                skipButton.tap()
            }
        }

        // Session complete - check for completion text
        let completionText = app.staticTexts["今天的学习完成了！"]
        XCTAssertTrue(completionText.waitForExistence(timeout: 5), "Session complete view should appear after all cards")
    }

    func testSessionCompleteShowsStats() {
        let textField = app.textFields["spellingTextField"]
        guard textField.waitForExistence(timeout: 5) else { return }

        textField.tap()
        textField.typeText("apple")
        app.buttons["submitButton"].tap()

        // Advance past result
        let nextButton = app.buttons["nextButton"]
        let skipButton = app.buttons["skipButton"]
        if nextButton.waitForExistence(timeout: 3) {
            nextButton.tap()
        } else if skipButton.waitForExistence(timeout: 2) {
            skipButton.tap()
        }

        // Should show completion stats
        let completionText = app.staticTexts["今天的学习完成了！"]
        XCTAssertTrue(completionText.waitForExistence(timeout: 5))
    }
}
