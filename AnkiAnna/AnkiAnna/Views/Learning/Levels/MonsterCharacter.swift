import SwiftUI

enum MonsterState {
    case idle
    case hit       // Just got hit by dragon
    case attacking // Attacking the dragon
    case defeated  // Dead
}

struct MonsterCharacter: View {
    let character: String // The Chinese character displayed on the monster
    let isBoss: Bool
    let state: MonsterState
    let hp: Int
    let maxHp: Int

    @State private var shaking = false
    @State private var fadeOut = false

    private var scale: CGFloat { isBoss ? 1.3 : 1.0 }

    private var bodyColor: Color {
        switch state {
        case .hit: return Color(red: 1.0, green: 0.3, blue: 0.3)
        case .defeated: return Color.gray
        default: return Color(red: 0.55, green: 0.30, blue: 0.75)
        }
    }

    private var darkColor: Color {
        switch state {
        case .hit: return Color(red: 0.8, green: 0.15, blue: 0.15)
        case .defeated: return Color(red: 0.4, green: 0.4, blue: 0.4)
        default: return Color(red: 0.35, green: 0.15, blue: 0.55)
        }
    }

    var body: some View {
        ZStack {
            // Glow for boss
            if isBoss && state != .defeated {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [bodyColor.opacity(0.3), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 50
                        )
                    )
                    .frame(width: 100, height: 100)
            }

            monsterBody
                .scaleEffect(scale)
                .opacity(state == .defeated ? 0.3 : 1.0)
                .offset(x: shaking ? -5 : 0)
        }
        .onChange(of: state) {
            if state == .hit {
                withAnimation(.linear(duration: 0.08).repeatCount(4, autoreverses: true)) {
                    shaking = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { shaking = false }
            }
        }
    }

    private var monsterBody: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                // Shadow
                Ellipse()
                    .fill(Color.black.opacity(0.15))
                    .frame(width: w * 0.6, height: h * 0.08)
                    .offset(y: h * 0.42)

