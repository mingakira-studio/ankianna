import XCTest
import SwiftData
@testable import AnkiAnna

@MainActor
final class IntegrationTests: XCTestCase {

    var container: ModelContainer!

    override func setUp() {
        super.setUp()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try! ModelContainer(
            for: Card.self, ReviewRecord.self, DailySession.self, UserProfile.self, CharacterStats.self,
            configurations: config
        )
    }

    func testFullReviewCycle() throws {
        let context = container.mainContext

        // Create card
        let card = Card(type: .chineseWriting, answer: "龙", audioText: "龙")
        card.contexts = [CardContext(type: .phrase, text: "___飞凤舞", fullText: "龙飞凤舞")]
        context.insert(card)

        // Create profile
        let profile = UserProfile(name: "Anna", dailyGoal: 15)
        context.insert(profile)

        // Simulate correct answer
        let sm2Result = SM2Engine.calculateNext(quality: 5, previousEase: 2.5, previousInterval: 0, repetition: 0)
        let record = ReviewRecord(
            card: card,
            result: .correct,
            ease: sm2Result.ease,
            interval: sm2Result.interval,
            repetition: sm2Result.repetition,
            nextReviewDate: sm2Result.nextReviewDate
        )
        context.insert(record)

        // Award points
        let points = PointsService.pointsForAnswer(correct: true, combo: 0)
        profile.totalPoints += points

        try context.save()

        XCTAssertEqual(profile.totalPoints, 10)
        XCTAssertEqual(record.interval, 1)

        let records = try context.fetch(FetchDescriptor<ReviewRecord>())
        XCTAssertEqual(records.count, 1)
    }
}
