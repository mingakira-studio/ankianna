import SwiftUI
import SwiftData
import PencilKit

struct SurvivalView: View {
    var cardTypeFilter: CardType?

    @Environment(\.dismiss) private var dismiss
    @Query var cards: [Card]
    @State private var viewModel = SurvivalViewModel()
    @State private var hasStarted = false
    @State private var drawing = PKDrawing()
    @State private var typedAnswer = ""
    @AppStorage("testModeEnabled") private var testModeEnabled = false

    var body: some View {
        Group {
            if viewModel.isGameOver {
                gameOverView
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else if hasStarted {
                gameplayView
                    .transition(.opacity)
            } else {
                startView
            }
        }
        .animation(DesignTokens.Animation.quick, value: viewModel.isGameOver)
        .animation(DesignTokens.Animation.quick, value: hasStarted)
    }

    private var startView: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            Image(systemName: "heart.fill")
                .font(.system(size: DesignTokens.IconSize.xl))
                .foregroundColor(DesignTokens.Colors.survival)

            Text("生存模式")
                .font(DesignTokens.Font.largeTitle)

            Text("3条命，看能走多远！\n连续答对5题恢复1条命")
                .multilineTextAlignment(.center)
                .font(DesignTokens.Font.body)
                .foregroundColor(DesignTokens.Colors.onSurfaceSecondary)

            Button("开始挑战") {
                let filtered = cardTypeFilter.map { type in cards.filter { $0.type == type } } ?? cards
                viewModel.start(cards: filtered)
                hasStarted = true
            }
            .buttonStyle(.borderedProminent)
            .tint(DesignTokens.Colors.survival)
            .font(DesignTokens.Font.title2)
            .disabled(cards.isEmpty)

            if cards.isEmpty {
                Text("请先添加卡片")
                    .font(DesignTokens.Font.body)
                    .foregroundColor(DesignTokens.Colors.warning)
            }
        }
        .navigationTitle("生存模式")
    }

    private var gameplayView: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height
            VStack(spacing: 0) {
                // Top bar: lives + survived + combo
                HStack {
                    HStack(spacing: DesignTokens.Spacing.xs) {
                        ForEach(0..<3, id: \.self) { i in
                            Image(systemName: i < viewModel.lives ? "heart.fill" : "heart")
                                .foregroundColor(DesignTokens.Colors.survival)
                                .font(DesignTokens.Font.title2)
                        }
                    }

                    Spacer()

                    Text("连击 \(viewModel.combo)")
                        .font(DesignTokens.Font.headline)
                        .foregroundColor(DesignTokens.Colors.accent)

                    Spacer()

                    Text("存活 \(viewModel.survivedCount)")
                        .font(DesignTokens.Font.title2)
                }
                .padding()

                Divider()

                if viewModel.showResult {
                    resultView
                } else if let card = viewModel.currentCard, let ctx = viewModel.currentContext {
                    questionView(card: card, context: ctx, isLandscape: isLandscape)
                }
            }
        }
    }

    @ViewBuilder
    private func questionView(card: Card, context: CardContext, isLandscape: Bool = false) -> some View {
        if isLandscape {
            HStack(spacing: 0) {
                Text(context.text)
                    .font(DesignTokens.Font.title)
                    .multilineTextAlignment(.center)
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onAppear {
                        TTSService.speak(text: context.fullText, cardType: card.type)
                    }

                Divider()

                VStack(spacing: DesignTokens.Spacing.lg) {
                    Spacer()
                    inputArea(card: card)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
        } else {
            VStack(spacing: DesignTokens.Spacing.xl) {
                Spacer()

                Text(context.text)
                    .font(DesignTokens.Font.title)
                    .multilineTextAlignment(.center)
                    .padding()
                    .onAppear {
                        TTSService.speak(text: context.fullText, cardType: card.type)
                    }

                inputArea(card: card)

                Spacer()
            }
        }
    }

    @ViewBuilder
    private func inputArea(card: Card) -> some View {
        if card.type == .chineseWriting {
            WritingCanvasWithTools(drawing: $drawing)
                .frame(height: 200)
                .background(DesignTokens.Colors.surface)
                .cornerRadius(DesignTokens.Radius.md)
                .padding(.horizontal)

            if testModeEnabled {
                HStack(spacing: DesignTokens.Spacing.lg) {
                    Button("模拟写对") {
                        drawing = PKDrawing()
                        viewModel.handleCorrectAnswer()
                    }
                    .buttonStyle(.bordered)

                    Button("模拟写错") {
                        drawing = PKDrawing()
                        viewModel.handleWrongAnswer()
                    }
                    .buttonStyle(.bordered)
                }
            }
        } else {
            TextField("输入答案", text: $typedAnswer)
                .textFieldStyle(.roundedBorder)
                .font(DesignTokens.Font.title2)
                .padding(.horizontal)
                .onSubmit {
                    let correct = typedAnswer.lowercased().trimmingCharacters(in: .whitespaces) == card.answer.lowercased()
                    typedAnswer = ""
                    if correct {
                        viewModel.handleCorrectAnswer()
                    } else {
                        viewModel.handleWrongAnswer()
                    }
                }
        }
    }

    private var resultView: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            Spacer()

            Image(systemName: viewModel.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: DesignTokens.IconSize.xxl))
                .foregroundColor(viewModel.isCorrect ? DesignTokens.Colors.success : DesignTokens.Colors.error)

            if let card = viewModel.currentCard {
                Text(card.answer)
                    .font(DesignTokens.Font.rounded(size: DesignTokens.CharSize.answer, weight: .bold))
            }

            if !viewModel.isCorrect {
                Text("剩余 \(viewModel.lives) 条命")
                    .font(DesignTokens.Font.title2)
                    .foregroundColor(DesignTokens.Colors.survival)
            }

            Button("继续") {
                viewModel.next()
            }
            .buttonStyle(.borderedProminent)
            .font(DesignTokens.Font.title3)

            Spacer()
        }
    }

    private var gameOverView: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            Spacer()

            Image(systemName: "heart.slash.fill")
                .font(.system(size: DesignTokens.IconSize.xl))
                .foregroundColor(DesignTokens.Colors.survival)

            Text("游戏结束")
                .font(DesignTokens.Font.largeTitle)

            VStack(spacing: DesignTokens.Spacing.md) {
                statRow(label: "存活数", value: "\(viewModel.survivedCount)")
                statRow(label: "最佳连击", value: "\(viewModel.bestCombo)")
            }
            .padding()
            .background(DesignTokens.Colors.surface)
            .cornerRadius(DesignTokens.Radius.md)
            .padding(.horizontal)

            HStack(spacing: DesignTokens.Spacing.lg) {
                Button("返回首页") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                .font(DesignTokens.Font.title3)

                Button("再来一次") {
                    viewModel = SurvivalViewModel()
                    hasStarted = false
                }
                .buttonStyle(.borderedProminent)
                .tint(DesignTokens.Colors.survival)
                .font(DesignTokens.Font.title3)
            }

            Spacer()
        }
        .navigationTitle("生存模式")
    }

    private func statRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(DesignTokens.Font.body)
                .foregroundColor(DesignTokens.Colors.onSurfaceSecondary)
            Spacer()
            Text(value)
                .font(DesignTokens.Font.headline)
        }
    }
}
