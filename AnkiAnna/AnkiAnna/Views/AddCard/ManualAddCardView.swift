import SwiftUI
import SwiftData

struct ManualAddCardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    enum InputMode: String, CaseIterable {
        case manual = "手动输入"
        case textbook = "课本选课"
    }

    @State private var inputMode: InputMode = .manual
    @State private var cardType: CardType = .chineseWriting
    @State private var wordsInput = ""
    @State private var tags = ""
    @State private var isGenerating = false
    @State private var generatedCards: [AIGenerator.GeneratedCard] = []
    @State private var selectedIndices: Set<Int> = []
    @State private var errorMessage: String?

    // Textbook mode state
    @State private var selectedGrade: TextbookDataProvider.Grade = .grade2
    @State private var selectedSemester: TextbookDataProvider.Semester = .upper
    @State private var selectedLessonIndex: Int = 0
    @State private var lessons: [TextbookDataProvider.TextbookLesson] = []

    var body: some View {
        Form {
            Section("输入方式") {
                Picker("模式", selection: $inputMode) {
                    ForEach(InputMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }

            if inputMode == .manual {
                manualInputSections
            } else {
                textbookInputSections
            }

            if let error = errorMessage {
                Section {
                    Text(error).foregroundStyle(.red)
                }
            }

            if !generatedCards.isEmpty {
                Section("预览 (\(generatedCards.count) 张卡片)") {
                    ForEach(generatedCards.indices, id: \.self) { index in
                        let card = generatedCards[index]
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(card.answer)
                                    .font(.headline)
                                Text(card.contexts.prefix(3).map(\.fullText).joined(separator: "、"))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
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
        .navigationTitle("手动添加")
        .onChange(of: selectedGrade) {
            loadLessons()
        }
        .onChange(of: selectedSemester) {
            loadLessons()
        }
        .onAppear {
            loadLessons()
        }
    }

    // MARK: - Manual Input

    @ViewBuilder
    private var manualInputSections: some View {
        Section("卡片类型") {
            Picker("类型", selection: $cardType) {
                Text("中文写字").tag(CardType.chineseWriting)
                Text("英文拼写").tag(CardType.englishSpelling)
            }
            .pickerStyle(.segmented)
        }

        Section("目标字词") {
            TextField("输入多个字词，用空格或逗号分隔\n如：龙 凤 虎 或 apple, banana", text: $wordsInput, axis: .vertical)
                .lineLimit(2...4)
                .font(DesignTokens.Font.title3)
        }

        Section("标签") {
            TextField("逗号分隔（如：二年级,动物）", text: $tags)
        }

        Section {
            Button {
                Task { await generateContexts() }
            } label: {
                HStack {
                    Image(systemName: "sparkles")
                    Text(isGenerating ? "生成中..." : "AI 生成语境")
                }
            }
            .disabled(parsedWords.isEmpty || isGenerating)
        }
    }

    // MARK: - Textbook Input

    @ViewBuilder
    private var textbookInputSections: some View {
        Section("选择课文") {
            Picker("年级", selection: $selectedGrade) {
                ForEach(TextbookDataProvider.Grade.allCases, id: \.self) { grade in
                    Text(grade.displayName).tag(grade)
                }
            }

            Picker("学期", selection: $selectedSemester) {
                ForEach(TextbookDataProvider.Semester.allCases, id: \.self) { semester in
                    Text(TextbookDataProvider.semesterDisplayName(grade: selectedGrade, semester: semester))
                        .tag(semester)
                }
            }

            if !lessons.isEmpty {
                Picker("课文", selection: $selectedLessonIndex) {
                    ForEach(lessons.indices, id: \.self) { index in
                        Text(lessons[index].displayLabel).tag(index)
                    }
                }
            }
        }

        if let lesson = currentLesson {
            Section("本课生字（\(lesson.characters.count) 个）") {
                Text(lesson.characters.map(\.char).joined(separator: "  "))
                    .font(DesignTokens.Font.title2)
            }

            Section {
                Button {
                    Task { await generateTextbookCards() }
                } label: {
                    HStack {
                        Image(systemName: "sparkles")
                        Text(isGenerating ? "生成中..." : "生成本课卡片")
                    }
                }
                .disabled(isGenerating)
            }
        }
    }

    // MARK: - Helpers

    private var currentLesson: TextbookDataProvider.TextbookLesson? {
        guard !lessons.isEmpty, selectedLessonIndex < lessons.count else { return nil }
        return lessons[selectedLessonIndex]
    }

    private var parsedWords: [String] {
        wordsInput
            .replacingOccurrences(of: "，", with: ",")
            .replacingOccurrences(of: "、", with: ",")
            .split(whereSeparator: { $0 == "," || $0 == " " || $0.isNewline })
            .map { String($0).trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    private func loadLessons() {
        lessons = TextbookDataProvider.loadLessons(grade: selectedGrade, semester: selectedSemester)
        selectedLessonIndex = 0
        // Clear previous results when switching
        generatedCards = []
        selectedIndices = []
        errorMessage = nil
    }

    private func generateContexts() async {
        isGenerating = true
        errorMessage = nil
        do {
            let config = AIGenerator.loadConfig()
            generatedCards = try await AIGenerator.generateContexts(
                words: parsedWords, subject: cardType, config: config
            )
            selectedIndices = Set(generatedCards.indices)
        } catch {
            errorMessage = "生成失败: \(error.localizedDescription)"
        }
        isGenerating = false
    }

    private func generateTextbookCards() async {
        guard let lesson = currentLesson else { return }
        isGenerating = true
        errorMessage = nil
        generatedCards = []
        selectedIndices = []
        do {
            let config = AIGenerator.loadConfig()
            generatedCards = try await AIGenerator.generateTextbookContexts(
                characters: lesson.characters,
                lessonTitle: lesson.title,
                config: config
            )
            selectedIndices = Set(generatedCards.indices)
        } catch {
            errorMessage = "生成失败: \(error.localizedDescription)"
        }
        isGenerating = false
    }

    private func importSelected() {
        let isTextbook = inputMode == .textbook
        let tagList: [String]
        if isTextbook, let lesson = currentLesson {
            tagList = [TextbookDataProvider.semesterDisplayName(grade: selectedGrade, semester: selectedSemester), lesson.displayLabel]
        } else {
            tagList = tags.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
        }
        let source: CardSource = isTextbook ? .textbook : .manual

        for index in selectedIndices {
            let gen = generatedCards[index]
            let card = Card(
                type: .chineseWriting,
                answer: gen.answer,
                audioText: gen.answer,
                tags: tagList,
                source: source
            )
            for ctx in gen.contexts {
                card.contexts.append(CardContext(type: ctx.type, text: ctx.text, fullText: ctx.fullText, source: source))
            }
            modelContext.insert(card)
        }
        dismiss()
    }
}
