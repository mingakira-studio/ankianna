import XCTest

final class CardEditTests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = LaunchHelper.launchApp()
    }

    func testToggleEditMode() {
        LaunchHelper.tapTab("卡片库", in: app)

        let firstCell = app.cells.firstMatch
        guard firstCell.waitForExistence(timeout: 3) else {
            XCTFail("No card cells found")
            return
        }
        firstCell.tap()

        let editButton = app.buttons["editToggleButton"]
        guard editButton.waitForExistence(timeout: 3) else {
            XCTFail("Edit button not found")
            return
        }

        // Button should say "编辑" initially
        XCTAssertEqual(editButton.label, "编辑")

        editButton.tap()

        // After tap, should say "完成"
        XCTAssertEqual(editButton.label, "完成")

        editButton.tap()

        // Back to "编辑"
        XCTAssertEqual(editButton.label, "编辑")
    }

    func testCardDetailShowsBasicInfo() {
        LaunchHelper.tapTab("卡片库", in: app)

        let firstCell = app.cells.firstMatch
        guard firstCell.waitForExistence(timeout: 3) else {
            XCTFail("No card cells found")
            return
        }
        firstCell.tap()

        // Should show basic info section
        XCTAssertTrue(app.staticTexts["目标字词"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["类型"].exists)
    }
}
