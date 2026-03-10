import SwiftUI

struct AddCardView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink {
                    ManualAddCardView()
                } label: {
                    Label("手动添加", systemImage: "square.and.pencil")
                }

                NavigationLink {
                    AIGenerateView()
                } label: {
                    Label("AI 自动生成", systemImage: "sparkles")
                }

                NavigationLink {
                    TextbookBrowserView()
                } label: {
                    Label("课本字库", systemImage: "character.book.closed")
                }
            }
            .navigationTitle("添加卡片")
        }
    }
}
