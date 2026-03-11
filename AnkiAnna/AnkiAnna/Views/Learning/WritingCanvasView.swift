import SwiftUI
import PencilKit

struct WritingCanvasView: UIViewRepresentable {
    @Binding var drawing: PKDrawing

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.drawing = drawing
        canvas.tool = PKInkingTool(.pen, color: .black, width: 5)
        canvas.drawingPolicy = .anyInput
        canvas.backgroundColor = .clear
        canvas.delegate = context.coordinator
        return canvas
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // Only sync when programmatically clearing (binding is empty but canvas is not)
        if drawing.strokes.isEmpty && !uiView.drawing.strokes.isEmpty {
            context.coordinator.ignoreNextChange = true
            uiView.drawing = PKDrawing()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(drawing: $drawing)
    }

    class Coordinator: NSObject, PKCanvasViewDelegate {
        @Binding var drawing: PKDrawing
        var ignoreNextChange = false

        init(drawing: Binding<PKDrawing>) {
            _drawing = drawing
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            if ignoreNextChange {
                ignoreNextChange = false
                return
            }
            drawing = canvasView.drawing
        }
    }
}
