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
                for: Card.self, ReviewRecord.self, DailySession.self, UserProfile.self, CharacterStats.self,
                configurations: config
            )
        } else {
            modelContainer = try! ModelContainer(
                for: Card.self, ReviewRecord.self, DailySession.self, UserProfile.self, CharacterStats.self
            )
        }
        #else
        modelContainer = try! ModelContainer(
            for: Card.self, ReviewRecord.self, DailySession.self, UserProfile.self, CharacterStats.self
        )
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    initializeUserProfile()
                }
        }
        .modelContainer(modelContainer)
    }

    private func initializeUserProfile() {
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<UserProfile>()
        if let existing = try? context.fetch(descriptor), existing.isEmpty {
            let profile = UserProfile(name: "Anna", dailyGoal: 15)
            context.insert(profile)
        }
    }
}
