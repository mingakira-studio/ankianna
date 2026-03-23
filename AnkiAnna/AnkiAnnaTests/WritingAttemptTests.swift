import XCTest
import SwiftData
@testable import AnkiAnna

@MainActor
final class WritingAttemptTests: XCTestCase {

    // MARK: - Initialization

    func testInitDefaultValues() {
        let attempt = WritingAttempt(
            character: "龙",
            correct: true,
            writingDuration: 3.5,
            gameMode: "quick"
        )
        XCTAssertEqual(attempt.character, "龙")
        XCTAssertTrue(attempt.correct)
        XCTAssertEqual(attempt.writingDuration, 3.5, accuracy: 0.001)
        XCTAssertEqual(attempt.gameMode, "quick")
        XCTAssertEqual(attempt.sessionId, "")
        XCTAssertNotNil(attempt.id)
        XCTAssertNotNil(attempt.timestamp)
    }

    func testInitWithSessionId() {
        let attempt = WritingAttempt(
            character: "春",
            correct: false,
            writingDuration: 8.2,
            gameMode: "timeAttack",
            sessionId: "session-abc-123"
        )
        XCTAssertEqual(attempt.character, "春")
        XCTAssertFalse(attempt.correct)
        XCTAssertEqual(attempt.writingDuration, 8.2, accuracy: 0.001)
        XCTAssertEqual(attempt.gameMode, "timeAttack")
        XCTAssertEqual(attempt.sessionId, "session-abc-123")
    }

    func testUniqueIds() {
        let a = WritingAttempt(character: "龙", correct: true, writingDuration: 1.0, gameMode: "quick")
        let b = WritingAttempt(character: "龙", correct: true, writingDuration: 1.0, gameMode: "quick")
        XCTAssertNotEqual(a.id, b.id, "Each attempt should have a unique UUID")
    }

    func testTimestampIsRecent() {
        let before = Date()
        let attempt = WritingAttempt(character: "花", correct: true, writingDuration: 2.0, gameMode: "survival")
        let after = Date()
        XCTAssertGreaterThanOrEqual(attempt.timestamp, before)
        XCTAssertLessThanOrEqual(attempt.timestamp, after)
    }

    // MARK: - Game modes

    func testAllGameModes() {
        let modes = ["quick", "timeAttack", "survival", "levels", "practice"]
        for mode in modes {
            let attempt = WritingAttempt(character: "字", correct: true, writingDuration: 1.0, gameMode: mode)
            XCTAssertEqual(attempt.gameMode, mode)
        }
    }

    // MARK: - Edge cases

    func testZeroDuration() {
        let attempt = WritingAttempt(character: "一", correct: true, writingDuration: 0.0, gameMode: "quick")
        XCTAssertEqual(attempt.writingDuration, 0.0, accuracy: 0.001)
    }

    func testLargeDuration() {
        let attempt = WritingAttempt(character: "龟", correct: false, writingDuration: 120.5, gameMode: "levels")
        XCTAssertEqual(attempt.writingDuration, 120.5, accuracy: 0.001)
    }

    func testEmptyCharacter() {
        let attempt = WritingAttempt(character: "", correct: false, writingDuration: 1.0, gameMode: "quick")
        XCTAssertEqual(attempt.character, "")
    }

    // MARK: - SwiftData Persistence

    func testPersistence() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Card.self, ReviewRecord.self, DailySession.self,
            UserProfile.self, CharacterStats.self, WritingAttempt.self,
            configurations: config
        )
        let context = container.mainContext

        let attempt = WritingAttempt(
            character: "龙",
            correct: true,
            writingDuration: 4.2,
            gameMode: "quick",
            sessionId: "test-session"
        )
        context.insert(attempt)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<WritingAttempt>())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched[0].character, "龙")
        XCTAssertTrue(fetched[0].correct)
        XCTAssertEqual(fetched[0].writingDuration, 4.2, accuracy: 0.001)
        XCTAssertEqual(fetched[0].gameMode, "quick")
        XCTAssertEqual(fetched[0].sessionId, "test-session")
    }

    func testPersistMultipleAttempts() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Card.self, ReviewRecord.self, DailySession.self,
            UserProfile.self, CharacterStats.self, WritingAttempt.self,
            configurations: config
        )
        let context = container.mainContext

        let sessionId = "batch-session"
        let attempts = [
            WritingAttempt(character: "春", correct: true, writingDuration: 2.1, gameMode: "timeAttack", sessionId: sessionId),
            WritingAttempt(character: "夏", correct: false, writingDuration: 5.3, gameMode: "timeAttack", sessionId: sessionId),
            WritingAttempt(character: "秋", correct: true, writingDuration: 3.0, gameMode: "timeAttack", sessionId: sessionId),
        ]
        for a in attempts { context.insert(a) }
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<WritingAttempt>())
        XCTAssertEqual(fetched.count, 3)

        let correctCount = fetched.filter { $0.correct }.count
        XCTAssertEqual(correctCount, 2)

        let sessionFiltered = fetched.filter { $0.sessionId == sessionId }
        XCTAssertEqual(sessionFiltered.count, 3)
    }
}
