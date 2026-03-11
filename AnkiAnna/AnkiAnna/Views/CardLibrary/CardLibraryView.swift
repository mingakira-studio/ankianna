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
        HStack(spacing: 12) {
            Text(card.answer)
                .font(.system(size: 36, weight: .medium))
                .frame(width: 50)

            VStack(alignment: .leading, spacing: 4) {
                masteryBadge(stats?.masteryLevel ?? .new)

                if let stats, stats.practiceCount > 0 {
                    HStack(spacing: 12) {
                        Label("\(Int(Double(stats.correctCount) / Double(stats.practiceCount) * 100))%", systemImage: "chart.bar.fill")
                            .foregroundStyle(accuracyColor(correct: stats.correctCount, total: stats.practiceCount))
                        Label("\(stats.practiceCount)次", systemImage: "pencil.line")
                            .foregroundStyle(.secondary)
                        if let last = stats.lastPracticed {
                            Label(relativeDate(last), systemImage: "clock")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .font(.subheadline)
                } else {
                    Text("未学习")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            Button {
                cardToDelete = card
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(.red.opacity(0.6))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }

    private func accuracyColor(correct: Int, total: Int) -> Color {
        let rate = Double(correct) / Double(total)
        if rate >= 0.8 { return .green }
        if rate >= 0.5 { return .orange }
        return .red
    }

    private func relativeDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "今天" }
        if calendar.isDateInYesterday(date) { return "昨天" }
        let days = calendar.dateComponents([.day], from: date, to: Date()).day ?? 0
        return "\(days)天前"
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
