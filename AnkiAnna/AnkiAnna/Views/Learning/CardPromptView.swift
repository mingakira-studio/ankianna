import SwiftUI

struct CardPromptView: View {
    let context: CardContext?
    let cardType: CardType
    let onSpeak: () -> Void

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            if let context {
                Text(context.text)
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
