import SwiftUI

struct ContentView: View {
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
    }
}
