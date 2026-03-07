import SwiftUI

enum MascotState {
    case idle       // Waiting for user to start
    case thinking   // User is writing/typing answer
    case happy      // User got it right
    case encourage  // User got it wrong
    case celebrate  // Session complete or high combo
}

struct MascotView: View {
    let state: MascotState

    @State private var bouncing = false

    private var emoji: String {
        switch state {
        case .idle: return "🦕"
        case .thinking: return "🤔"
        case .happy: return "🥳"
        case .encourage: return "💪"
        case .celebrate: return "🎉"
        }
    }

    private var message: String {
        switch state {
        case .idle: return "准备好了吗？"
        case .thinking: return "认真想想..."
        case .happy: return "太棒了！"
        case .encourage: return "再试试！"
        case .celebrate: return "你真厉害！"
        }
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(emoji)
                .font(.system(size: 50))
                .scaleEffect(bouncing ? 1.15 : 1.0)

            // Speech bubble
            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background {
                    SpeechBubble()
                        .fill(Color(.systemGray6))
                }
        }
        .onChange(of: state) {
            bouncing = true
            withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) {
                bouncing = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    bouncing = false
                }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: state)
    }
}

/// A rounded rectangle with a small upward-pointing triangle (tail) at the top center.
private struct SpeechBubble: Shape {
    func path(in rect: CGRect) -> Path {
        let cornerRadius: CGFloat = 10
        let tailWidth: CGFloat = 10
        let tailHeight: CGFloat = 6

        var path = Path()

        // Tail pointing up
        let tailCenter = rect.midX
        path.move(to: CGPoint(x: tailCenter - tailWidth / 2, y: tailHeight))
        path.addLine(to: CGPoint(x: tailCenter, y: 0))
        path.addLine(to: CGPoint(x: tailCenter + tailWidth / 2, y: tailHeight))

        // Rounded rectangle body below the tail
        let bodyRect = CGRect(
            x: rect.minX,
            y: tailHeight,
            width: rect.width,
            height: rect.height - tailHeight
        )
        path.addRoundedRect(in: bodyRect, cornerSize: CGSize(width: cornerRadius, height: cornerRadius))

        return path
    }
}

#Preview {
    VStack(spacing: 30) {
        ForEach([MascotState.idle, .thinking, .happy, .encourage, .celebrate], id: \.self) { state in
            MascotView(state: state)
        }
    }
    .padding()
}

extension MascotState: Hashable {}
