import SwiftUI
import PencilKit

struct WritingCanvasView: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    var isErasing: Bool = false

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.drawing = drawing
        canvas.tool = isErasing ? PKEraserTool(.vector) : PKInkingTool(.pen, color: .black, width: 5)
        canvas.drawingPolicy = .anyInput
        canvas.backgroundColor = .clear
        canvas.delegate = context.coordinator
        return canvas
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // Switch tool
        if isErasing {
            if !(uiView.tool is PKEraserTool) {
                uiView.tool = PKEraserTool(.vector)
            }
        } else {
            if !(uiView.tool is PKInkingTool) {
                uiView.tool = PKInkingTool(.pen, color: .black, width: 5)
            }
        }

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

/// Writing canvas with eraser toggle and clear button
struct WritingCanvasWithTools: View {
    @Binding var drawing: PKDrawing
    @State private var isErasing = false

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            WritingCanvasView(drawing: $drawing, isErasing: isErasing)

            HStack(spacing: DesignTokens.Spacing.md) {
                Button {
                    isErasing = false
                } label: {
                    Label("画笔", systemImage: "pencil.tip")
                        .font(DesignTokens.Font.caption)
                }
                .buttonStyle(.bordered)
                .tint(isErasing ? .secondary : DesignTokens.Colors.primary)
                .accessibilityIdentifier("penToolButton")

                Button {
                    isErasing = true
                } label: {
                    Label("橡皮擦", systemImage: "eraser")
                        .font(DesignTokens.Font.caption)
                }
                .buttonStyle(.bordered)
                .tint(isErasing ? DesignTokens.Colors.primary : .secondary)
                .accessibilityIdentifier("eraserToolButton")

                Spacer()

                Button {
                    drawing = PKDrawing()
                    isErasing = false
                } label: {
                    Label("清除", systemImage: "trash")
                        .font(DesignTokens.Font.caption)
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .accessibilityIdentifier("clearCanvasButton")
            }
            .padding(.horizontal)
        }
    }
}
