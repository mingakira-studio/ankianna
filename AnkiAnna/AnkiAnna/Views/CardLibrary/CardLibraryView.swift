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
        HStack(spacing: DesignTokens.Spacing.lg) {
            // Character — visual anchor
            Text(card.answer)
                .font(DesignTokens.Font.rounded(size: DesignTokens.CharSize.library, weight: .semibold))
                .frame(width: 56, alignment: .center)

            // Mastery badge
            masteryBadge(stats?.masteryLevel ?? .new)

            if let stats, stats.practiceCount > 0 {
                // Accuracy — color-coded
                Text("\(Int(Double(stats.correctCount) / Double(stats.practiceCount) * 100))%")
                    .font(DesignTokens.Font.headline)
                    .foregroundStyle(accuracyColor(correct: stats.correctCount, total: stats.practiceCount))

                Text("\(stats.practiceCount)次")
                    .font(DesignTokens.Font.subheadline)
                    .foregroundStyle(DesignTokens.Colors.onSurfaceSecondary)

                if let last = stats.lastPracticed {
                    Text(relativeDate(last))
                        .font(DesignTokens.Font.subheadline)
                        .foregroundStyle(DesignTokens.Colors.onSurfaceSecondary)
                }
            } else {
                Text("未学习")
                    .font(DesignTokens.Font.subheadline)
                    .foregroundStyle(.quaternary)
            }

            Spacer()

            Button {
                cardToDelete = card
            } label: {
                Image(systemName: "trash")
                    .font(DesignTokens.Font.subheadline)
                    .foregroundStyle(DesignTokens.Colors.error.opacity(0.4))
                    .frame(minWidth: 44, minHeight: 44)
            }
            .accessibilityLabel("删除卡片")
            .buttonStyle(.plain)
        }
        .padding(.vertical, DesignTokens.Spacing.sm)
    }

    private func accuracyColor(correct: Int, total: Int) -> Color {
        let rate = Double(correct) / Double(total)
        if rate >= 0.8 { return DesignTokens.Colors.success }
        if rate >= 0.5 { return DesignTokens.Colors.warning }
        return DesignTokens.Colors.error
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
        case .mastered: ("已掌握", DesignTokens.Colors.success)
        case .learning: ("学习中", DesignTokens.Colors.primary)
        case .difficult: ("疑难字", DesignTokens.Colors.warning)
        case .new: ("新字", .gray)
        }
        return Text(text)
            .font(DesignTokens.Font.footnote)
            .padding(.horizontal, DesignTokens.Spacing.sm)
            .padding(.vertical, 3)
            .background(color.opacity(0.12))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}
