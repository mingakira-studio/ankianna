import XCTest

final class TextbookBrowserTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Navigation

    func testNavigateToTextbookBrowser() throws {
        let app = LaunchHelper.launchApp(seed: .none)
        LaunchHelper.tapTab("添加", in: app)

        let browserLink = app.staticTexts["课本字库"]
        XCTAssertTrue(browserLink.waitForExistence(timeout: 3), "课本字库 entry should exist in 添加 tab")
        browserLink.tap()

        // Should show grade sections
        XCTAssertTrue(app.navigationBars["课本字库"].waitForExistence(timeout: 3),
                      "Should navigate to 课本字库")
    }

    func testBrowseGradeToLessons() throws {
        let app = LaunchHelper.launchApp(seed: .none)
        LaunchHelper.tapTab("添加", in: app)
        app.staticTexts["课本字库"].tap()

        // Tap first semester entry (二年级上册 should exist)
        let semester = app.staticTexts["二年级上册"]
        XCTAssertTrue(semester.waitForExistence(timeout: 3), "二年级上册 should exist")
        semester.tap()

        // Should show lesson list
        XCTAssertTrue(app.navigationBars["二年级上册"].waitForExistence(timeout: 3),
                      "Should navigate to lesson list")
    }

    func testBrowseLessonToCharacters() throws {
        let app = LaunchHelper.launchApp(seed: .none)
        LaunchHelper.tapTab("添加", in: app)
        app.staticTexts["课本字库"].tap()

        // Navigate to 二年级上册
        app.staticTexts["二年级上册"].tap()
        _ = app.navigationBars["二年级上册"].waitForExistence(timeout: 3)

        // Tap first lesson
        let firstLesson = app.cells.firstMatch
        XCTAssertTrue(firstLesson.waitForExistence(timeout: 3))
        firstLesson.tap()

        // Should show character list with add-all button
        let addAll = app.buttons["addAllButton"]
        XCTAssertTrue(addAll.waitForExistence(timeout: 3),
                      "Should show 全部加入 button")
    }

    // MARK: - Add to Library

    func testAddSingleCharacter() throws {
        let app = LaunchHelper.launchApp(seed: .none)
        LaunchHelper.tapTab("添加", in: app)
        app.staticTexts["课本字库"].tap()
        app.staticTexts["二年级上册"].tap()
        _ = app.navigationBars["二年级上册"].waitForExistence(timeout: 3)

        // Tap first lesson
        app.cells.firstMatch.tap()

        // Find and tap add button for a character
        let addButton = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'add-'")).firstMatch
        XCTAssertTrue(addButton.waitForExistence(timeout: 3), "Should have add button for character")
        addButton.tap()

        // After adding, should show checkmark
        let checkmark = app.images.matching(NSPredicate(format: "identifier BEGINSWITH 'added-'")).firstMatch
        XCTAssertTrue(checkmark.waitForExistence(timeout: 3),
                      "Should show checkmark after adding")
    }

    func testAddedCharacterAppearsInCardLibrary() throws {
        let app = LaunchHelper.launchApp(seed: .none)
        LaunchHelper.tapTab("添加", in: app)
        app.staticTexts["课本字库"].tap()
        app.staticTexts["二年级上册"].tap()
        _ = app.navigationBars["二年级上册"].waitForExistence(timeout: 3)

        app.cells.firstMatch.tap()

        // Add a character
        let addButton = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'add-'")).firstMatch
        XCTAssertTrue(addButton.waitForExistence(timeout: 3))
        addButton.tap()

        // Go back to card library and verify card exists
        LaunchHelper.tapTab("卡片库", in: app)
        let cardCell = app.cells.firstMatch
        XCTAssertTrue(cardCell.waitForExistence(timeout: 3),
                      "Added character should appear in card library")
    }
}
