import SwiftUI
import SwiftData

struct CardDetailView: View {
    @Bindable var card: Card
    @Environment(\.modelContext) private var modelContext
    @State private var isEditing = false

    var body: some View {
        List {
            Section("基本信息") {
                if isEditing {
                    LabeledContent("目标字词") {
                        TextField("目标字词", text: $card.answer)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("音频文本") {
                        TextField("音频文本", text: $card.audioText)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("类型", value: card.type == .chineseWriting ? "中文写字" : "英文拼写")
                    LabeledContent("来源", value: card.source == .manual ? "手动" : "AI 生成")
                } else {
                    LabeledContent("目标字词", value: card.answer)
                    LabeledContent("类型", value: card.type == .chineseWriting ? "中文写字" : "英文拼写")
                    LabeledContent("来源", value: card.source == .manual ? "手动" : "AI 生成")
                }
            }

            Section("语境 (\(card.contexts.count))") {
                ForEach(card.contexts) { ctx in
                    if isEditing {
                        editableContextRow(ctx)
                    } else {
                        readOnlyContextRow(ctx)
                    }
                }

                if isEditing {
                    Button {
                        let newContext = CardContext(type: .phrase, text: "", fullText: "")
                        card.contexts.append(newContext)
                    } label: {
                        Label("添加语境", systemImage: "plus.circle")
                    }
                }
            }

            if !card.tags.isEmpty {
                Section("标签") {
                    FlowLayout(spacing: 8) {
                        ForEach(card.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(.gray.opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .navigationTitle(card.answer)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(isEditing ? "完成" : "编辑") {
                    isEditing.toggle()
                }
                .accessibilityIdentifier("editToggleButton")
            }
        }
    }

    @ViewBuilder
    private func readOnlyContextRow(_ ctx: CardContext) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(ctx.text).font(.headline)
            Text(ctx.fullText).font(.subheadline).foregroundStyle(.secondary)
            Text(ctx.type == .phrase ? "组词" : "造句")
                .font(.caption2)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(.blue.opacity(0.1))
                .clipShape(Capsule())
        }
    }

    @ViewBuilder
    private func editableContextRow(_ ctx: CardContext) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("填空文本", text: Binding(
                get: { ctx.text },
                set: { ctx.text = $0 }
            ))
            .font(.headline)

            TextField("完整文本", text: Binding(
                get: { ctx.fullText },
                set: { ctx.fullText = $0 }
            ))
            .font(.subheadline)
            .foregroundStyle(.secondary)

            HStack {
                Picker("类型", selection: Binding(
                    get: { ctx.type },
                    set: { ctx.type = $0 }
                )) {
                    Text("组词").tag(ContextType.phrase)
                    Text("造句").tag(ContextType.sentence)
                }
                .pickerStyle(.segmented)
                .frame(width: 140)

                Spacer()

                Button(role: .destructive) {
                    if let index = card.contexts.firstIndex(where: { $0.id == ctx.id }) {
                        let removed = card.contexts.remove(at: index)
                        modelContext.delete(removed)
                    }
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                }
                .disabled(!card.canDeleteContext)
            }
        }
        .padding(.vertical, 4)
    }
}

// Simple flow layout for tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}