                // Body blob
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [bodyColor.opacity(0.8), bodyColor, darkColor],
                            center: UnitPoint(x: 0.35, y: 0.3),
                            startRadius: 0,
                            endRadius: w * 0.35
                        )
                    )
                    .frame(width: w * 0.65, height: h * 0.65)
                    .shadow(color: darkColor.opacity(0.4), radius: 6, x: 3, y: 4)

                // Horns
                hornPair(w: w, h: h)

                // Boss crown
                if isBoss {
                    crown(w: w, h: h)
                }

                // Eyes
                monsterEyes(w: w, h: h)

                // Mouth
                monsterMouth(w: w, h: h)

                // Mystery mark (don't reveal the answer)
                Text("?")
                    .font(DesignTokens.Font.rounded(size: isBoss ? 28 : 22, weight: .bold))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.5), radius: 2, x: 1, y: 1)
                    .offset(y: h * 0.08)

                // HP bar
                if state != .defeated {
                    hpBar(w: w, h: h)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func hornPair(w: CGFloat, h: CGFloat) -> some View {
        Group {
            Triangle()
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.7, green: 0.3, blue: 0.3), Color(red: 0.5, green: 0.15, blue: 0.15)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: w * 0.08, height: h * 0.15)
                .rotationEffect(.degrees(-20))
                .offset(x: -w * 0.18, y: -h * 0.28)

            Triangle()
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.7, green: 0.3, blue: 0.3), Color(red: 0.5, green: 0.15, blue: 0.15)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: w * 0.08, height: h * 0.15)
                .rotationEffect(.degrees(20))
                .offset(x: w * 0.18, y: -h * 0.28)
        }
    }

    private func crown(w: CGFloat, h: CGFloat) -> some View {
        ZStack {
            // Crown base
            Image(systemName: "crown.fill")
                .font(.system(size: w * 0.18))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.yellow, Color(red: 1.0, green: 0.75, blue: 0.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: .yellow.opacity(0.5), radius: 4)
        }
        .offset(y: -h * 0.33)
    }

    private func monsterEyes(w: CGFloat, h: CGFloat) -> some View {
        let eyeY = -h * 0.08
        return Group {
            // Left eye
            ZStack {
                Ellipse().fill(Color.white)
                    .frame(width: w * 0.13, height: w * 0.11)
                Ellipse().fill(Color(red: 0.8, green: 0.1, blue: 0.1))
                    .frame(width: w * 0.07, height: w * 0.07)
                Circle().fill(Color.white)
                    .frame(width: w * 0.025)
                    .offset(x: -w * 0.01, y: -w * 0.01)
            }
            .offset(x: -w * 0.10, y: eyeY)

            // Right eye
            ZStack {
                Ellipse().fill(Color.white)
                    .frame(width: w * 0.13, height: w * 0.11)
                Ellipse().fill(Color(red: 0.8, green: 0.1, blue: 0.1))
                    .frame(width: w * 0.07, height: w * 0.07)
                Circle().fill(Color.white)
                    .frame(width: w * 0.025)
                    .offset(x: -w * 0.01, y: -w * 0.01)
            }
            .offset(x: w * 0.10, y: eyeY)

            // Angry eyebrows
            Capsule().fill(darkColor)
                .frame(width: w * 0.12, height: h * 0.025)
                .rotationEffect(.degrees(15))
                .offset(x: -w * 0.10, y: eyeY - h * 0.07)
            Capsule().fill(darkColor)
                .frame(width: w * 0.12, height: h * 0.025)
                .rotationEffect(.degrees(-15))
                .offset(x: w * 0.10, y: eyeY - h * 0.07)
        }
    }

    @ViewBuilder
    private func monsterMouth(w: CGFloat, h: CGFloat) -> some View {
        if state == .attacking {
            // Open angry mouth
            Ellipse()
                .fill(Color(red: 0.3, green: 0.0, blue: 0.0))
                .frame(width: w * 0.12, height: h * 0.08)
                .offset(y: h * 0.02)
        } else {
            // Jagged teeth grin
            ZStack {
                // Mouth background
                SmileMouth()
                    .fill(Color(red: 0.3, green: 0.0, blue: 0.0))
                    .frame(width: w * 0.14, height: h * 0.06)

                // Teeth
                HStack(spacing: 1) {
                    ForEach(0..<3, id: \.self) { _ in
                        Triangle()
                            .fill(Color.white)
                            .frame(width: w * 0.025, height: h * 0.025)
                    }
                }
                .offset(y: -h * 0.005)
            }
            .offset(y: h * 0.02)
        }
    }

    private func hpBar(w: CGFloat, h: CGFloat) -> some View {
        VStack(spacing: 1) {
            // HP bar background
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.black.opacity(0.3))
                    .frame(width: w * 0.45, height: 6)
                RoundedRectangle(cornerRadius: 3)
                    .fill(
                        LinearGradient(
                            colors: [Color.red, Color(red: 0.8, green: 0.2, blue: 0.0)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: w * 0.45 * CGFloat(hp) / CGFloat(max(1, maxHp)), height: 6)
            }
        }
        .offset(y: -h * 0.35)
    }
}

// Shared shapes
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

private struct SmileMouth: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY),
            control: CGPoint(x: rect.midX, y: rect.maxY)
        )
        path.closeSubpath()
        return path
    }
}

/// Mini monster icon for progress grid
struct MiniMonster: View {
    let character: String
    let isDefeated: Bool
    let isBoss: Bool
    let isCurrent: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    isDefeated
                        ? Color.green.opacity(0.15)
                        : (isCurrent ? Color.purple.opacity(0.25) : Color(.systemGray5))
                )
                .frame(width: 44, height: 44)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isCurrent ? Color.purple : Color.clear, lineWidth: 2)
                )

            if isDefeated {
                ZStack {
                    Text(character)
                        .font(DesignTokens.Font.rounded(size: isBoss ? 18 : 16, weight: .bold))
                        .foregroundStyle(Color.green)
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.green)
                        .offset(x: 14, y: -14)
                }
            } else {
                Text("?")
                    .font(DesignTokens.Font.rounded(size: isBoss ? 18 : 16, weight: .bold))
                    .foregroundStyle(isCurrent ? Color.purple : DesignTokens.Colors.onSurfaceSecondary)
            }

            if isBoss && !isDefeated {
                Image(systemName: "crown.fill")
                    .font(.system(size: 8))
                    .foregroundStyle(.yellow)
                    .offset(y: -18)
            }
        }
    }
}
