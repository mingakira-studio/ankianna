import SwiftUI
import SwiftData
import PencilKit

struct TimeAttackView: View {
    @Environment(\.dismiss) private var dismiss
    @Query var cards: [Card]
    @State private var viewModel: TimeAttackViewModel?
    @State private var selectedDuration: Int? = nil
    @State private var timer: Timer?
    @State private var drawing = PKDrawing()
    @State private var typedAnswer = ""

    var body: some View {
        Group {
            if let vm = viewModel {
                if vm.isGameOver {
                    gameOverView(vm)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                } else if vm.isRunning {
                    gameplayView(vm)
                        .transition(.opacity)
                } else {
                    durationPicker
                }
            } else {
                durationPicker
            }
        }
        .animation(DesignTokens.Animation.quick, value: viewModel?.isGameOver)
        .animation(DesignTokens.Animation.quick, value: viewModel?.isRunning)
    }

    private var durationPicker: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            Image(systemName: "timer")
                .font(.system(size: DesignTokens.IconSize.xl))
                .foregroundColor(DesignTokens.Colors.timeAttack)

            Text("限时挑战")
                .font(DesignTokens.Font.largeTitle)

            Text("选择时长，限时内尽可能多答对！")
                .font(DesignTokens.Font.body)
                .foregroundColor(DesignTokens.Colors.onSurfaceSecondary)

            VStack(spacing: DesignTokens.Spacing.md) {
                ForEach([60, 90, 120], id: \.self) { seconds in
                    Button {
                        let vm = TimeAttackViewModel(duration: seconds)
                        vm.start(cards: cards)
                        viewModel = vm
                        startTimer()
                    } label: {
                        Text("\(seconds) 秒")
                            .font(DesignTokens.Font.title2)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(DesignTokens.Colors.timeAttack.opacity(0.1))
                            .cornerRadius(DesignTokens.Radius.md)
                    }
                    .disabled(cards.isEmpty)
                }
            }
            .padding(.horizontal, 40)

            if cards.isEmpty {
                Text("请先添加卡片")
                    .font(DesignTokens.Font.body)
                    .foregroundColor(DesignTokens.Colors.warning)
            }
        }
        .navigationTitle("限时挑战")
    }

    private func gameplayView(_ vm: TimeAttackViewModel) -> some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height
            VStack(spacing: 0) {
                // Top bar: timer + score + combo
                HStack {
                    Label("\(vm.remainingTime)s", systemImage: "timer")
                        .font(DesignTokens.Font.title2)
                        .foregroundColor(vm.remainingTime <= 10 ? DesignTokens.Colors.error : DesignTokens.Colors.onSurface)

                    Spacer()

                    Text("连击 \(vm.combo)")
                        .font(DesignTokens.Font.headline)
                        .foregroundColor(DesignTokens.Colors.accent)

                    Spacer()

                    Text("得分 \(vm.score)")
                        .font(DesignTokens.Font.title2)
                }
                .padding()

                Divider()

                if vm.showResult {
                    resultView(vm)
                } else if let card = vm.currentCard, let ctx = vm.currentContext {
                    questionView(card: card, context: ctx, vm: vm, isLandscape: isLandscape)
                }
            }
        }
    }

    @ViewBuilder
    private func questionView(card: Card, context: CardContext, vm: TimeAttackViewModel, isLandscape: Bool = false) -> some View {
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
                    inputArea(card: card, onCorrect: { vm.handleCorrectAnswer() }, onWrong: { vm.handleWrongAnswer() })
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

                inputArea(card: card, onCorrect: { vm.handleCorrectAnswer() }, onWrong: { vm.handleWrongAnswer() })

                Spacer()
            }
        }
    }

    @ViewBuilder
    private func inputArea(card: Card, onCorrect: @escaping () -> Void, onWrong: @escaping () -> Void) -> some View {
        if card.type == .chineseWriting {
            WritingCanvasView(drawing: $drawing)
                .frame(height: 200)
                .background(DesignTokens.Colors.surface)
                .cornerRadius(DesignTokens.Radius.md)
                .padding(.horizontal)

            HStack(spacing: DesignTokens.Spacing.lg) {
                #if DEBUG
                Button("模拟写对") {
                    drawing = PKDrawing()
                    onCorrect()
                }
                .buttonStyle(.bordered)

                Button("模拟写错") {
                    drawing = PKDrawing()
                    onWrong()
                }
                .buttonStyle(.bordered)
                #endif
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
                        onCorrect()
                    } else {
                        onWrong()
                    }
                }
        }
    }

    private func resultView(_ vm: TimeAttackViewModel) -> some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            Spacer()

            Image(systemName: vm.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: DesignTokens.IconSize.xxl))
                .foregroundColor(vm.isCorrect ? DesignTokens.Colors.success : DesignTokens.Colors.error)

            if let card = vm.currentCard {
                Text(card.answer)
                    .font(DesignTokens.Font.rounded(size: DesignTokens.CharSize.answer, weight: .bold))
            }

            if vm.isCorrect {
                Text("+\(PointsService.pointsForAnswer(correct: true, combo: vm.combo)) 分  +3秒")
                    .font(DesignTokens.Font.title2)
                    .foregroundColor(DesignTokens.Colors.success)
            }

            Button("继续") {
                vm.next()
            }
            .buttonStyle(.borderedProminent)
            .font(DesignTokens.Font.title3)

            Spacer()
        }
    }

    private func gameOverView(_ vm: TimeAttackViewModel) -> some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            Spacer()

            Image(systemName: "flag.checkered")
                .font(.system(size: DesignTokens.IconSize.xl))
                .foregroundColor(DesignTokens.Colors.timeAttack)

            Text("时间到！")
                .font(DesignTokens.Font.largeTitle)

            VStack(spacing: DesignTokens.Spacing.md) {
                statRow(label: "总得分", value: "\(vm.score)")
                statRow(label: "答题数", value: "\(vm.answeredCount)")
                statRow(label: "正确数", value: "\(vm.correctCount)")
                statRow(label: "正确率", value: vm.answeredCount > 0 ? "\(vm.correctCount * 100 / vm.answeredCount)%" : "0%")
                statRow(label: "最佳连击", value: "\(vm.bestCombo)")
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
                    viewModel = nil
                }
                .buttonStyle(.borderedProminent)
                .font(DesignTokens.Font.title3)
            }

            Spacer()
        }
        .navigationTitle("限时挑战")
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
