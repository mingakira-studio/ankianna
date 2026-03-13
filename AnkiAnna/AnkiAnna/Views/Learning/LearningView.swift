import SwiftUI
import SwiftData
import PencilKit

struct LearningView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @Query private var cards: [Card]
    @Query private var profiles: [UserProfile]
    @Query private var allCharacterStats: [CharacterStats]
    @State private var viewModel = LearningViewModel()
    @State private var drawing = PKDrawing()
    @State private var typedAnswer: String = ""
    @State private var modelReady: Bool = false

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            ZStack {
                Group {
                    if viewModel.sessionComplete {
                        sessionCompleteView
                    } else if viewModel.showDifficultyFeedback {
                        difficultyFeedbackView
                    } else if viewModel.showCardExitFeedback {
                        cardExitFeedbackView
                    } else if viewModel.isInPracticeMode {
                        practiceView
                    } else if let card = viewModel.currentCard {
                        learningContentView(card: card)
                    } else {
                        emptyStateView
                    }
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
                #if !targetEnvironment(simulator)
                modelReady = HandwritingRecognizer.isModelReady(language: "zh-CN")
                if !modelReady {
                    HandwritingRecognizer.downloadModel(language: "zh-CN") { success in
                        modelReady = success
                    }
                }
                #endif
            }
            .alert("完全掌握了吗？", isPresented: $viewModel.showMasteryConfirmation) {
                Button("掌握了！") { viewModel.confirmMastered() }
                Button("还没有", role: .cancel) { viewModel.declineMastered() }
            } message: {
                Text("这个字连续答对3次，确认已经完全掌握吗？掌握后不再自动复习。")
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
                    Label("x\(viewModel.combo)", systemImage: "flame.fill")
                        .font(DesignTokens.Font.comboText)
                        .foregroundStyle(DesignTokens.Colors.accent)
                        .accessibilityIdentifier("comboCounter")
                        .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))
                }

                // Progress
                Text("\(viewModel.completedCount)/\(viewModel.totalCount)")
                    .font(DesignTokens.Font.headline)
                    .foregroundStyle(DesignTokens.Colors.onSurfaceSecondary)
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
                        .font(DesignTokens.Font.inputField)
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
                            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                                .fill(DesignTokens.Colors.canvas)
                                .shadow(radius: DesignTokens.Shadow.radius)
                        )
                        .padding()

                    #if targetEnvironment(simulator)
                    Text("模拟器不支持手写识别，请用下方模拟按钮")
                        .font(DesignTokens.Font.caption)
                        .foregroundStyle(DesignTokens.Colors.onSurfaceSecondary)
                    #else
                    if !modelReady {
                        Text("正在下载识别模型...")
                            .font(DesignTokens.Font.caption)
                            .foregroundStyle(DesignTokens.Colors.warning)
                    }

                    Button("提交") {
                        submitDrawing(card: card)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(!modelReady)
                    .padding(.bottom)
                    #endif

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
        .onChange(of: viewModel.currentContext?.id) {
            // Auto-speak when context changes (covers card reinsertion from queue)
            if !viewModel.showResult, let newCard = viewModel.currentCard {
                speakCurrentContext(card: newCard)
            }
        }
    }

    // MARK: - Practice mode view

    private var practiceView: some View {
        HStack(spacing: 0) {
            // Left: instructions
            VStack(spacing: DesignTokens.Spacing.lg) {
                MascotView(state: .encourage)
                    .padding(.top, 8)

                Spacer()

                if viewModel.practicePhase == 1 {
                    Text("对着写")
                        .font(DesignTokens.Font.sectionTitle)
                    Text(viewModel.practiceCorrectAnswer)
                        .font(DesignTokens.Font.rounded(size: DesignTokens.CharSize.practice, weight: .bold))
                        .foregroundStyle(DesignTokens.Colors.onSurface)
                        .accessibilityIdentifier("practiceCharacter")
                    Text("\(viewModel.practicePhase1Count + 1)/2")
                        .font(DesignTokens.Font.title2)
                        .foregroundStyle(DesignTokens.Colors.onSurfaceSecondary)
                        .accessibilityIdentifier("practiceProgress")
                } else {
                    Text("盲写")
                        .font(DesignTokens.Font.sectionTitle)
                    Text("?")
                        .font(DesignTokens.Font.rounded(size: DesignTokens.CharSize.practice, weight: .bold))
                        .foregroundStyle(DesignTokens.Colors.onSurfaceSecondary)
                        .accessibilityIdentifier("practiceBlind")
                }

                if let result = viewModel.practiceIsCorrect {
                    if result {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: DesignTokens.CharSize.answer))
                            .foregroundStyle(DesignTokens.Colors.success)
                            .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))
                            .accessibilityIdentifier("practiceCorrectIcon")
                    } else {
                        VStack(spacing: DesignTokens.Spacing.xs) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: DesignTokens.CharSize.answer))
                                .foregroundStyle(DesignTokens.Colors.error)
                            Text("再试一次")
                                .font(DesignTokens.Font.headline)
                                .foregroundStyle(DesignTokens.Colors.error)
                        }
                        .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))
                        .accessibilityIdentifier("practiceWrongFeedback")
                    }
                }

                Spacer()

                Text("\(viewModel.completedCount)/\(viewModel.totalCount)")
                    .font(DesignTokens.Font.headline)
                    .foregroundStyle(DesignTokens.Colors.onSurfaceSecondary)
                    .padding(.bottom)
                    .accessibilityIdentifier("progressText")
            }
            .frame(maxWidth: .infinity)

            // Right: writing area
            VStack {
                if viewModel.currentCard?.type == .englishSpelling {
                    TextField("输入拼写...", text: $typedAnswer)
                        .textFieldStyle(.roundedBorder)
                        .font(DesignTokens.Font.inputField)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .padding()
                        .accessibilityIdentifier("practiceTextField")

                    Button("提交") {
                        viewModel.submitPracticeTypedAnswer(typed: typedAnswer)
                        typedAnswer = ""
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding(.bottom)
                    .accessibilityIdentifier("practiceSubmitButton")
                } else {
                    WritingCanvasView(drawing: $drawing)
                        .background(
                            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                                .fill(DesignTokens.Colors.canvas)
                                .shadow(radius: DesignTokens.Shadow.radius)
                        )
                        .padding()
                        .onChange(of: viewModel.practicePhase1Count) {
                            drawing = PKDrawing()
                        }
                        .onChange(of: viewModel.practicePhase) {
                            drawing = PKDrawing()
                        }

                    #if !targetEnvironment(simulator)
                    Button("提交") {
                        submitPracticeDrawing()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(!modelReady)
                    .padding(.bottom)
                    .accessibilityIdentifier("practiceSubmitButton")
                    #endif

                    #if DEBUG
                    HStack(spacing: 16) {
                        Button("模拟写对") {
                            viewModel.submitPracticeAnswer(recognized: viewModel.practiceCorrectAnswer)
                            drawing = PKDrawing()
                        }
                        .buttonStyle(.bordered)
                        .tint(.green)
                        .accessibilityIdentifier("practiceSimulateCorrectButton")

                        Button("模拟写错") {
                            viewModel.submitPracticeAnswer(recognized: "")
                            drawing = PKDrawing()
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                        .accessibilityIdentifier("practiceSimulateWrongButton")
                    }
                    .padding(.bottom, 8)
                    #endif
                }
            }
            .frame(maxWidth: .infinity)
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: viewModel.practiceIsCorrect != nil)
        .onChange(of: viewModel.showPracticeCorrectFlash) {
            if viewModel.showPracticeCorrectFlash {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation(reduceMotion ? .none : .default) {
                        viewModel.showPracticeCorrectFlash = false
                        viewModel.practiceIsCorrect = nil
                    }
                }
            }
        }
    }

    // MARK: - Difficulty feedback view

    private var difficultyFeedbackView: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            MascotView(state: .encourage)

            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: DesignTokens.IconSize.xl))
                .foregroundStyle(DesignTokens.Colors.warning)

            Text("标记为疑难字")
                .font(DesignTokens.Font.sectionTitle)

            if let card = viewModel.currentCard {
                Text(card.answer)
                    .font(DesignTokens.Font.rounded(size: DesignTokens.CharSize.practice, weight: .bold))
                    .foregroundStyle(DesignTokens.Colors.warning)
            }

            Text("下次会优先复习这个字")
                .font(DesignTokens.Font.title3)
                .foregroundStyle(DesignTokens.Colors.onSurfaceSecondary)

            Button("继续") {
                viewModel.dismissDifficultyFeedback()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.top)
            .accessibilityIdentifier("difficultyDismissButton")
        }
        .accessibilityIdentifier("difficultyFeedbackView")
    }

    // MARK: - Card exit feedback view

    private var cardExitFeedbackView: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: DesignTokens.IconSize.xl))
                .foregroundStyle(DesignTokens.Colors.primary)

            Text(viewModel.cardExitMessage)
                .font(DesignTokens.Font.encouragement)
                .multilineTextAlignment(.center)

            Text("\(viewModel.completedCount)/\(viewModel.totalCount)")
                .font(DesignTokens.Font.title2)
                .foregroundStyle(DesignTokens.Colors.onSurfaceSecondary)
        }
        .accessibilityIdentifier("cardExitFeedbackView")
        .onTapGesture {
            viewModel.dismissCardExitFeedback()
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                viewModel.dismissCardExitFeedback()
            }
        }
    }

    private var sessionCompleteView: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            MascotView(state: .celebrate)
                .padding(.top, 8)

            Text("今天的学习完成了！")
                .font(DesignTokens.Font.sectionTitle)

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(viewModel.orderedSummaries, id: \.character) { summary in
                        sessionSummaryRow(summary)
                        Divider()
                    }
                }
                .padding(.horizontal)
            }
            .frame(maxHeight: 300)

            Divider()
                .padding(.horizontal, 32)

            // Summary stats
            HStack(spacing: DesignTokens.Spacing.xl) {
                Label(viewModel.sessionDurationFormatted, systemImage: "clock")
                Label("\(Int(viewModel.sessionAccuracyRate * 100))%", systemImage: "target")
                Label("\(viewModel.sessionTotalPoints)", systemImage: "star.fill")
            }
            .font(DesignTokens.Font.headline)
            .foregroundStyle(DesignTokens.Colors.onSurfaceSecondary)
            .accessibilityIdentifier("sessionSummaryStats")

            ShareLink(item: sessionShareText) {
                Label("分享成绩", systemImage: "square.and.arrow.up")
                    .font(DesignTokens.Font.headline)
            }
            .buttonStyle(.bordered)
            .padding(.bottom)
        }
        .accessibilityIdentifier("sessionCompleteView")
    }

    private var sessionShareText: String {
        let accuracy = Int(viewModel.sessionAccuracyRate * 100)
        let characters = viewModel.orderedSummaries.map(\.character).joined()
        return "Anna 记忆卡片 - 今日学习完成!\n学习了 \(viewModel.orderedSummaries.count) 个字: \(characters)\n正确率: \(accuracy)%\n用时: \(viewModel.sessionDurationFormatted)\n积分: \(viewModel.sessionTotalPoints)"
    }

    private func sessionSummaryRow(_ summary: CharacterSummary) -> some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            Text(summary.character)
                .font(DesignTokens.Font.encouragement)
                .frame(width: 40)

            // Answer sequence
            HStack(spacing: 2) {
                ForEach(Array(summary.answerSequence.enumerated()), id: \.offset) { _, correct in
                    Image(systemName: correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: DesignTokens.IconSize.sm))
                        .foregroundStyle(correct ? DesignTokens.Colors.success : DesignTokens.Colors.error)
                }
            }
            .frame(minWidth: 60, alignment: .leading)

            Spacer()

            // Exit reason badge
            if let reason = summary.exitReason {
                exitReasonBadge(reason)
            }

            // Duration
            Text(viewModel.characterDuration(for: summary))
                .font(DesignTokens.Font.caption)
                .foregroundStyle(DesignTokens.Colors.onSurfaceSecondary)
                .frame(width: 40, alignment: .trailing)
        }
        .padding(.vertical, 8)
    }

    private func exitReasonBadge(_ reason: CharacterExitReason) -> some View {
        let (text, color): (String, Color) = switch reason {
        case .mastered: ("已掌握", DesignTokens.Colors.success)
        case .completed: ("已完成", DesignTokens.Colors.primary)
        case .difficult: ("疑难字", DesignTokens.Colors.warning)
        }
        return Text(text)
            .font(DesignTokens.Font.caption)
            .padding(.horizontal, DesignTokens.Spacing.sm)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    private var emptyStateView: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            Image(systemName: "rectangle.stack.badge.plus")
                .font(.system(size: DesignTokens.IconSize.xl))
                .foregroundStyle(DesignTokens.Colors.onSurfaceSecondary)
            Text("还没有卡片")
                .font(DesignTokens.Font.title2)
            Text("去「添加」页面创建一些卡片吧")
                .font(DesignTokens.Font.body)
                .foregroundStyle(DesignTokens.Colors.onSurfaceSecondary)
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

    private func submitPracticeDrawing() {
        guard let card = viewModel.currentCard else { return }
        let lang = TTSService.languageCode(for: card.type)
        HandwritingRecognizer.recognize(drawing: drawing, language: lang) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let candidates):
                    let matched = HandwritingRecognizer.bestMatch(candidates: candidates, expected: viewModel.practiceCorrectAnswer)
                    if matched {
                        viewModel.submitPracticeAnswer(recognized: viewModel.practiceCorrectAnswer)
                    } else {
                        viewModel.submitPracticeAnswer(recognized: candidates.first ?? "")
                    }
                case .failure:
                    viewModel.submitPracticeAnswer(recognized: "")
                }
                drawing = PKDrawing()
            }
        }
    }
}
