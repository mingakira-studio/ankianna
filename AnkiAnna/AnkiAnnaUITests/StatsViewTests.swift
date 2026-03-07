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

        // Should show points label
        let pointsLabel = app.staticTexts["积分"]
        XCTAssertTrue(pointsLabel.waitForExistence(timeout: 3))
    }

    func testStatsViewShowsStreak() {
        LaunchHelper.tapTab("统计", in: app)

        let streakLabel = app.staticTexts["连续打卡"]
        XCTAssertTrue(streakLabel.waitForExistence(timeout: 3))
    }

    func testStatsViewShowsBadgesSection() {
        LaunchHelper.tapTab("统计", in: app)

        // Badge grid should show badge names (e.g. first badge "小小学徒")
        let badgeText = app.staticTexts["小小学徒"]
        XCTAssertTrue(badgeText.waitForExistence(timeout: 3))
    }

    func testStatsViewShowsLevel() {
        LaunchHelper.tapTab("统计", in: app)

        // Level section should show XP text
        let xpText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'XP'")).firstMatch
        XCTAssertTrue(xpText.waitForExistence(timeout: 3))
    }
}
