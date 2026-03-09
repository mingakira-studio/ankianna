import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        TabView {
            LearningView()
                .tabItem {
                    Label("学习", systemImage: "pencil.line")
                }
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
        #if DEBUG
        .onAppear {
            if CommandLine.arguments.contains("-SeedEnglishCards") {
                UITestSeeder.seedEnglishCards(context: modelContext)
            } else if CommandLine.arguments.contains("-SeedTestData") {
                UITestSeeder.seedTestData(context: modelContext)
            } else if CommandLine.arguments.contains("-SeedSingleCard") {
                UITestSeeder.seedSingleCard(context: modelContext)
            }
        }
        #endif
    }
}
