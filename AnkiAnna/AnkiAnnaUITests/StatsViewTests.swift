import XCTest

final class StatsViewTests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = LaunchHelper.launchApp()
    }

    func testStatsViewShowsContent() {
        LaunchHelper.tapTab("统计", in: app)

        XCTAssertTrue(app.navigationBars["统计"].waitForExistence(timeout: 3))
    }

    func testStatsViewShowsPoints() {
        LaunchHelper.tapTab("统计", in: app)

        // XP text in the level section
        let xpText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'XP'")).firstMatch
        XCTAssertTrue(xpText.waitForExistence(timeout: 5))
    }

    func testStatsViewShowsStreak() {
        LaunchHelper.tapTab("统计", in: app)

        let streakLabel = app.staticTexts["连续打卡"]
        XCTAssertTrue(streakLabel.waitForExistence(timeout: 3))
    }

    func testStatsViewShowsBadgesSection() {
        LaunchHelper.tapTab("统计", in: app)

        // Scroll down to find badges section — it's now further down in the list
        let list = app.collectionViews.firstMatch
        list.swipeUp()
        sleep(1)

        let badgeText = app.staticTexts["小小学徒"]
        XCTAssertTrue(badgeText.waitForExistence(timeout: 5))
    }

    func testStatsViewShowsLevel() {
        LaunchHelper.tapTab("统计", in: app)

        // Level section should show XP text
        let xpText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'XP'")).firstMatch
        XCTAssertTrue(xpText.waitForExistence(timeout: 3))
    }
}
