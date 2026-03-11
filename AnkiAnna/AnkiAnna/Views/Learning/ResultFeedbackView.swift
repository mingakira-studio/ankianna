import SwiftUI

struct ResultFeedbackView: View {
    let isCorrect: Bool
    let correctAnswer: String
    var charResults: [SpellingChecker.CharResult]? = nil
    var combo: Int = 0
    var pointsEarned: Int = 0
    let onNext: () -> Void
    let onRetry: () -> Void

    @State private var pointsScale: CGFloat = 2.0
    @State private var comboScale: CGFloat = 0.5
    @State private var checkmarkScale: CGFloat = 0.5

    var body: some View {
        VStack(spacing: 20) {
            if isCorrect {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.green)
                    .scaleEffect(checkmarkScale)
                    .accessibilityIdentifier("correctFeedback")
                    .onAppear {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                            checkmarkScale = 1.0
                        }
                    }

                if pointsEarned > 0 {
                    Text("+\(pointsEarned)")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.orange)
                        .scaleEffect(pointsScale)
                        .accessibilityIdentifier("pointsEarnedText")
                        .onAppear {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                                pointsScale = 1.0
                            }
                        }
                }

                if combo >= 2 {
                    Text("🔥 x\(combo)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.orange)
                        .scaleEffect(comboScale)
                        .accessibilityIdentifier("comboText")
                        .onAppear {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) {
                                comboScale = 1.0
                            }
                        }
                }

                Text("太棒了！")
                    .font(.system(size: 32, weight: .bold))

                if combo >= 3 {
                    ComboFireView(combo: combo)
                }
            } else {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.red)

                // Per-character feedback for English spelling
                if let charResults = charResults {
                    Text("你的拼写")
                        .font(.headline)
                    HStack(spacing: 2) {
                        ForEach(Array(charResults.enumerated()), id: \.offset) { _, result in
                            Text(String(result.character))
                                .font(.system(size: 36, weight: .bold, design: .monospaced))
                                .foregroundStyle(result.isCorrect ? .green : .red)
                        }
                    }
                }

                Text("正确答案")
                    .font(.headline)
                Text(correctAnswer)
                    .font(.system(size: 48, weight: .bold))
                    .accessibilityIdentifier("correctAnswerText")
            }

            if isCorrect {
                Button("下一个", action: onNext)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .accessibilityIdentifier("nextButton")
            } else {
                Button("再试一次", action: onRetry)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .accessibilityIdentifier("retryButton")
            }

            if !isCorrect {
                EncouragementView()
            }
        }
        .padding()
        .overlay {
            if isCorrect {
                ConfettiView()
            }
        }
    }
}
