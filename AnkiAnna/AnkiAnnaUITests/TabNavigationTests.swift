import XCTest

final class TabNavigationTests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = LaunchHelper.launchApp()
    }

    func testAllTabsExist() {
        XCTAssertTrue(LaunchHelper.tabExists("学习", in: app))
        XCTAssertTrue(LaunchHelper.tabExists("卡片库", in: app))
        XCTAssertTrue(LaunchHelper.tabExists("添加", in: app))
        XCTAssertTrue(LaunchHelper.tabExists("统计", in: app))
    }

    func testSwitchToCardLibraryTab() {
        LaunchHelper.tapTab("卡片库", in: app)
        XCTAssertTrue(app.navigationBars.staticTexts.element(matching: NSPredicate(format: "label CONTAINS '卡片库'")).waitForExistence(timeout: 3))
    }

    func testSwitchToAddTab() {
        LaunchHelper.tapTab("添加", in: app)
        XCTAssertTrue(app.navigationBars["添加卡片"].waitForExistence(timeout: 3))
    }

    func testSwitchToStatsTab() {
        LaunchHelper.tapTab("统计", in: app)
        XCTAssertTrue(app.navigationBars["统计"].waitForExistence(timeout: 3))
    }
}
