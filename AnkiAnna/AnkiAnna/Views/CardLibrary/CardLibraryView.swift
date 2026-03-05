import SwiftUI
import SwiftData

struct CardLibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Card.createdAt, order: .reverse) private var cards: [Card]

    var body: some View {
        NavigationStack {
            List {
                ForEach(cards) { card in
                    NavigationLink {
                        CardDetailView(card: card)
                    } label: {
                        HStack {
                            Text(card.answer)
                                .font(.title2)
                            Spacer()
                            Text(card.type == .chineseWriting ? "中文" : "英文")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(card.contexts.count) 个语境")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        modelContext.delete(cards[index])
                    }
                }
            }
            .navigationTitle("卡片库 (\(cards.count))")
            .overlay {
                if cards.isEmpty {
                    ContentUnavailableView("没有卡片", systemImage: "rectangle.stack", description: Text("去添加一些卡片吧"))
                }
            }
        }
    }
}
