import XCTest

enum LaunchHelper {
    static func launchApp(
        seedData: Bool = true,
        singleCard: Bool = false,
        englishOnly: Bool = false
    ) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments.append("-UITestMode")
        if englishOnly {
            app.launchArguments.append("-SeedEnglishCards")
        } else if singleCard {
            app.launchArguments.append("-SeedSingleCard")
        } else if seedData {
            app.launchArguments.append("-SeedTestData")
        }
        app.launch()
        return app
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
