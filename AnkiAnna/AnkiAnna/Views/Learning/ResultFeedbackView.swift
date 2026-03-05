import SwiftUI

struct ResultFeedbackView: View {
    let isCorrect: Bool
    let correctAnswer: String
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
