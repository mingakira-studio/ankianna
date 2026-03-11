import SwiftUI
import SwiftData
import PencilKit

struct TimeAttackView: View {
    @Query var cards: [Card]
    @State private var viewModel: TimeAttackViewModel?
    @State private var selectedDuration: Int? = nil
    @State private var timer: Timer?
    @State private var drawing = PKDrawing()
    @State private var typedAnswer = ""

    var body: some View {
        if let vm = viewModel {
            if vm.isGameOver {
                gameOverView(vm)
            } else if vm.isRunning {
                gameplayView(vm)
            } else {
                durationPicker
            }
        } else {
            durationPicker
        }
    }

    private var durationPicker: some View {
        VStack(spacing: 24) {
            Image(systemName: "timer")
                .font(.system(size: 60))
                .foregroundColor(.red)

            Text("限时挑战")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("选择时长，限时内尽可能多答对！")
                .foregroundColor(.secondary)

            VStack(spacing: 12) {
                ForEach([60, 90, 120], id: \.self) { seconds in
                    Button {
                        let vm = TimeAttackViewModel(duration: seconds)
                        vm.start(cards: cards)
                        viewModel = vm
                        startTimer()
                    } label: {
                        Text("\(seconds) 秒")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(12)
                    }
                    .disabled(cards.isEmpty)
                }
            }
            .padding(.horizontal, 40)

            if cards.isEmpty {
                Text("请先添加卡片")
                    .foregroundColor(.orange)
            }
        }
        .navigationTitle("限时挑战")
    }

    private func gameplayView(_ vm: TimeAttackViewModel) -> some View {
        VStack(spacing: 0) {
            // Top bar: timer + score + combo
            HStack {
                Label("\(vm.remainingTime)s", systemImage: "timer")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(vm.remainingTime <= 10 ? .red : .primary)

                Spacer()

                Text("连击 \(vm.combo)")
                    .font(.headline)
                    .foregroundColor(.orange)

                Spacer()

                Text("得分 \(vm.score)")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            .padding()
            .background(Color(.systemBackground))

            Divider()

            if vm.showResult {
                resultView(vm)
            } else if let card = vm.currentCard, let ctx = vm.currentContext {
                questionView(card: card, context: ctx, vm: vm)
            }
        }
    }

    private func questionView(card: Card, context: CardContext, vm: TimeAttackViewModel) -> some View {
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
                        vm.handleCorrectAnswer()
                    }
                    .buttonStyle(.bordered)

                    Button("模拟写错") {
                        drawing = PKDrawing()
                        vm.handleWrongAnswer()
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
                            vm.handleCorrectAnswer()
                        } else {
                            vm.handleWrongAnswer()
                        }
                    }
            }

            Spacer()
        }
    }

    private func resultView(_ vm: TimeAttackViewModel) -> some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: vm.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(vm.isCorrect ? .green : .red)

            if let card = vm.currentCard {
                Text(card.answer)
                    .font(.system(size: 48))
                    .fontWeight(.bold)
            }

            if vm.isCorrect {
                Text("+\(PointsService.pointsForAnswer(correct: true, combo: vm.combo)) 分  +3秒")
                    .font(.title2)
                    .foregroundColor(.green)
            }

            Button("继续") {
                vm.next()
            }
            .buttonStyle(.borderedProminent)
            .font(.title3)

            Spacer()
        }
    }

    private func gameOverView(_ vm: TimeAttackViewModel) -> some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "flag.checkered")
                .font(.system(size: 60))
                .foregroundColor(.red)

            Text("时间到！")
                .font(.largeTitle)
                .fontWeight(.bold)

            VStack(spacing: 12) {
                statRow(label: "总得分", value: "\(vm.score)")
                statRow(label: "答题数", value: "\(vm.answeredCount)")
                statRow(label: "正确数", value: "\(vm.correctCount)")
                statRow(label: "正确率", value: vm.answeredCount > 0 ? "\(vm.correctCount * 100 / vm.answeredCount)%" : "0%")
                statRow(label: "最佳连击", value: "\(vm.bestCombo)")
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)

            Button("再来一次") {
                viewModel = nil
            }
            .buttonStyle(.borderedProminent)
            .font(.title3)

            Spacer()
        }
        .navigationTitle("限时挑战")
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

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            viewModel?.tick()
            if viewModel?.isGameOver == true {
                timer?.invalidate()
                timer = nil
            }
        }
    }
}
