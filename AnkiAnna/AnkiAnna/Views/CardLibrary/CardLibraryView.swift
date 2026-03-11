import SwiftUI
import SwiftData

struct CardLibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Card.createdAt, order: .reverse) private var cards: [Card]
    @Query private var allCharacterStats: [CharacterStats]
    @State private var cardToDelete: Card?

    private func statsFor(_ card: Card) -> CharacterStats? {
        allCharacterStats.first(where: { $0.character == card.answer })
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(cards) { card in
                    NavigationLink {
                        CardDetailView(card: card)
                    } label: {
                        cardRow(card)
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
            .alert("确认删除", isPresented: Binding(
                get: { cardToDelete != nil },
                set: { if !$0 { cardToDelete = nil } }
            )) {
                Button("删除", role: .destructive) {
                    if let card = cardToDelete {
                        modelContext.delete(card)
                        cardToDelete = nil
                    }
                }
                Button("取消", role: .cancel) {
                    cardToDelete = nil
                }
            } message: {
                if let card = cardToDelete {
                    Text("确定要删除「\(card.answer)」吗？")
                }
            }
        }
    }

    @ViewBuilder
    private func cardRow(_ card: Card) -> some View {
        let stats = statsFor(card)
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(card.answer)
                    .font(.title2)
                masteryBadge(stats?.masteryLevel ?? .new)
                Spacer()
                if let stats, stats.practiceCount > 0 {
                    let rate = Int(Double(stats.correctCount) / Double(stats.practiceCount) * 100)
                    Text("正确率 \(rate)%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(stats.correctCount)✓")
                        .font(.caption)
                        .foregroundStyle(.green)
                    Text("\(stats.errorCount)✗")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                Button {
                    cardToDelete = card
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                        .font(.caption)
                }
                .buttonStyle(.plain)
            }
            HStack(spacing: 8) {
                Text(card.type == .chineseWriting ? "中文" : "英文")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(card.contexts.count) 个语境")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }

    private func masteryBadge(_ level: MasteryLevel) -> some View {
        let (text, color): (String, Color) = switch level {
        case .mastered: ("已掌握", .green)
        case .learning: ("学习中", .blue)
        case .difficult: ("疑难字", .orange)
        case .new: ("新字", .gray)
        }
        return Text(text)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}
