import SwiftUI

// MARK: - Confetti View

struct ConfettiView: View {
    @State private var animate = false

    private let emojis = ["⭐", "🌟", "✨", "🎉", "💫"]
    private let pieces = 12

    var body: some View {
        ZStack {
            ForEach(0..<pieces, id: \.self) { index in
                let emoji = emojis[index % emojis.count]
                let xOffset = CGFloat.random(in: -160...160)
                let yOffset = CGFloat.random(in: 40...280)
                let rotation = Double.random(in: -180...180)

                Text(emoji)
                    .font(.system(size: CGFloat.random(in: 20...36)))
                    .offset(
                        x: animate ? xOffset : 0,
                        y: animate ? yOffset : -20
                    )
                    .rotationEffect(.degrees(animate ? rotation : 0))
                    .opacity(animate ? 0 : 1)
                    .scaleEffect(animate ? 0.6 : 0.2)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.5)) {
                animate = true
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Combo Fire View

struct ComboFireView: View {
    let combo: Int
    @State private var animate = false

    private var fireCount: Int {
        min(combo, 6)
    }

    private var scale: CGFloat {
        1.0 + CGFloat(min(combo, 10)) * 0.15
    }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<fireCount, id: \.self) { index in
                Text("🔥")
                    .font(.system(size: 28))
                    .offset(y: animate ? -12 : 0)
                    .opacity(animate ? 0.7 : 1.0)
                    .animation(
                        .easeInOut(duration: 0.8)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.1),
                        value: animate
                    )
            }
        }
        .scaleEffect(scale)
        .onAppear {
            animate = true
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Encouragement View

struct EncouragementView: View {
    @State private var animate = false

    var body: some View {
        Text("加油！💪")
            .font(.system(size: 24, weight: .semibold))
            .foregroundStyle(.orange)
            .scaleEffect(animate ? 1.05 : 0.95)
            .animation(
                .easeInOut(duration: 0.6)
                    .repeatCount(3, autoreverses: true),
                value: animate
            )
            .onAppear {
                animate = true
            }
    }
}
