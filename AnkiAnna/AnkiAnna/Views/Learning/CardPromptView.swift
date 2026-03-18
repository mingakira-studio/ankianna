import SwiftUI

struct CardPromptView: View {
    let context: CardContext?
    let cardType: CardType
    let answer: String?
    let onSpeak: () -> Void

    init(context: CardContext?, cardType: CardType, answer: String? = nil, onSpeak: @escaping () -> Void) {
        self.context = context
        self.cardType = cardType
        self.answer = answer
        self.onSpeak = onSpeak
    }

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            if let context {
                Text(answer != nil ? context.displayText(answer: answer!) : context.text)
                    .font(DesignTokens.Font.promptText)
                    .multilineTextAlignment(.center)

                Text(context.type == .phrase ? "组词" : "造句")
                    .font(DesignTokens.Font.caption)
                    .foregroundStyle(DesignTokens.Colors.onSurfaceSecondary)
            }

            Button(action: onSpeak) {
                Image(systemName: "speaker.wave.2.fill")
                    .font(DesignTokens.Font.feedbackTitle)
                    .foregroundStyle(DesignTokens.Colors.primary)
            }
            .accessibilityLabel("朗读")
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
        .padding()
    }
}
