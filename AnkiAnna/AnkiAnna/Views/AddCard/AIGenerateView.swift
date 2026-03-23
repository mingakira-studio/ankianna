import SwiftUI
import SwiftData

struct AIGenerateView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var cardType: CardType = .chineseWriting
    @State private var grade = "二年级"
    @State private var topic = ""
    @State private var endpoint = ""
    @State private var apiKey = ""
    @State private var model = ""
    @State private var isLoading = false
    @State private var generatedCards: [AIGenerator.GeneratedCard] = []
    @State private var selectedIndices: Set<Int> = []
    @State private var errorMessage: String?
    @State private var showSettings = false

    let grades = ["一年级", "二年级", "三年级", "四年级", "五年级", "六年级"]

    var body: some View {
        Form {
            Section("生成设置") {
                Picker("类型", selection: $cardType) {
                    Text("中文写字").tag(CardType.chineseWriting)
                    Text("英文拼写").tag(CardType.englishSpelling)
                }
                .pickerStyle(.segmented)

                Picker("年级", selection: $grade) {
                    ForEach(grades, id: \.self) { Text($0) }
                }

                TextField("主题/单元（如：动物、第三课）", text: $topic)
            }

            Section {
                DisclosureGroup("API 设置", isExpanded: $showSettings) {
                    TextField("API 地址", text: $endpoint, prompt: Text(AIGenerator.defaultEndpoint))
                    SecureField("API Key", text: $apiKey)
                    TextField("模型", text: $model, prompt: Text(AIGenerator.defaultModel))
                    Button("保存设置") {
                        if !apiKey.isEmpty { AIGenerator.saveAPIKey(apiKey) }
                        if !endpoint.isEmpty { AIGenerator.saveEndpoint(endpoint) }
                        if !model.isEmpty { AIGenerator.saveModel(model) }
                        showSettings = false
                    }
                }
            }

            Section {
                Button(isLoading ? "生成中..." : "生成卡片") {
                    Task { await generate() }
                }
                .disabled(topic.isEmpty || isLoading)
            }

            if let error = errorMessage {
                Section {
                    Text(error).foregroundStyle(.red)
                }
            }

            if !generatedCards.isEmpty {
                Section("预览 (\(generatedCards.count) 张)") {
                    ForEach(generatedCards.indices, id: \.self) { index in
                        let card = generatedCards[index]
                        HStack {
                            VStack(alignment: .leading) {
                                Text(card.answer).font(.headline)
                                Text("\(card.contexts.count) 个语境").font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: selectedIndices.contains(index) ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(selectedIndices.contains(index) ? .blue : .gray)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedIndices.contains(index) {
                                selectedIndices.remove(index)
                            } else {
                                selectedIndices.insert(index)
                            }
                        }
                    }
                }

                Section {
                    Button("导入选中的 \(selectedIndices.count) 张卡片") {
                        importSelected()
                    }
                    .disabled(selectedIndices.isEmpty)
                }
            }
        }
        .navigationTitle("AI 生成")
        .onAppear {
            apiKey = AIGenerator.loadAPIKey() ?? ""
            endpoint = AIGenerator.loadEndpoint() ?? ""
            model = AIGenerator.loadModel() ?? ""
        }
    }

    private func generate() async {
        isLoading = true
        errorMessage = nil
        do {
            let key = apiKey.isEmpty ? (AIGenerator.loadAPIKey() ?? "") : apiKey
            guard !key.isEmpty else { throw AIGenerator.GeneratorError.noAPIKey }
            let ep = endpoint.isEmpty ? (AIGenerator.loadEndpoint() ?? AIGenerator.defaultEndpoint) : endpoint
            let md = model.isEmpty ? (AIGenerator.loadModel() ?? AIGenerator.defaultModel) : model
            let config = AIGenerator.APIConfig(endpoint: ep, apiKey: key, model: md)
            generatedCards = try await AIGenerator.generateCards(
                subject: cardType, grade: grade, topic: topic, config: config
            )
            selectedIndices = Set(generatedCards.indices)
        } catch {
            errorMessage = "生成失败: \(error.localizedDescription)"
        }
        isLoading = false
    }

    private func importSelected() {
        for index in selectedIndices {
            let gen = generatedCards[index]
            let card = Card(
                type: cardType,
                answer: gen.answer,
                audioText: gen.answer,
                source: .aiGenerated
            )
            for ctx in gen.contexts {
                // Sanitize: ensure only the target character is masked, not the whole word
                let sanitizedText = Self.sanitizeMasking(text: ctx.text, fullText: ctx.fullText, answer: gen.answer)
                card.contexts.append(CardContext(type: ctx.type, text: sanitizedText, fullText: ctx.fullText, source: .aiGenerated))
            }
            modelContext.insert(card)
        }
        dismiss()
    }

    /// Re-derive masked text from fullText by replacing only the first occurrence of the answer character.
    /// AI sometimes masks entire words (e.g., "芬芳" → "___") instead of just the target char ("芬" → "___芳").
    static func sanitizeMasking(text: String, fullText: String, answer: String) -> String {
        // If fullText is empty or answer is empty, return as-is
        guard !fullText.isEmpty, !answer.isEmpty else { return text }
        // Re-derive: replace first occurrence of answer in fullText with ___
        if let range = fullText.range(of: answer) {
            return fullText.replacingCharacters(in: range, with: "___")
        }
        return text
    }
}
