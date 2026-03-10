import XCTest

final class SessionCompleteTests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        // Use single card so we can complete the session quickly
        app = LaunchHelper.launchApp(seedData: false, singleCard: true)
    }

    private func requireSpellingField() -> XCUIElement {
        let textField = app.textFields["spellingTextField"]
        XCTAssertTrue(textField.waitForExistence(timeout: 5), "Expected single-card seeding to show the spelling field")
        return textField
    }

    /// Answer correctly 3 times + confirm mastery to complete session
    private func completeSessionWithSingleCard() {
        for _ in 0..<3 {
            let textField = app.textFields["spellingTextField"]
            guard textField.waitForExistence(timeout: 5) else { break }
            textField.tap()
            textField.typeText("apple")
            app.buttons["submitButton"].tap()

            let nextButton = app.buttons["nextButton"]
            if nextButton.waitForExistence(timeout: 3) {
                nextButton.tap()
            }
        }

        // Handle mastery confirmation alert
        let masteryAlert = app.alerts["完全掌握了吗？"]
        if masteryAlert.waitForExistence(timeout: 3) {
            masteryAlert.buttons["掌握了！"].tap()
        } else {
            // If no mastery alert, try "还没有" or decline
            let declineButton = app.buttons["还没有"]
            if declineButton.exists { declineButton.tap() }
        }
    }

    func testSessionCompleteAfterAllCards() {
        _ = requireSpellingField()
        completeSessionWithSingleCard()

        let completionText = app.staticTexts["今天的学习完成了！"]
        XCTAssertTrue(completionText.waitForExistence(timeout: 5), "Session complete view should appear after all cards")
    }

    func testSessionCompleteShowsStats() {
        _ = requireSpellingField()
        completeSessionWithSingleCard()

        let completionText = app.staticTexts["今天的学习完成了！"]
        XCTAssertTrue(completionText.waitForExistence(timeout: 5))

        let score = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '正确'")).firstMatch
        XCTAssertTrue(score.exists, "Completion should show score")
    }
}
