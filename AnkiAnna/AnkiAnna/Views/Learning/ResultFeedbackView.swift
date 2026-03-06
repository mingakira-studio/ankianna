import SwiftUI

struct ResultFeedbackView: View {
    let isCorrect: Bool
    let correctAnswer: String
    var charResults: [SpellingChecker.CharResult]? = nil
    let onNext: () -> Void
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            if isCorrect {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.green)
                Text("太棒了！")
                    .font(.system(size: 32, weight: .bold))
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
            }

            HStack(spacing: 20) {
                if !isCorrect {
                    Button("再试一次", action: onRetry)
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                }
                Button(isCorrect ? "下一个" : "跳过", action: onNext)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
            }
        }
        .padding()
    }
}
