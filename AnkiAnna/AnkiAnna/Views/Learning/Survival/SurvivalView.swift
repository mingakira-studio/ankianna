import SwiftUI
import SwiftData
import PencilKit

struct SurvivalView: View {
    @Query var cards: [Card]
    @State private var viewModel = SurvivalViewModel()
    @State private var hasStarted = false
    @State private var drawing = PKDrawing()
    @State private var typedAnswer = ""

    var body: some View {
        if viewModel.isGameOver {
            gameOverView
        } else if hasStarted {
            gameplayView
        } else {
            startView
        }
    }

    private var startView: some View {
        VStack(spacing: 24) {
            Image(systemName: "heart.fill")
                .font(.system(size: 60))
                .foregroundColor(.pink)

            Text("生存模式")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("3条命，看能走多远！\n连续答对5题恢复1条命")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            Button("开始挑战") {
                viewModel.start(cards: cards)
                hasStarted = true
            }
            .buttonStyle(.borderedProminent)
            .tint(.pink)
            .font(.title2)
            .disabled(cards.isEmpty)

            if cards.isEmpty {
                Text("请先添加卡片")
                    .foregroundColor(.orange)
            }
        }
        .navigationTitle("生存模式")
    }

    private var gameplayView: some View {
        VStack(spacing: 0) {
            // Top bar: lives + survived + combo
            HStack {
                HStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { i in
                        Image(systemName: i < viewModel.lives ? "heart.fill" : "heart")
                            .foregroundColor(.pink)
                            .font(.title2)
                    }
                }

                Spacer()

                Text("连击 \(viewModel.combo)")
                    .font(.headline)
                    .foregroundColor(.orange)

                Spacer()

                Text("存活 \(viewModel.survivedCount)")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            .padding()
            .background(Color(.systemBackground))

            Divider()

            if viewModel.showResult {
                resultView
            } else if let card = viewModel.currentCard, let ctx = viewModel.currentContext {
                questionView(card: card, context: ctx)
            }
        }
    }

    private func questionView(card: Card, context: CardContext) -> some View {
        VStack(spacing: 20) {
            Spacer()

            Text(context.text)
                .font(.title)
                .multilineTextAlignment(.center)
                .padding()
                .onAppear {
                    TTSService.speak(text: context.fullText, cardType: card.type)
                }

            if card.type == .chineseWriting {
                WritingCanvasView(drawing: $drawing)
                    .frame(height: 200)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)

                HStack(spacing: 16) {
                    #if DEBUG
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
                    #endif
                }
            } else {
                TextField("输入答案", text: $typedAnswer)
                    .textFieldStyle(.roundedBorder)
                    .font(.title2)
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

            Spacer()
        }
    }

    private var resultView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: viewModel.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(viewModel.isCorrect ? .green : .red)

            if let card = viewModel.currentCard {
                Text(card.answer)
                    .font(.system(size: 48))
                    .fontWeight(.bold)
            }

            if !viewModel.isCorrect {
                Text("剩余 \(viewModel.lives) 条命")
                    .font(.title2)
                    .foregroundColor(.pink)
            }

            Button("继续") {
                viewModel.next()
            }
            .buttonStyle(.borderedProminent)
            .font(.title3)

            Spacer()
        }
    }

    private var gameOverView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "heart.slash.fill")
                .font(.system(size: 60))
                .foregroundColor(.pink)

            Text("游戏结束")
                .font(.largeTitle)
                .fontWeight(.bold)

            VStack(spacing: 12) {
                statRow(label: "存活数", value: "\(viewModel.survivedCount)")
                statRow(label: "最佳连击", value: "\(viewModel.bestCombo)")
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)

            Button("再来一次") {
                viewModel = SurvivalViewModel()
                hasStarted = false
            }
            .buttonStyle(.borderedProminent)
            .tint(.pink)
            .font(.title3)

            Spacer()
        }
        .navigationTitle("生存模式")
    }

    private func statRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.bold)
        }
    }
}
