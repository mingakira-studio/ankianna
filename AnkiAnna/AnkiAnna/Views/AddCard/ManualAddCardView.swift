import SwiftUI
import SwiftData

struct ManualAddCardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var cardType: CardType = .chineseWriting
    @State private var answer = ""
    @State private var contextText = ""
    @State private var contextFullText = ""
    @State private var contextType: ContextType = .phrase
    @State private var contexts: [(type: ContextType, text: String, fullText: String)] = []
    @State private var tags = ""

    var body: some View {
        Form {
            Section("卡片类型") {
                Picker("类型", selection: $cardType) {
                    Text("中文写字").tag(CardType.chineseWriting)
                    Text("英文拼写").tag(CardType.englishSpelling)
                }
                .pickerStyle(.segmented)
            }

            Section("目标字词") {
                TextField("如：龙、dragon", text: $answer)
                    .font(.title2)
            }

            Section("添加语境") {
                Picker("语境类型", selection: $contextType) {
                    Text("组词").tag(ContextType.phrase)
                    Text("造句").tag(ContextType.sentence)
                }
                .pickerStyle(.segmented)

                TextField("含空位的文本（如 ___飞凤舞）", text: $contextText)
                TextField("完整文本（如 龙飞凤舞）", text: $contextFullText)

                Button("添加语境") {
                    guard !contextText.isEmpty, !contextFullText.isEmpty else { return }
                    contexts.append((type: contextType, text: contextText, fullText: contextFullText))
                    contextText = ""
                    contextFullText = ""
                }
                .disabled(contextText.isEmpty || contextFullText.isEmpty)
            }

            if !contexts.isEmpty {
                Section("已添加的语境 (\(contexts.count))") {
                    ForEach(contexts.indices, id: \.self) { index in
                        VStack(alignment: .leading) {
                            Text(contexts[index].text).font(.headline)
                            Text(contexts[index].fullText).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .onDelete { contexts.remove(atOffsets: $0) }
                }
            }

            Section("标签") {
                TextField("逗号分隔（如：二年级,动物）", text: $tags)
            }

            Section {
                Button("保存卡片") {
                    saveCard()
                }
                .disabled(answer.isEmpty || contexts.isEmpty)
            }
        }
        .navigationTitle("手动添加")
    }

    private func saveCard() {
        let card = Card(
            type: cardType,
            answer: answer,
            audioText: answer,
            tags: tags.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
        )
        for ctx in contexts {
            let context = CardContext(type: ctx.type, text: ctx.text, fullText: ctx.fullText)
            card.contexts.append(context)
        }
        modelContext.insert(card)
        dismiss()
    }
}
