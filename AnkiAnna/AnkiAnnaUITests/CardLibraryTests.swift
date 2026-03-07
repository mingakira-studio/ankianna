import XCTest

final class CardLibraryTests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = LaunchHelper.launchApp()
    }

    func testCardListShowsCards() {
        LaunchHelper.tapTab("卡片库", in: app)

        // Should show card library with seeded cards
        let navTitle = app.navigationBars.staticTexts.element(matching: NSPredicate(format: "label CONTAINS '卡片库'"))
        XCTAssertTrue(navTitle.waitForExistence(timeout: 3))

        // At least one card should exist in the list
        let cells = app.cells
        XCTAssertTrue(cells.firstMatch.waitForExistence(timeout: 3), "Card list should have at least one card")
    }

    func testNavigateToCardDetail() {
        LaunchHelper.tapTab("卡片库", in: app)

        let firstCell = app.cells.firstMatch
        guard firstCell.waitForExistence(timeout: 3) else {
            XCTFail("No card cells found")
            return
        }
        firstCell.tap()

        // Should navigate to detail view with edit button
        let editButton = app.buttons["editToggleButton"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 3), "Card detail should have edit button")
    }

    func testSwipeToDeleteCard() {
        LaunchHelper.tapTab("卡片库", in: app)

        let firstCell = app.cells.firstMatch
        guard firstCell.waitForExistence(timeout: 3) else {
            XCTFail("No card cells found")
            return
        }

        let initialCount = app.cells.count
        firstCell.swipeLeft()

        let deleteButton = app.buttons["Delete"]
        if deleteButton.waitForExistence(timeout: 2) {
            deleteButton.tap()
            // After delete, count should decrease
            XCTAssertLessThan(app.cells.count, initialCount)
        }
    }
}
