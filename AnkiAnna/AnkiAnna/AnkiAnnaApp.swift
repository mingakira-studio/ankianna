import SwiftUI
import SwiftData

@main
struct AnkiAnnaApp: App {
    let modelContainer: ModelContainer

    init() {
        #if DEBUG
        if CommandLine.arguments.contains("-UITestMode") {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            modelContainer = try! ModelContainer(
                for: Card.self, ReviewRecord.self, DailySession.self, UserProfile.self,
                configurations: config
            )
        } else {
            modelContainer = try! ModelContainer(
                for: Card.self, ReviewRecord.self, DailySession.self, UserProfile.self
            )
        }
        #else
        modelContainer = try! ModelContainer(
            for: Card.self, ReviewRecord.self, DailySession.self, UserProfile.self
        )
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
