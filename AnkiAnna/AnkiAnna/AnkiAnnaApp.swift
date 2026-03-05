import SwiftUI
import SwiftData

@main
struct AnkiAnnaApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Card.self, ReviewRecord.self, DailySession.self, UserProfile.self])
    }
}
