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
}
