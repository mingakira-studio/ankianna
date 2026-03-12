import SwiftUI

struct CardPromptView: View {
    let context: CardContext?
    let cardType: CardType
    let onSpeak: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            if let context {
                Text(context.text)
                    .font(.system(size: 36, weight: .medium))
                    .multilineTextAlignment(.center)

                Text(context.type == .phrase ? "组词" : "造句")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button(action: onSpeak) {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.blue)
            }
            .accessibilityLabel("朗读")
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
        .padding()
    }
}
