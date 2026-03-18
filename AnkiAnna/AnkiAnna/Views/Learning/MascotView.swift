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
    @State private var messageIndex = 0

    private static let messages: [MascotState: [String]] = [
        .idle: ["准备好了吗？", "开始写吧！", "加油哦~", "我在这里陪你！"],
        .thinking: ["认真想想...", "慢慢来~", "你可以的！", "仔细回忆一下~"],
        .happy: ["太棒了！", "写得真好！", "你好厉害！", "完美！继续！", "真聪明！"],
        .encourage: ["再试试！", "没关系的~", "别灰心！", "下次一定行！", "我相信你！"],
        .celebrate: ["你真厉害！", "太了不起了！", "今天进步好大！", "为你骄傲！", "冠军！"],
    ]

    private var message: String {
        let msgs = Self.messages[state] ?? [""]
        let idx = messageIndex % msgs.count
        return msgs[idx]
    }

    var body: some View {
        VStack(spacing: 0) {
            DinoSceneView(state: state)
                .frame(width: 200, height: 160)
                .scaleEffect(bouncing ? 1.08 : 1.0)

            // Speech bubble below dino
            Text(message)
                .font(DesignTokens.Font.footnote)
                .foregroundStyle(DesignTokens.Colors.onSurface)
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.vertical, DesignTokens.Spacing.xs)
                .background(
                    Capsule()
                        .fill(DesignTokens.Colors.surface)
                        .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
                )
                .offset(y: -8)
        }
        .onChange(of: state) {
            messageIndex = Int.random(in: 0..<100)
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

// MARK: - Dragon Character (3D-style SwiftUI drawn)

private struct DragonCharacter: View {
    let state: MascotState
    let reduceMotion: Bool

    @State private var blinkPhase = false
    @State private var armWave = false

    // Dragon color palette
    private var primaryColor: Color {
        switch state {
        case .idle: return Color(red: 0.30, green: 0.72, blue: 0.55)      // emerald
        case .thinking: return Color(red: 0.40, green: 0.65, blue: 0.82)  // sky blue
        case .happy: return Color(red: 0.95, green: 0.70, blue: 0.20)     // golden
        case .encourage: return Color(red: 0.88, green: 0.48, blue: 0.42) // warm coral
        case .celebrate: return Color(red: 0.72, green: 0.42, blue: 0.82) // royal purple
        }
    }

    private var lightColor: Color { primaryColor.opacity(0.5) }
    private var darkColor: Color {
        switch state {
        case .idle: return Color(red: 0.18, green: 0.50, blue: 0.35)
        case .thinking: return Color(red: 0.25, green: 0.45, blue: 0.60)
        case .happy: return Color(red: 0.75, green: 0.50, blue: 0.10)
        case .encourage: return Color(red: 0.65, green: 0.30, blue: 0.25)
        case .celebrate: return Color(red: 0.50, green: 0.25, blue: 0.60)
        }
    }

    private var bellyColor: Color {
        Color(red: 0.98, green: 0.95, blue: 0.85) // cream
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                // Tail
                tail(w: w, h: h)

                // Wings
                wing(w: w, h: h, isLeft: true)
                wing(w: w, h: h, isLeft: false)

                // Body with gradient
                bodyShape(w: w, h: h)

                // Belly patch
                bellyPatch(w: w, h: h)

                // Head with gradient
                headShape(w: w, h: h)

                // Horns
                horn(w: w, h: h, isLeft: true)
                horn(w: w, h: h, isLeft: false)

                // Spikes along back
                spikes(w: w, h: h)

                // Eyes with expressions
                eyes(w: w, h: h)

                // Eyebrows
                eyebrows(w: w, h: h)

                // Mouth
                mouth(w: w, h: h)

                // Cheeks
                cheeks(w: w, h: h)

                // Whiskers
                whiskers(w: w, h: h)

                // Arms
                arm(w: w, h: h, isLeft: true)
                arm(w: w, h: h, isLeft: false)

                // Feet
                foot(w: w, h: h, isLeft: true)
                foot(w: w, h: h, isLeft: false)

                // Special effects
                specialEffects(w: w, h: h)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .onAppear { startAnimations() }
        .onChange(of: state) { startAnimations() }
    }

    private func startAnimations() {
        guard !reduceMotion else { return }
        if state == .thinking {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                blinkPhase = true
            }
        } else {
            blinkPhase = false
        }
        if state == .celebrate {
            withAnimation(.easeInOut(duration: 0.4).repeatCount(4, autoreverses: true)) {
                armWave = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { armWave = false }
        } else {
            armWave = false
        }
    }

    // MARK: - Body Parts

    private func bodyShape(w: CGFloat, h: CGFloat) -> some View {
        Ellipse()
            .fill(
                LinearGradient(
                    colors: [lightColor, primaryColor, darkColor],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: w * 0.62, height: h * 0.48)
            .shadow(color: darkColor.opacity(0.3), radius: 4, x: 2, y: 3)
            .offset(y: h * 0.18)
    }

    private func bellyPatch(w: CGFloat, h: CGFloat) -> some View {
        Ellipse()
            .fill(
                RadialGradient(
                    colors: [bellyColor, bellyColor.opacity(0.6)],
                    center: .center,
                    startRadius: 0,
                    endRadius: w * 0.15
                )
            )
            .frame(width: w * 0.30, height: h * 0.28)
            .offset(y: h * 0.18)
    }

    private func headShape(w: CGFloat, h: CGFloat) -> some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [lightColor, primaryColor, darkColor],
                    center: UnitPoint(x: 0.35, y: 0.3),
                    startRadius: 0,
                    endRadius: w * 0.35
                )
            )
            .frame(width: w * 0.52, height: h * 0.52)
            .shadow(color: darkColor.opacity(0.2), radius: 3, x: 1, y: 2)
            .offset(y: -h * 0.06)
    }

    private func horn(w: CGFloat, h: CGFloat, isLeft: Bool) -> some View {
        let xOffset = isLeft ? -w * 0.12 : w * 0.12
        return Triangle()
            .fill(
                LinearGradient(
                    colors: [Color(red: 1.0, green: 0.85, blue: 0.50), Color(red: 0.85, green: 0.65, blue: 0.30)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: w * 0.08, height: h * 0.14)
            .rotationEffect(.degrees(isLeft ? -15 : 15))
            .offset(x: xOffset, y: -h * 0.30)
    }

    private func spikes(w: CGFloat, h: CGFloat) -> some View {
        let spikeGradient = LinearGradient(
            colors: [primaryColor.opacity(0.8), darkColor],
            startPoint: .top,
            endPoint: .bottom
        )
        return Group {
            Triangle().fill(spikeGradient)
                .frame(width: w * 0.06, height: h * 0.08)
                .offset(x: -w * 0.04, y: -h * 0.32)
            Triangle().fill(spikeGradient)
                .frame(width: w * 0.07, height: h * 0.10)
                .offset(y: -h * 0.33)
            Triangle().fill(spikeGradient)
                .frame(width: w * 0.06, height: h * 0.08)
                .offset(x: w * 0.04, y: -h * 0.32)
        }
    }

    private func wing(w: CGFloat, h: CGFloat, isLeft: Bool) -> some View {
        let xSign: CGFloat = isLeft ? -1 : 1
        let wingRotation: Double = state == .celebrate ? (isLeft ? -25 : 25) : (isLeft ? -5 : 5)
        return WingShape()
            .fill(
                LinearGradient(
                    colors: [primaryColor.opacity(0.4), primaryColor.opacity(0.15)],
                    startPoint: isLeft ? .trailing : .leading,
                    endPoint: isLeft ? .leading : .trailing
                )
            )
            .frame(width: w * 0.25, height: h * 0.22)
            .scaleEffect(x: isLeft ? -1 : 1, y: 1)
            .rotationEffect(.degrees(wingRotation))
            .offset(x: xSign * w * 0.35, y: h * 0.05)
    }

    private func tail(w: CGFloat, h: CGFloat) -> some View {
        TailShape()
            .fill(
                LinearGradient(
                    colors: [primaryColor, darkColor],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: w * 0.30, height: h * 0.10)
            .offset(x: w * 0.28, y: h * 0.32)
    }

    @ViewBuilder
    private func eyes(w: CGFloat, h: CGFloat) -> some View {
        let eyeY = -h * 0.08
        let eyeSpacing = w * 0.10

        switch state {
        case .happy:
            // Happy arcs
            happyEyePair(w: w, h: h, eyeY: eyeY, spacing: eyeSpacing)
        case .celebrate:
            // Star eyes
            starEye(w: w, h: h, x: -eyeSpacing, y: eyeY)
            starEye(w: w, h: h, x: eyeSpacing, y: eyeY)
        case .thinking:
            // Blinking eye
            normalEye(w: w, h: h, x: -eyeSpacing, y: eyeY)
            normalEye(w: w, h: h, x: eyeSpacing, y: eyeY - (blinkPhase ? 0 : h * 0.02))
        case .encourage:
            // Sympathetic eyes (slightly droopy)
            normalEye(w: w, h: h, x: -eyeSpacing, y: eyeY + h * 0.01)
            normalEye(w: w, h: h, x: eyeSpacing, y: eyeY + h * 0.01)
        default:
            normalEye(w: w, h: h, x: -eyeSpacing, y: eyeY)
            normalEye(w: w, h: h, x: eyeSpacing, y: eyeY)
        }
    }

    private func normalEye(w: CGFloat, h: CGFloat, x: CGFloat, y: CGFloat) -> some View {
        ZStack {
            // White
            Ellipse()
                .fill(Color.white)
                .frame(width: w * 0.12, height: h * 0.11)
            // Pupil
            Circle()
                .fill(Color(red: 0.15, green: 0.15, blue: 0.20))
                .frame(width: w * 0.07, height: h * 0.07)
                .offset(x: w * 0.005, y: h * 0.005)
            // Highlight
            Circle()
                .fill(Color.white)
                .frame(width: w * 0.03, height: h * 0.03)
                .offset(x: -w * 0.01, y: -h * 0.015)
        }
        .offset(x: x, y: y)
    }

    private func happyEyePair(w: CGFloat, h: CGFloat, eyeY: CGFloat, spacing: CGFloat) -> some View {
        Group {
            HappyEye()
                .stroke(Color(red: 0.15, green: 0.15, blue: 0.20), lineWidth: 2.5)
                .frame(width: w * 0.10, height: h * 0.05)
                .offset(x: -spacing, y: eyeY)
            HappyEye()
                .stroke(Color(red: 0.15, green: 0.15, blue: 0.20), lineWidth: 2.5)
                .frame(width: w * 0.10, height: h * 0.05)
                .offset(x: spacing, y: eyeY)
        }
    }

    private func starEye(w: CGFloat, h: CGFloat, x: CGFloat, y: CGFloat) -> some View {
        Image(systemName: "star.fill")
            .font(.system(size: w * 0.12))
            .foregroundStyle(Color.yellow)
            .shadow(color: .yellow.opacity(0.5), radius: 3)
            .offset(x: x, y: y)
    }

    @ViewBuilder
    private func eyebrows(w: CGFloat, h: CGFloat) -> some View {
        let browY = -h * 0.16
        let browSpacing = w * 0.10

        switch state {
        case .happy, .celebrate:
            // Raised happy brows
            Capsule().fill(darkColor)
                .frame(width: w * 0.10, height: h * 0.02)
                .rotationEffect(.degrees(-8))
                .offset(x: -browSpacing, y: browY - h * 0.02)
            Capsule().fill(darkColor)
                .frame(width: w * 0.10, height: h * 0.02)
                .rotationEffect(.degrees(8))
                .offset(x: browSpacing, y: browY - h * 0.02)
        case .encourage:
            // Worried brows (angled inward-up)
            Capsule().fill(darkColor)
                .frame(width: w * 0.10, height: h * 0.02)
                .rotationEffect(.degrees(12))
                .offset(x: -browSpacing, y: browY)
            Capsule().fill(darkColor)
                .frame(width: w * 0.10, height: h * 0.02)
                .rotationEffect(.degrees(-12))
                .offset(x: browSpacing, y: browY)
        case .thinking:
            // One raised, one flat
            Capsule().fill(darkColor)
                .frame(width: w * 0.10, height: h * 0.02)
                .offset(x: -browSpacing, y: browY)
            Capsule().fill(darkColor)
                .frame(width: w * 0.10, height: h * 0.02)
                .rotationEffect(.degrees(-10))
                .offset(x: browSpacing, y: browY - h * 0.02)
        default:
            // Neutral
            Capsule().fill(darkColor)
                .frame(width: w * 0.10, height: h * 0.02)
                .offset(x: -browSpacing, y: browY)
            Capsule().fill(darkColor)
                .frame(width: w * 0.10, height: h * 0.02)
                .offset(x: browSpacing, y: browY)
        }
    }

    @ViewBuilder
    private func mouth(w: CGFloat, h: CGFloat) -> some View {
        let mouthY = h * 0.04
        switch state {
        case .happy, .celebrate:
            // Big open smile
            SmileMouth()
                .stroke(Color(red: 0.15, green: 0.15, blue: 0.20), lineWidth: 2)
                .frame(width: w * 0.16, height: h * 0.08)
                .offset(y: mouthY)
        case .encourage:
            // Wavy concerned mouth
            SmileMouth()
                .stroke(Color(red: 0.15, green: 0.15, blue: 0.20), lineWidth: 1.5)
                .frame(width: w * 0.08, height: h * 0.03)
                .rotationEffect(.degrees(180))
                .offset(y: mouthY + h * 0.02)
        case .thinking:
            // Small 'o'
            Circle()
                .stroke(Color(red: 0.15, green: 0.15, blue: 0.20), lineWidth: 1.5)
                .frame(width: w * 0.06, height: h * 0.06)
                .offset(y: mouthY + h * 0.01)
        default:
            SmileMouth()
                .stroke(Color(red: 0.15, green: 0.15, blue: 0.20), lineWidth: 1.5)
                .frame(width: w * 0.12, height: h * 0.05)
                .offset(y: mouthY)
        }
    }

    @ViewBuilder
    private func cheeks(w: CGFloat, h: CGFloat) -> some View {
        if state == .happy || state == .celebrate {
            Circle()
                .fill(Color.pink.opacity(0.25))
                .frame(width: w * 0.10, height: h * 0.10)
                .offset(x: -w * 0.17, y: h * 0.02)
            Circle()
                .fill(Color.pink.opacity(0.25))
                .frame(width: w * 0.10, height: h * 0.10)
                .offset(x: w * 0.17, y: h * 0.02)
        }
    }

    private func whiskers(w: CGFloat, h: CGFloat) -> some View {
        let whiskerColor = darkColor.opacity(0.4)
        return Group {
            // Left whiskers
            Capsule().fill(whiskerColor)
                .frame(width: w * 0.12, height: h * 0.01)
                .rotationEffect(.degrees(-10))
                .offset(x: -w * 0.25, y: h * 0.0)
            Capsule().fill(whiskerColor)
                .frame(width: w * 0.10, height: h * 0.01)
                .rotationEffect(.degrees(5))
                .offset(x: -w * 0.24, y: h * 0.04)
            // Right whiskers
            Capsule().fill(whiskerColor)
                .frame(width: w * 0.12, height: h * 0.01)
                .rotationEffect(.degrees(10))
                .offset(x: w * 0.25, y: h * 0.0)
            Capsule().fill(whiskerColor)
                .frame(width: w * 0.10, height: h * 0.01)
                .rotationEffect(.degrees(-5))
                .offset(x: w * 0.24, y: h * 0.04)
        }
    }

    private func arm(w: CGFloat, h: CGFloat, isLeft: Bool) -> some View {
        let xSign: CGFloat = isLeft ? -1 : 1
        let baseRotation: Double = isLeft ? -10 : 10
        let waveRotation: Double = (state == .celebrate && armWave) ? (isLeft ? -40 : 40) : baseRotation

        return Capsule()
            .fill(
                LinearGradient(
                    colors: [primaryColor, darkColor],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: w * 0.08, height: h * 0.18)
            .rotationEffect(.degrees(waveRotation))
            .offset(x: xSign * w * 0.28, y: h * 0.15)
    }

    private func foot(w: CGFloat, h: CGFloat, isLeft: Bool) -> some View {
        let xSign: CGFloat = isLeft ? -1 : 1
        return Ellipse()
            .fill(
                LinearGradient(
                    colors: [primaryColor, darkColor],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: w * 0.14, height: h * 0.07)
            .offset(x: xSign * w * 0.12, y: h * 0.40)
    }

    @ViewBuilder
    private func specialEffects(w: CGFloat, h: CGFloat) -> some View {
        if state == .encourage {
            // Tear drop
            TearDrop()
                .fill(Color(red: 0.6, green: 0.8, blue: 1.0))
                .frame(width: w * 0.04, height: h * 0.06)
                .offset(x: w * 0.16, y: -h * 0.02)
        }
        if state == .celebrate {
            // Sparkles
            Image(systemName: "sparkle")
                .font(.system(size: w * 0.08))
                .foregroundStyle(.yellow)
                .offset(x: -w * 0.30, y: -h * 0.25)
            Image(systemName: "sparkle")
                .font(.system(size: w * 0.06))
                .foregroundStyle(.yellow)
                .offset(x: w * 0.32, y: -h * 0.20)
        }
    }
}

// MARK: - Custom Shapes

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

private struct WingShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY),
            control: CGPoint(x: rect.midX, y: rect.minY - rect.height * 0.3)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.maxY),
            control: CGPoint(x: rect.maxX + rect.width * 0.1, y: rect.midY)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.midY),
            control: CGPoint(x: rect.midX, y: rect.maxY + rect.height * 0.1)
        )
        return path
    }
}

private struct TailShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.midY - rect.height * 0.3),
            control: CGPoint(x: rect.midX, y: rect.minY)
        )
        // Tail tip (pointed)
        path.addLine(to: CGPoint(x: rect.maxX + rect.width * 0.05, y: rect.midY - rect.height * 0.5))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.midY),
            control: CGPoint(x: rect.midX, y: rect.maxY)
        )
        return path
    }
}

private struct TearDrop: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.midX, y: rect.maxY),
            control: CGPoint(x: rect.maxX, y: rect.midY)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.midX, y: rect.minY),
            control: CGPoint(x: rect.minX, y: rect.midY)
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

        let tailCenter = rect.midX
        path.move(to: CGPoint(x: tailCenter - tailWidth / 2, y: tailHeight))
        path.addLine(to: CGPoint(x: tailCenter, y: 0))
        path.addLine(to: CGPoint(x: tailCenter + tailWidth / 2, y: tailHeight))

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
