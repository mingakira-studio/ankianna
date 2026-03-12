import SwiftUI

struct ResultFeedbackView: View {
    let isCorrect: Bool
    let correctAnswer: String
    var charResults: [SpellingChecker.CharResult]? = nil
    var combo: Int = 0
    var pointsEarned: Int = 0
    let onNext: () -> Void
    let onRetry: () -> Void

    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State private var pointsScale: CGFloat = 2.0
    @State private var comboScale: CGFloat = 0.5
    @State private var checkmarkScale: CGFloat = 0.5

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            if isCorrect {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: DesignTokens.IconSize.xxl))
                    .foregroundStyle(DesignTokens.Colors.success)
                    .scaleEffect(checkmarkScale)
                    .accessibilityIdentifier("correctFeedback")
                    .onAppear {
                        if reduceMotion {
                            checkmarkScale = 1.0
                        } else {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                                checkmarkScale = 1.0
                            }
                        }
                    }

                if pointsEarned > 0 {
                    Text("+\(pointsEarned)")
                        .font(DesignTokens.Font.points)
                        .foregroundStyle(DesignTokens.Colors.accent)
                        .scaleEffect(pointsScale)
                        .accessibilityIdentifier("pointsEarnedText")
                        .onAppear {
                            if reduceMotion {
                                pointsScale = 1.0
                            } else {
                                withAnimation(DesignTokens.Animation.gentle) {
                                    pointsScale = 1.0
                                }
                            }
                        }
                }

                if combo >= 2 {
                    Text("x\(combo)")
                        .font(DesignTokens.Font.encouragement)
                        .foregroundStyle(DesignTokens.Colors.accent)
                        .scaleEffect(comboScale)
                        .accessibilityIdentifier("comboText")
                        .onAppear {
                            if reduceMotion {
                                comboScale = 1.0
                            } else {
                                withAnimation(DesignTokens.Animation.bounce) {
                                    comboScale = 1.0
                                }
                            }
                        }
                }

                Text("太棒了！")
                    .font(DesignTokens.Font.feedbackTitle)

                if combo >= 3 {
                    ComboFireView(combo: combo)
                }
            } else {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: DesignTokens.IconSize.xxl))
                    .foregroundStyle(DesignTokens.Colors.error)

                // Per-character feedback for English spelling
                if let charResults = charResults {
                    Text("你的拼写")
                        .font(DesignTokens.Font.headline)
                    HStack(spacing: 2) {
                        ForEach(Array(charResults.enumerated()), id: \.offset) { _, result in
                            Text(String(result.character))
                                .font(DesignTokens.Font.spellingChar)
                                .foregroundStyle(result.isCorrect ? DesignTokens.Colors.success : DesignTokens.Colors.error)
                        }
                    }
                }

                Text("正确答案")
                    .font(DesignTokens.Font.headline)
                Text(correctAnswer)
                    .font(DesignTokens.Font.rounded(size: DesignTokens.CharSize.answer, weight: .bold))
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
            if isCorrect && !reduceMotion {
                ConfettiView()
            }
        }
    }
}
