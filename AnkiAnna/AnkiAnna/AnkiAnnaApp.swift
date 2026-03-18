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
                for: Card.self, ReviewRecord.self, DailySession.self, UserProfile.self, CharacterStats.self, LevelProgress.self,
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
                    migrateContextMasking()
                }
        }
        .modelContainer(modelContainer)
    }

    /// Fix AI-generated contexts where entire words were masked instead of just the target character.
    /// Runs once per app version via AppStorage flag.
    private func migrateContextMasking() {
        let defaults = UserDefaults.standard
        let key = "hasFixedContextMasking_v1"
        guard !defaults.bool(forKey: key) else { return }

        let context = modelContainer.mainContext
        guard let cards = try? context.fetch(FetchDescriptor<Card>()) else { return }

        var fixedCount = 0
        for card in cards {
            for ctx in card.contexts {
                guard !ctx.fullText.isEmpty, !card.answer.isEmpty else { continue }
                let correct = ctx.displayText(answer: card.answer)
                if correct != ctx.text {
                    ctx.text = correct
                    fixedCount += 1
                }
            }
        }

        if fixedCount > 0 {
            try? context.save()
            print("[Migration] Fixed \(fixedCount) context masking(s)")
        }
        defaults.set(true, forKey: key)
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
