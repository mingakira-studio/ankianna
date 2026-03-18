import SwiftUI
import SceneKit

/// Renders the 3D dinosaur USDZ model via SceneKit, with state-driven animation.
struct DinoSceneView: UIViewRepresentable {
    let state: MascotState

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.backgroundColor = .clear
        scnView.autoenablesDefaultLighting = true
        scnView.allowsCameraControl = false
        scnView.isUserInteractionEnabled = false
        scnView.antialiasingMode = .multisampling4X

        // Load USDZ model
        guard let url = Bundle.main.url(forResource: "dino", withExtension: "usdz"),
              let scene = try? SCNScene(url: url) else {
            return scnView
        }
        scnView.scene = scene

        // Camera setup — side view
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.fieldOfView = 35
        cameraNode.position = SCNVector3(0, 0.5, 1.5)
        cameraNode.look(at: SCNVector3(0, 0.3, 0))

        // Rotate model to show side profile (facing right)
        // Find the main mesh node and rotate it
        scene.rootNode.childNodes.first { $0.name == "scene" || !$0.childNodes.isEmpty }?
            .eulerAngles = SCNVector3(0, -Float.pi / 2, 0)
        scene.rootNode.addChildNode(cameraNode)

        // Ambient light for softer look
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.color = UIColor(white: 0.5, alpha: 1.0)
        scene.rootNode.addChildNode(ambientLight)

        // Store reference for updates
        context.coordinator.scnView = scnView
        context.coordinator.scene = scene

        // Start idle animation
        applyState(state, to: scene, coordinator: context.coordinator)

        return scnView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        guard let scene = context.coordinator.scene else { return }
        applyState(state, to: scene, coordinator: context.coordinator)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    private func applyState(_ state: MascotState, to scene: SCNScene, coordinator: Coordinator) {
        let rootNode = scene.rootNode

        // Remove previous programmatic actions
        rootNode.removeAllActions()

        // Control built-in animation speed
        scene.isPaused = false

        switch state {
        case .idle:
            // Gentle breathing/bob animation
            rootNode.animationKeys.forEach { key in
                if let player = rootNode.animationPlayer(forKey: key) {
                    player.speed = 0.6
                    player.play()
                }
            }
            // Subtle floating bob
            let bob = SCNAction.sequence([
                SCNAction.moveBy(x: 0, y: 0.05, z: 0, duration: 1.0),
                SCNAction.moveBy(x: 0, y: -0.05, z: 0, duration: 1.0),
            ])
            rootNode.runAction(SCNAction.repeatForever(bob), forKey: "bob")

        case .thinking:
            // Slow animation + slight tilt
            rootNode.animationKeys.forEach { key in
                if let player = rootNode.animationPlayer(forKey: key) {
                    player.speed = 0.3
                    player.play()
                }
            }
            let tilt = SCNAction.sequence([
                SCNAction.rotateBy(x: 0, y: 0, z: 0.1, duration: 1.5),
                SCNAction.rotateBy(x: 0, y: 0, z: -0.1, duration: 1.5),
            ])
            rootNode.runAction(SCNAction.repeatForever(tilt), forKey: "tilt")

        case .happy:
            // Fast animation + jump
            rootNode.animationKeys.forEach { key in
                if let player = rootNode.animationPlayer(forKey: key) {
                    player.speed = 1.5
                    player.play()
                }
            }
            let jump = SCNAction.sequence([
                SCNAction.moveBy(x: 0, y: 0.15, z: 0, duration: 0.2),
                SCNAction.moveBy(x: 0, y: -0.15, z: 0, duration: 0.2),
                SCNAction.wait(duration: 0.6),
            ])
            rootNode.runAction(SCNAction.repeatForever(jump), forKey: "jump")

        case .encourage:
            // Slow, shake head side to side
            rootNode.animationKeys.forEach { key in
                if let player = rootNode.animationPlayer(forKey: key) {
                    player.speed = 0.4
                    player.play()
                }
            }
            let shake = SCNAction.sequence([
                SCNAction.rotateBy(x: 0, y: 0.2, z: 0, duration: 0.3),
                SCNAction.rotateBy(x: 0, y: -0.4, z: 0, duration: 0.6),
                SCNAction.rotateBy(x: 0, y: 0.2, z: 0, duration: 0.3),
            ])
            rootNode.runAction(SCNAction.repeatForever(shake), forKey: "shake")

        case .celebrate:
            // Fast animation + spin
            rootNode.animationKeys.forEach { key in
                if let player = rootNode.animationPlayer(forKey: key) {
                    player.speed = 2.0
                    player.play()
                }
            }
            let celebrate = SCNAction.sequence([
                SCNAction.moveBy(x: 0, y: 0.2, z: 0, duration: 0.15),
                SCNAction.rotateBy(x: 0, y: .pi * 2, z: 0, duration: 0.5),
                SCNAction.moveBy(x: 0, y: -0.2, z: 0, duration: 0.15),
                SCNAction.wait(duration: 0.5),
            ])
            rootNode.runAction(SCNAction.repeatForever(celebrate), forKey: "celebrate")
        }
    }

    class Coordinator {
        var scnView: SCNView?
        var scene: SCNScene?
    }
}
