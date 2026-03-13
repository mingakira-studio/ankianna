import SwiftUI
import SpriteKit

// MARK: - Confetti View (SpriteKit Particle System)

struct ConfettiView: View {
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        if reduceMotion {
            Image(systemName: "star.fill")
                .font(DesignTokens.Font.promptText)
                .foregroundStyle(.yellow)
        } else {
            SpriteView(scene: ConfettiScene(), transition: nil, isPaused: false, preferredFramesPerSecond: 60)
                .allowsHitTesting(false)
                .ignoresSafeArea()
        }
    }
}

private class ConfettiScene: SKScene {
    override func didMove(to view: SKView) {
        size = view.bounds.size
        scaleMode = .resizeFill
        backgroundColor = .clear
        view.allowsTransparency = true

        let colors: [UIColor] = [.systemYellow, .systemOrange, .systemPink, .systemPurple, .systemBlue]

        for color in colors {
            let emitter = makeEmitter(color: color)
            emitter.position = CGPoint(x: size.width / 2, y: size.height)
            addChild(emitter)
        }

        // Auto-remove scene after particles finish
        run(.sequence([
            .wait(forDuration: 2.5),
            .run { [weak self] in
                self?.children.forEach { ($0 as? SKEmitterNode)?.particleBirthRate = 0 }
            }
        ]))
    }

    private func makeEmitter(color: UIColor) -> SKEmitterNode {
        let emitter = SKEmitterNode()

        // Particle appearance
        emitter.particleTexture = SKTexture(imageNamed: "spark") // Falls back to default if missing
        if emitter.particleTexture == nil {
            // Programmatic circle texture as fallback
            emitter.particleTexture = circleTexture(size: 12)
        }
        emitter.particleColor = color
        emitter.particleColorBlendFactor = 1.0
        emitter.particleSize = CGSize(width: 10, height: 10)
        emitter.particleScaleRange = 0.8

        // Emission
        emitter.particleBirthRate = 25
        emitter.numParticlesToEmit = 30
        emitter.particleLifetime = 2.0
        emitter.particleLifetimeRange = 0.5

        // Movement — burst downward with spread
        emitter.emissionAngle = -.pi / 2  // downward
        emitter.emissionAngleRange = .pi / 3
        emitter.particleSpeed = 300
        emitter.particleSpeedRange = 150
        emitter.yAcceleration = -200  // gravity

        // Spread across width
        emitter.particlePositionRange = CGVector(dx: size.width * 0.8, dy: 0)

        // Rotation
        emitter.particleRotation = 0
        emitter.particleRotationRange = .pi * 2
        emitter.particleRotationSpeed = 2

        // Fade out
        emitter.particleAlpha = 1.0
        emitter.particleAlphaSpeed = -0.5

        return emitter
    }

    private func circleTexture(size: CGFloat) -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        let image = renderer.image { ctx in
            UIColor.white.setFill()
            ctx.cgContext.fillEllipse(in: CGRect(x: 0, y: 0, width: size, height: size))
        }
        return SKTexture(image: image)
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
