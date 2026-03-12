import SwiftUI

// MARK: - Confetti View

struct ConfettiView: View {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State private var animate = false

    private let symbols = ["star.fill", "sparkle", "star.circle.fill", "heart.fill", "moon.stars.fill"]
    private let colors: [Color] = [.yellow, .orange, .pink, .purple, .blue]
    private let pieces = 12

    var body: some View {
        ZStack {
            if reduceMotion {
                // Static star for reduced motion
                Image(systemName: "star.fill")
                    .font(DesignTokens.Font.promptText)
                    .foregroundStyle(.yellow)
            } else {
                ForEach(0..<pieces, id: \.self) { index in
                    let symbol = symbols[index % symbols.count]
                    let color = colors[index % colors.count]
                    let xOffset = CGFloat.random(in: -160...160)
                    let yOffset = CGFloat.random(in: 40...280)
                    let rotation = Double.random(in: -180...180)

                    Image(systemName: symbol)
                        .font(.system(size: CGFloat.random(in: 20...36)))
                        .foregroundStyle(color)
                        .offset(
                            x: animate ? xOffset : 0,
                            y: animate ? yOffset : -20
                        )
                        .rotationEffect(.degrees(animate ? rotation : 0))
                        .opacity(animate ? 0 : 1)
                        .scaleEffect(animate ? 0.6 : 0.2)
                }
            }
        }
        .onAppear {
            if !reduceMotion {
                withAnimation(.easeOut(duration: 1.5)) {
                    animate = true
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Combo Fire View

struct ComboFireView: View {
    let combo: Int
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State private var animate = false

    private var fireCount: Int {
        min(combo, 6)
    }

    private var scale: CGFloat {
        1.0 + CGFloat(min(combo, 10)) * 0.15
    }

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.xs) {
            ForEach(0..<fireCount, id: \.self) { index in
                Image(systemName: "flame.fill")
                    .font(DesignTokens.Font.points)
                    .foregroundStyle(.orange.gradient)
                    .offset(y: reduceMotion ? 0 : (animate ? -12 : 0))
                    .opacity(reduceMotion ? 1.0 : (animate ? 0.7 : 1.0))
                    .animation(
                        reduceMotion ? nil :
                            .easeInOut(duration: 0.8)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.1),
                        value: animate
                    )
            }
        }
        .scaleEffect(scale)
        .onAppear {
            if !reduceMotion {
                animate = true
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Encouragement View

struct EncouragementView: View {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State private var animate = false

    var body: some View {
        Label("加油！", systemImage: "hand.thumbsup.fill")
            .font(DesignTokens.Font.encouragement)
            .foregroundStyle(DesignTokens.Colors.accent)
            .scaleEffect(reduceMotion ? 1.0 : (animate ? 1.05 : 0.95))
            .animation(
                reduceMotion ? nil :
                    .easeInOut(duration: 0.6)
                        .repeatCount(3, autoreverses: true),
                value: animate
            )
            .onAppear {
                if !reduceMotion {
                    animate = true
                }
            }
    }
}
