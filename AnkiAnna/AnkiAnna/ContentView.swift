import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("hasSeededTextbook") private var hasSeeded = false
    @Query private var allCharacterStats: [CharacterStats]

    private var dueCount: Int {
        let now = Date()
        return allCharacterStats.filter { stats in
            guard let nextReview = stats.nextReviewDate else { return false }
            return nextReview <= now
        }.count
    }

    var body: some View {
        TabView {
            GameModeSelectionView()
                .tabItem {
                    Label("学习", systemImage: "pencil.line")
                }
                .badge(dueCount > 0 ? dueCount : 0)
            CardLibraryView()
                .tabItem {
                    Label("卡片库", systemImage: "rectangle.stack")
                }
            AddCardView()
                .tabItem {
                    Label("添加", systemImage: "plus.circle")
                }
            StatsView()
                .tabItem {
                    Label("统计", systemImage: "chart.bar")
                }
        }
        .onAppear {
            #if DEBUG
            if CommandLine.arguments.contains("-UITestMode") {
                if CommandLine.arguments.contains("-SeedEnglishCards") {
                    UITestSeeder.seedEnglishCards(context: modelContext)
                } else if CommandLine.arguments.contains("-SeedTestData") {
                    UITestSeeder.seedTestData(context: modelContext)
                } else if CommandLine.arguments.contains("-SeedSingleCard") {
                    UITestSeeder.seedSingleCard(context: modelContext)
                } else if CommandLine.arguments.contains("-SeedWithStats") {
                    UITestSeeder.seedWithCharacterStats(context: modelContext)
                } else if CommandLine.arguments.contains("-SeedTextbook") {
                    // Real TextbookSeeder path — tests actual first-launch seeding
                    TextbookSeeder.seedAllTextbooks(modelContext: modelContext)
                }
                return
            }
            #endif
            // Seed default lesson (grade 2 upper lesson 1) on first launch
            if !hasSeeded {
                TextbookSeeder.seedDefaultLesson(modelContext: modelContext)
                hasSeeded = true
            }
        }
    }
}
