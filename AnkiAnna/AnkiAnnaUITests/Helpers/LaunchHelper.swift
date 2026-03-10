import XCTest

enum SeedMode {
    case testData       // 3 English + 1 Chinese card
    case englishOnly    // 3 English cards
    case singleCard     // 1 English card (quick session complete)
    case withStats      // 3 Chinese + 1 English + CharacterStats (SM-2 path)
    case textbook       // Real TextbookSeeder — actual first-launch path
    case none           // No data (empty state)
}

enum LaunchHelper {
    static func launchApp(seed: SeedMode = .testData) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments.append("-UITestMode")
        switch seed {
        case .testData:     app.launchArguments.append("-SeedTestData")
        case .englishOnly:  app.launchArguments.append("-SeedEnglishCards")
        case .singleCard:   app.launchArguments.append("-SeedSingleCard")
        case .withStats:    app.launchArguments.append("-SeedWithStats")
        case .textbook:     app.launchArguments.append("-SeedTextbook")
        case .none:         break
        }
        app.launch()
        return app
    }

    /// Backward-compatible overload
    static func launchApp(
        seedData: Bool = true,
        singleCard: Bool = false,
        englishOnly: Bool = false
    ) -> XCUIApplication {
        if englishOnly { return launchApp(seed: .englishOnly) }
        if singleCard { return launchApp(seed: .singleCard) }
        if seedData { return launchApp(seed: .testData) }
        return launchApp(seed: .none)
    }

    /// Tap a tab item by label. On iPad, TabView may render as toolbar buttons
    /// instead of a traditional UITabBar, potentially with multiple matches.
    static func tapTab(_ label: String, in app: XCUIApplication) {
        // Try traditional tab bar first
        let tabBarButton = app.tabBars.buttons[label]
        if tabBarButton.waitForExistence(timeout: 2) {
            tabBarButton.tap()
            return
        }
        // iPad: tab items appear as regular buttons (use firstMatch for duplicates)
        let button = app.buttons[label].firstMatch
        if button.waitForExistence(timeout: 2) {
            button.tap()
            return
        }
        XCTFail("Could not find tab '\(label)'")
    }

    /// Check if a tab item exists
    static func tabExists(_ label: String, in app: XCUIApplication) -> Bool {
        app.tabBars.buttons[label].exists || app.buttons[label].firstMatch.exists
    }
}
