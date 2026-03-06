import Foundation
import SwiftData

enum CardType: String, Codable {
    case chineseWriting
    case englishSpelling
}

enum CardSource: String, Codable {
    case manual
    case aiGenerated
    case textbook
}

@Model
final class Card {
    var id: UUID
    var type: CardType
    var answer: String
    @Relationship(deleteRule: .cascade) var contexts: [CardContext]
    var audioText: String
    var hint: String?
    var tags: [String]
    var source: CardSource
    var createdAt: Date

    var canDeleteContext: Bool {
        contexts.count > 1
    }

    init(
        type: CardType,
        answer: String,
        audioText: String,
        hint: String? = nil,
        tags: [String] = [],
        source: CardSource = .manual
    ) {
        self.id = UUID()
        self.type = type
        self.answer = answer
        self.contexts = []
        self.audioText = audioText
        self.hint = hint
        self.tags = tags
        self.source = source
        self.createdAt = Date()
    }
}
