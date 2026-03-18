import Foundation
import SwiftData

enum ContextType: String, Codable {
    case phrase
    case sentence
}

@Model
final class CardContext {
    var id: UUID
    var type: ContextType
    var text: String
    var fullText: String
    var source: CardSource

    init(type: ContextType, text: String, fullText: String, source: CardSource = .manual) {
        self.id = UUID()
        self.type = type
        self.text = text
        self.fullText = fullText
        self.source = source
    }

    /// Returns display text with only the target answer masked.
    /// Fixes AI-generated contexts where entire words were masked instead of just the target character.
    func displayText(answer: String) -> String {
        guard !fullText.isEmpty, !answer.isEmpty else { return text }
        // If fullText contains the answer, re-derive masking from fullText
        if let range = fullText.range(of: answer) {
            return fullText.replacingCharacters(in: range, with: "___")
        }
        return text
    }
}
