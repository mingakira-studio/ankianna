import XCTest

final class EmptyStateTests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        // Launch without seeding data
        app = LaunchHelper.launchApp(seedData: false)
        LaunchHelper.enterQuickLearn(in: app)
    }

    func testEmptyStateShowsWhenNoCards() {
        let noCardsText = app.staticTexts["还没有卡片"]
        XCTAssertTrue(noCardsText.waitForExistence(timeout: 5), "Empty state should show when no cards exist")
    }

    func testEmptyStateShowsMessage() {
        let hintText = app.staticTexts["去「添加」页面创建一些卡片吧"]
        XCTAssertTrue(hintText.waitForExistence(timeout: 5))
    }
}
