import XCTest
import SwiftData
@testable import AnkiAnna

/// Tests for subtask 3: Card and context editing
@MainActor
final class CardEditTests: XCTestCase {

    var container: ModelContainer!

    override func setUp() {
        super.setUp()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try! ModelContainer(
            for: Card.self, ReviewRecord.self, DailySession.self, UserProfile.self,
            configurations: config
        )
    }

    // MARK: - Edit card answer

    func testUpdateCardAnswer() throws {
        let context = container.mainContext
        let card = Card(type: .chineseWriting, answer: "龙", audioText: "龙")
        context.insert(card)
        try context.save()

        card.answer = "凤"
        card.audioText = "凤"
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Card>())
        XCTAssertEqual(fetched[0].answer, "凤")
        XCTAssertEqual(fetched[0].audioText, "凤")
    }

    // MARK: - Add context to existing card

    func testAddContextToCard() throws {
        let context = container.mainContext
        let card = Card(type: .chineseWriting, answer: "龙", audioText: "龙")
        let ctx1 = CardContext(type: .phrase, text: "恐___", fullText: "恐龙")
        card.contexts = [ctx1]
        context.insert(card)
        try context.save()

        XCTAssertEqual(card.contexts.count, 1)

        let ctx2 = CardContext(type: .sentence, text: "___飞凤舞", fullText: "龙飞凤舞")
        card.contexts.append(ctx2)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Card>())
        XCTAssertEqual(fetched[0].contexts.count, 2)
    }

    // MARK: - Remove context from card

    func testRemoveContextFromCard() throws {
        let context = container.mainContext
        let card = Card(type: .chineseWriting, answer: "龙", audioText: "龙")
        let ctx1 = CardContext(type: .phrase, text: "恐___", fullText: "恐龙")
        let ctx2 = CardContext(type: .phrase, text: "___飞凤舞", fullText: "龙飞凤舞")
        card.contexts = [ctx1, ctx2]
        context.insert(card)
        try context.save()

        XCTAssertEqual(card.contexts.count, 2)

        card.contexts.removeAll { $0.id == ctx1.id }
        context.delete(ctx1)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Card>())
        XCTAssertEqual(fetched[0].contexts.count, 1)
        XCTAssertEqual(fetched[0].contexts[0].fullText, "龙飞凤舞")
    }

    // MARK: - Edit context text

    func testUpdateContextText() throws {
        let context = container.mainContext
        let card = Card(type: .chineseWriting, answer: "龙", audioText: "龙")
        let ctx = CardContext(type: .phrase, text: "恐___", fullText: "恐龙")
        card.contexts = [ctx]
        context.insert(card)
        try context.save()

        ctx.text = "___王"
        ctx.fullText = "龙王"
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Card>())
        XCTAssertEqual(fetched[0].contexts[0].text, "___王")
        XCTAssertEqual(fetched[0].contexts[0].fullText, "龙王")
    }

    // MARK: - Edit context type

    func testUpdateContextType() throws {
        let context = container.mainContext
        let card = Card(type: .chineseWriting, answer: "龙", audioText: "龙")
        let ctx = CardContext(type: .phrase, text: "恐___", fullText: "恐龙")
        card.contexts = [ctx]
        context.insert(card)
        try context.save()

        ctx.type = .sentence
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Card>())
        XCTAssertEqual(fetched[0].contexts[0].type, .sentence)
    }

    // MARK: - Cannot delete last context (guard)

    func testCardMustHaveAtLeastOneContext() throws {
        // This tests that our editing logic prevents removing all contexts
        let card = Card(type: .chineseWriting, answer: "龙", audioText: "龙")
        let ctx = CardContext(type: .phrase, text: "恐___", fullText: "恐龙")
        card.contexts = [ctx]

        // canDeleteContext should return false when only 1 context remains
        XCTAssertFalse(card.canDeleteContext)
    }
}
