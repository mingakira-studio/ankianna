import SwiftUI
import SwiftData
import PencilKit

struct LearningView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var cards: [Card]
    @Query private var profiles: [UserProfile]
    @Query private var allCharacterStats: [CharacterStats]
    @State private var viewModel = LearningViewModel()
    @State private var drawing = PKDrawing()
    @State private var typedAnswer: String = ""

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.sessionComplete {
                    sessionCompleteView
                } else if let card = viewModel.currentCard {
                    learningContentView(card: card)
                } else {
                    emptyStateView
                }
            }
            .navigationTitle("学习")
            .onAppear {
                let dailyGoal = profile?.dailyGoal ?? 15
                if allCharacterStats.isEmpty {
                    viewModel.loadDueCards(from: cards, dailyGoal: dailyGoal)
                } else {
                    viewModel.loadDueCards(allCards: cards, characterStats: allCharacterStats, dailyGoal: dailyGoal)
                }
                HandwritingRecognizer.downloadModel(language: "zh-CN") { _ in }
            }
        }
    }

    private var mascotState: MascotState {
        if viewModel.showResult {
            return viewModel.isCorrect ? .happy : .encourage
        } else if viewModel.combo >= 3 {
            return .celebrate
        } else {
            return .idle
        }
    }

    private func speakCurrentContext(card: Card) {
        if let ctx = viewModel.currentContext {
            TTSService.speak(text: ctx.fullText, cardType: card.type)
        }
    }

    private func learningContentView(card: Card) -> some View {
        HStack(spacing: 0) {
            // Left: prompt + controls
            VStack {
                MascotView(state: mascotState)
                    .padding(.top, 8)

                Spacer()
                CardPromptView(
                    context: viewModel.currentContext,
                    cardType: card.type,
                    onSpeak: {
                        if let ctx = viewModel.currentContext {
                            TTSService.speak(text: ctx.fullText, cardType: card.type)
                        }
                    }
                )
                Spacer()

                // Combo counter
                if viewModel.combo >= 2 {
                    Text("🔥 x\(viewModel.combo)")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.orange)
                        .accessibilityIdentifier("comboCounter")
                        .transition(.scale.combined(with: .opacity))
                }

                // Progress
                Text("\(viewModel.completedCount)/\(viewModel.totalCount)")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .padding(.bottom)
                    .accessibilityIdentifier("progressText")
            }
            .frame(maxWidth: .infinity)

            // Right: writing area or result
            VStack {
                if viewModel.showResult {
                    ResultFeedbackView(
                        isCorrect: viewModel.isCorrect,
                        correctAnswer: card.answer,
                        charResults: card.type == .englishSpelling ? viewModel.charResults : nil,
                        combo: viewModel.combo,
                        pointsEarned: PointsService.pointsForAnswer(correct: viewModel.isCorrect, combo: viewModel.combo),
                        onNext: {
                            drawing = PKDrawing()
                            typedAnswer = ""
                            viewModel.next()
                        },
                        onRetry: {
                            drawing = PKDrawing()
                            typedAnswer = ""
                            viewModel.retry()
                        }
                    )
                } else if card.type == .englishSpelling {
                    // Keyboard input for English spelling
                    TextField("输入拼写...", text: $typedAnswer)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 32))
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .padding()
                        .accessibilityIdentifier("spellingTextField")

                    Button("提交") {
                        viewModel.submitTypedAnswer(typed: typedAnswer, modelContext: modelContext, profile: profile)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding(.bottom)
                    .accessibilityIdentifier("submitButton")
                } else {
                    // Handwriting input for Chinese cards
                    WritingCanvasView(drawing: $drawing)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.white)
                                .shadow(radius: 2)
                        )
                        .padding()

                    Button("提交") {
                        submitDrawing(card: card)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding(.bottom)

                    #if DEBUG
                    HStack(spacing: 16) {
                        Button("模拟写对") {
                            viewModel.submitAnswer(recognized: card.answer, modelContext: modelContext, profile: profile)
                        }
                        .buttonStyle(.bordered)
                        .tint(.green)
                        .accessibilityIdentifier("simulateCorrectButton")

                        Button("模拟写错") {
                            viewModel.submitAnswer(recognized: "", modelContext: modelContext, profile: profile)
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                        .accessibilityIdentifier("simulateWrongButton")
                    }
                    .padding(.bottom, 8)
                    #endif
                }
            }
            .frame(maxWidth: .infinity)
        }
        .onAppear {
            speakCurrentContext(card: card)
        }
        .onChange(of: viewModel.showResult) {
            // Auto-speak when moving to next card (showResult goes false)
            if !viewModel.showResult, let newCard = viewModel.currentCard {
                speakCurrentContext(card: newCard)
            }
        }
    }

    private var sessionCompleteView: some View {
        VStack(spacing: 20) {
            MascotView(state: .celebrate)

            Image(systemName: "star.fill")
                .font(.system(size: 80))
                .foregroundStyle(.yellow)
            Text("今天的学习完成了！")
                .font(.system(size: 28, weight: .bold))
            Text("正确 \(viewModel.correctCount)/\(viewModel.totalCount)")
                .font(.title2)
        }
        .accessibilityIdentifier("sessionCompleteView")
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "rectangle.stack.badge.plus")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text("还没有卡片")
                .font(.title2)
            Text("去「添加」页面创建一些卡片吧")
                .foregroundStyle(.secondary)
        }
        .accessibilityIdentifier("emptyStateView")
    }

    private func submitDrawing(card: Card) {
        let lang = TTSService.languageCode(for: card.type)
        HandwritingRecognizer.recognize(drawing: drawing, language: lang) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let candidates):
                    let matched = HandwritingRecognizer.bestMatch(candidates: candidates, expected: card.answer)
                    if matched {
                        viewModel.submitAnswer(recognized: card.answer, modelContext: modelContext, profile: profile)
                    } else {
                        viewModel.submitAnswer(recognized: candidates.first ?? "", modelContext: modelContext, profile: profile)
                    }
                case .failure:
                    viewModel.submitAnswer(recognized: "", modelContext: modelContext, profile: profile)
                }
            }
        }
    }
}
