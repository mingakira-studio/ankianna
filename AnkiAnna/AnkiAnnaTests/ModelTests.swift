import XCTest
import SwiftData
@testable import AnkiAnna

@MainActor
final class ModelTests: XCTestCase {

    var container: ModelContainer!

    override func setUp() {
        super.setUp()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try! ModelContainer(
            for: Card.self, ReviewRecord.self, DailySession.self, UserProfile.self,
            configurations: config
        )
    }

    func testCreateChineseCard() throws {
        let context = container.mainContext
        let card = Card(
            type: .chineseWriting,
            answer: "龙",
            audioText: "龙"
        )
        let ctx1 = CardContext(type: .phrase, text: "___飞凤舞", fullText: "龙飞凤舞")
        let ctx2 = CardContext(type: .phrase, text: "恐___", fullText: "恐龙")
        card.contexts = [ctx1, ctx2]
        card.tags = ["二年级", "动物"]

        context.insert(card)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Card>())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched[0].answer, "龙")
        XCTAssertEqual(fetched[0].type, .chineseWriting)
        XCTAssertEqual(fetched[0].contexts.count, 2)
    }

    func testCreateEnglishCard() throws {
        let context = container.mainContext
        let card = Card(
            type: .englishSpelling,
            answer: "dragon",
            audioText: "dragon"
        )
        let ctx = CardContext(type: .sentence, text: "The ___ flies in the sky.", fullText: "The dragon flies in the sky.")
        card.contexts = [ctx]

        context.insert(card)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Card>())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched[0].answer, "dragon")
        XCTAssertEqual(fetched[0].type, .englishSpelling)
    }

    func testReviewRecord() throws {
        let context = container.mainContext
        let card = Card(type: .chineseWriting, answer: "龙", audioText: "龙")
        context.insert(card)

        let record = ReviewRecord(
            card: card,
            result: .correct,
            ease: 2.5,
            interval: 1,
            nextReviewDate: Date().addingTimeInterval(86400)
        )
        context.insert(record)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<ReviewRecord>())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched[0].result, .correct)
    }

    func testDailySession() throws {
        let context = container.mainContext
        let session = DailySession(date: Date(), targetCount: 15)
        context.insert(session)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<DailySession>())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched[0].targetCount, 15)
        XCTAssertEqual(fetched[0].completedCount, 0)
    }

    func testUserProfile() throws {
        let context = container.mainContext
        let profile = UserProfile(name: "Anna", dailyGoal: 15)
        context.insert(profile)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<UserProfile>())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched[0].name, "Anna")
        XCTAssertEqual(fetched[0].totalPoints, 0)
    }
}
