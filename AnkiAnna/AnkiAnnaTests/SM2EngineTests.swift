import XCTest
@testable import AnkiAnna

final class SM2EngineTests: XCTestCase {

    func testFirstCorrectReview() {
        // First review: correct answer
        let result = SM2Engine.calculateNext(
            quality: 5,  // perfect
            previousEase: 2.5,
            previousInterval: 0,
            repetition: 0
        )
        XCTAssertEqual(result.interval, 1)
        XCTAssertEqual(result.ease, 2.6, accuracy: 0.01)
        XCTAssertEqual(result.repetition, 1)
    }

    func testSecondCorrectReview() {
        let result = SM2Engine.calculateNext(
            quality: 4,  // correct with hesitation
            previousEase: 2.5,
            previousInterval: 1,
            repetition: 1
        )
        XCTAssertEqual(result.interval, 6)
        XCTAssertEqual(result.repetition, 2)
    }

    func testThirdCorrectReview() {
        let result = SM2Engine.calculateNext(
            quality: 4,
            previousEase: 2.5,
            previousInterval: 6,
            repetition: 2
        )
        // interval = round(6 * 2.5) = 15
        XCTAssertEqual(result.interval, 15)
        XCTAssertEqual(result.repetition, 3)
    }

    func testIncorrectReviewResetsInterval() {
        let result = SM2Engine.calculateNext(
            quality: 1,  // wrong
            previousEase: 2.5,
            previousInterval: 15,
            repetition: 3
        )
        XCTAssertEqual(result.interval, 1)
        XCTAssertEqual(result.repetition, 0)
        // ease should decrease but not below 1.3
        XCTAssertGreaterThanOrEqual(result.ease, 1.3)
    }

    func testEaseNeverBelowMinimum() {
        // Repeatedly wrong answers
        var ease = 2.5
        for _ in 0..<10 {
            let result = SM2Engine.calculateNext(
                quality: 0,
                previousEase: ease,
                previousInterval: 1,
                repetition: 0
            )
            ease = result.ease
        }
        XCTAssertGreaterThanOrEqual(ease, 1.3)
    }

    func testQualityToResult() {
        // quality >= 3 is correct
        XCTAssertTrue(SM2Engine.isCorrect(quality: 3))
        XCTAssertTrue(SM2Engine.isCorrect(quality: 4))
        XCTAssertTrue(SM2Engine.isCorrect(quality: 5))
        XCTAssertFalse(SM2Engine.isCorrect(quality: 2))
        XCTAssertFalse(SM2Engine.isCorrect(quality: 1))
        XCTAssertFalse(SM2Engine.isCorrect(quality: 0))
    }

    func testSelectDueCards() {
        // Cards with nextReviewDate <= now should be selected
        let now = Date()
        let dueCard = SM2Engine.CardSchedule(
            cardId: UUID(),
            nextReviewDate: now.addingTimeInterval(-3600), // 1 hour ago
            ease: 2.5,
            interval: 1,
            repetition: 1
        )
        let futureCard = SM2Engine.CardSchedule(
            cardId: UUID(),
            nextReviewDate: now.addingTimeInterval(86400), // tomorrow
            ease: 2.5,
            interval: 6,
            repetition: 2
        )
        let newCard = SM2Engine.CardSchedule(
            cardId: UUID(),
            nextReviewDate: nil, // never reviewed
            ease: 2.5,
            interval: 0,
            repetition: 0
        )

        let due = SM2Engine.selectDueCards(
            from: [dueCard, futureCard, newCard],
            limit: 15,
            now: now
        )

        // Due card and new card should be included, future card excluded
        XCTAssertEqual(due.count, 2)
        XCTAssertTrue(due.contains(where: { $0.cardId == dueCard.cardId }))
        XCTAssertTrue(due.contains(where: { $0.cardId == newCard.cardId }))
        XCTAssertFalse(due.contains(where: { $0.cardId == futureCard.cardId }))
    }
}
