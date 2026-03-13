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

    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State private var bouncing = false

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
        VStack(spacing: DesignTokens.Spacing.xs) {
            DinoCharacter(state: state)
                .frame(width: 60, height: 60)
                .scaleEffect(bouncing ? 1.15 : 1.0)

            // Speech bubble
            Text(message)
                .font(DesignTokens.Font.footnote)
                .foregroundStyle(DesignTokens.Colors.onSurface)
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.vertical, DesignTokens.Spacing.sm)
                .background {
                    SpeechBubble()
                        .fill(DesignTokens.Colors.surface)
                }
        }
        .onChange(of: state) {
            if reduceMotion {
                bouncing = false
            } else {
                withAnimation(DesignTokens.Animation.bounce) {
                    bouncing = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    withAnimation(DesignTokens.Animation.gentle) {
                        bouncing = false
                    }
                }
            }
        }
        .animation(reduceMotion ? nil : DesignTokens.Animation.gentle, value: state)
    }
}

// MARK: - Dino Character (SwiftUI drawn)

private struct DinoCharacter: View {
    let state: MascotState

    private var bodyColor: Color {
        switch state {
        case .idle: return Color(red: 0.45, green: 0.78, blue: 0.65)     // teal green
        case .thinking: return Color(red: 0.55, green: 0.75, blue: 0.85) // sky blue
        case .happy: return Color(red: 0.95, green: 0.75, blue: 0.30)    // golden
        case .encourage: return Color(red: 0.90, green: 0.55, blue: 0.45) // warm coral
        case .celebrate: return Color(red: 0.85, green: 0.50, blue: 0.85) // lavender
        }
    }

    private var cheekColor: Color {
        bodyColor.opacity(0.4)
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                // Body (rounded blob)
                Ellipse()
                    .fill(bodyColor)
                    .frame(width: w * 0.7, height: h * 0.55)
                    .offset(y: h * 0.15)

                // Head (circle)
                Circle()
                    .fill(bodyColor)
                    .frame(width: w * 0.55, height: h * 0.55)
                    .offset(y: -h * 0.08)

                // Spikes on head
                spikes(w: w, h: h)

                // Eyes
                eyes(w: w, h: h)

                // Mouth
                mouth(w: w, h: h)

                // Cheeks (blush)
                if state == .happy || state == .celebrate {
                    Circle()
                        .fill(cheekColor)
                        .frame(width: w * 0.1, height: h * 0.1)
                        .offset(x: -w * 0.15, y: h * 0.02)
                    Circle()
                        .fill(cheekColor)
                        .frame(width: w * 0.1, height: h * 0.1)
                        .offset(x: w * 0.15, y: h * 0.02)
                }

                // Little arms
                arm(w: w, h: h, isLeft: true)
                arm(w: w, h: h, isLeft: false)

                // Tail
                tail(w: w, h: h)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func spikes(w: CGFloat, h: CGFloat) -> some View {
        let spikeColor = bodyColor.opacity(0.7)
        return Group {
            // Three small triangular spikes
            Triangle()
                .fill(spikeColor)
                .frame(width: w * 0.08, height: h * 0.1)
                .offset(x: -w * 0.06, y: -h * 0.35)
            Triangle()
                .fill(spikeColor)
                .frame(width: w * 0.09, height: h * 0.12)
                .offset(y: -h * 0.37)
            Triangle()
                .fill(spikeColor)
                .frame(width: w * 0.08, height: h * 0.1)
                .offset(x: w * 0.06, y: -h * 0.35)
        }
    }

    @ViewBuilder
    private func eyes(w: CGFloat, h: CGFloat) -> some View {
        let eyeY = -h * 0.1
        switch state {
        case .happy, .celebrate:
            // Happy closed eyes (arcs)
            HappyEye()
                .stroke(Color.black, lineWidth: 2)
                .frame(width: w * 0.1, height: h * 0.05)
                .offset(x: -w * 0.1, y: eyeY)
            HappyEye()
                .stroke(Color.black, lineWidth: 2)
                .frame(width: w * 0.1, height: h * 0.05)
                .offset(x: w * 0.1, y: eyeY)
        case .thinking:
            // One eye normal, one raised
            Circle()
                .fill(Color.black)
                .frame(width: w * 0.08, height: h * 0.08)
                .offset(x: -w * 0.1, y: eyeY)
            Circle()
                .fill(Color.black)
                .frame(width: w * 0.08, height: h * 0.08)
                .offset(x: w * 0.1, y: eyeY - h * 0.03)
        default:
            // Normal round eyes
            Circle()
                .fill(Color.black)
                .frame(width: w * 0.08, height: h * 0.08)
                .offset(x: -w * 0.1, y: eyeY)
            // Eye highlight
            Circle()
                .fill(Color.white)
                .frame(width: w * 0.03, height: h * 0.03)
                .offset(x: -w * 0.08, y: eyeY - h * 0.015)
            Circle()
                .fill(Color.black)
                .frame(width: w * 0.08, height: h * 0.08)
                .offset(x: w * 0.1, y: eyeY)
            Circle()
                .fill(Color.white)
                .frame(width: w * 0.03, height: h * 0.03)
                .offset(x: w * 0.12, y: eyeY - h * 0.015)
        }
    }

    @ViewBuilder
    private func mouth(w: CGFloat, h: CGFloat) -> some View {
        let mouthY = h * 0.02
        switch state {
        case .happy, .celebrate:
            // Big smile
            SmileMouth()
                .stroke(Color.black, lineWidth: 1.5)
                .frame(width: w * 0.15, height: h * 0.08)
                .offset(y: mouthY)
        case .encourage:
            // Determined line
            RoundedRectangle(cornerRadius: 1)
                .fill(Color.black)
                .frame(width: w * 0.1, height: 2)
                .offset(y: mouthY)
        case .thinking:
            // Small 'o'
            Circle()
                .stroke(Color.black, lineWidth: 1.5)
                .frame(width: w * 0.06, height: h * 0.06)
                .offset(y: mouthY + h * 0.01)
        default:
            // Gentle smile
            SmileMouth()
                .stroke(Color.black, lineWidth: 1.5)
                .frame(width: w * 0.1, height: h * 0.05)
                .offset(y: mouthY)
        }
    }

    private func arm(w: CGFloat, h: CGFloat, isLeft: Bool) -> some View {
        let xSign: CGFloat = isLeft ? -1 : 1
        let rotation: Double = state == .celebrate ? (isLeft ? -30 : 30) : (isLeft ? -10 : 10)
        return Capsule()
            .fill(bodyColor)
            .frame(width: w * 0.08, height: h * 0.18)
            .rotationEffect(.degrees(rotation))
            .offset(x: xSign * w * 0.3, y: h * 0.12)
    }

    private func tail(w: CGFloat, h: CGFloat) -> some View {
        Capsule()
            .fill(bodyColor)
            .frame(width: w * 0.2, height: h * 0.08)
            .rotationEffect(.degrees(-15))
            .offset(x: w * 0.32, y: h * 0.28)
    }
}

// MARK: - Helper Shapes

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct HappyEye: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.maxY),
            control: CGPoint(x: rect.midX, y: rect.minY)
        )
        return path
    }
}

private struct SmileMouth: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY),
            control: CGPoint(x: rect.midX, y: rect.maxY)
        )
        return path
    }
}

/// A rounded rectangle with a small upward-pointing triangle (tail) at the top center.
private struct SpeechBubble: Shape {
    func path(in rect: CGRect) -> Path {
        let cornerRadius: CGFloat = DesignTokens.Radius.sm
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
