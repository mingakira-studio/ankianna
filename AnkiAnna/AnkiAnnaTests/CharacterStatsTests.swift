import XCTest
import SwiftData
@testable import AnkiAnna

@MainActor
final class CharacterStatsTests: XCTestCase {

    func testMasteryLevelRawValues() {
        XCTAssertEqual(MasteryLevel.new.rawValue, "new")
        XCTAssertEqual(MasteryLevel.learning.rawValue, "learning")
        XCTAssertEqual(MasteryLevel.difficult.rawValue, "difficult")
        XCTAssertEqual(MasteryLevel.mastered.rawValue, "mastered")
    }

    func testInitialValues() {
        let stats = CharacterStats(
            character: "春", grade: 1, semester: "upper",
            lesson: 1, lessonTitle: "春夏秋冬", words: ["春天", "春风"]
        )
        XCTAssertEqual(stats.character, "春")
        XCTAssertEqual(stats.grade, 1)
        XCTAssertEqual(stats.semester, "upper")
        XCTAssertEqual(stats.lesson, 1)
        XCTAssertEqual(stats.lessonTitle, "春夏秋冬")
        XCTAssertEqual(stats.words, ["春天", "春风"])
        XCTAssertEqual(stats.masteryLevel, .new)
        XCTAssertEqual(stats.practiceCount, 0)
        XCTAssertEqual(stats.correctCount, 0)
        XCTAssertEqual(stats.errorCount, 0)
        XCTAssertNil(stats.lastPracticed)
        XCTAssertEqual(stats.ease, 2.5)
        XCTAssertEqual(stats.interval, 0)
        XCTAssertEqual(stats.repetition, 0)
        XCTAssertNil(stats.nextReviewDate)
    }

    func testComputedErrorRateZeroWhenNoPractice() {
        let stats = CharacterStats(
            character: "春", grade: 1, semester: "upper",
            lesson: 1, lessonTitle: "春夏秋冬", words: []
        )
        XCTAssertEqual(stats.errorRate, 0)
    }

    func testComputedErrorRate() {
        let stats = CharacterStats(
            character: "春", grade: 1, semester: "upper",
            lesson: 1, lessonTitle: "春夏秋冬", words: []
        )
        stats.practiceCount = 10
        stats.errorCount = 3
        XCTAssertEqual(stats.errorRate, 0.3, accuracy: 0.001)
    }

    // MARK: - Mastery state transitions

    func testMarkMastered() {
        let stats = CharacterStats(
            character: "春", grade: 1, semester: "upper",
            lesson: 1, lessonTitle: "春夏秋冬", words: []
        )
        stats.masteryLevel = .learning
        stats.markMastered()
        XCTAssertEqual(stats.masteryLevel, .mastered)
    }

    func testMarkDifficult() {
        let stats = CharacterStats(
            character: "春", grade: 1, semester: "upper",
            lesson: 1, lessonTitle: "春夏秋冬", words: []
        )
        stats.masteryLevel = .learning
        stats.markDifficult()
        XCTAssertEqual(stats.masteryLevel, .difficult)
    }

    func testMarkLearningFromDifficult() {
        let stats = CharacterStats(
            character: "春", grade: 1, semester: "upper",
            lesson: 1, lessonTitle: "春夏秋冬", words: []
        )
        stats.masteryLevel = .difficult
        stats.markLearning()
        XCTAssertEqual(stats.masteryLevel, .learning)
    }

    // MARK: - recordReview

    func testRecordReviewCorrect() {
        let stats = CharacterStats(
            character: "春", grade: 1, semester: "upper",
            lesson: 1, lessonTitle: "春夏秋冬", words: []
        )
        let output = SM2Engine.calculateNext(
            quality: 4, previousEase: 2.5, previousInterval: 0, repetition: 0
        )
        stats.recordReview(correct: true, reviewOutput: output)

        XCTAssertEqual(stats.practiceCount, 1)
        XCTAssertEqual(stats.correctCount, 1)
        XCTAssertEqual(stats.errorCount, 0)
        XCTAssertNotNil(stats.lastPracticed)
        XCTAssertEqual(stats.repetition, 1)
        XCTAssertEqual(stats.interval, 1)
    }

    func testRecordReviewWrong() {
        let stats = CharacterStats(
            character: "春", grade: 1, semester: "upper",
            lesson: 1, lessonTitle: "春夏秋冬", words: []
        )
        let output = SM2Engine.calculateNext(
            quality: 1, previousEase: 2.5, previousInterval: 0, repetition: 0
        )
        stats.recordReview(correct: false, reviewOutput: output)

        XCTAssertEqual(stats.practiceCount, 1)
        XCTAssertEqual(stats.correctCount, 0)
        XCTAssertEqual(stats.errorCount, 1)
        XCTAssertEqual(stats.repetition, 0)
    }

    func testRecordReviewDoesNotChangeMasteryLevel() {
        let stats = CharacterStats(
            character: "春", grade: 1, semester: "upper",
            lesson: 1, lessonTitle: "春夏秋冬", words: []
        )
        // masteryLevel should remain .new after recordReview
        let output = SM2Engine.calculateNext(
            quality: 4, previousEase: 2.5, previousInterval: 0, repetition: 0
        )
        stats.recordReview(correct: true, reviewOutput: output)
        XCTAssertEqual(stats.masteryLevel, .new, "recordReview should not auto-update masteryLevel")
    }

    // MARK: - resetMastery

    func testResetMastery() {
        let stats = CharacterStats(
            character: "春", grade: 1, semester: "upper",
            lesson: 1, lessonTitle: "春夏秋冬", words: []
        )
        stats.masteryLevel = .mastered
        stats.ease = 3.0
        stats.interval = 21
        stats.repetition = 3

        stats.resetMastery()
        XCTAssertEqual(stats.masteryLevel, .learning)
        XCTAssertEqual(stats.ease, 2.5)
        XCTAssertEqual(stats.interval, 0)
        XCTAssertEqual(stats.repetition, 0)
        XCTAssertNil(stats.nextReviewDate)
    }

    // MARK: - Persistence

    func testPersistence() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Card.self, ReviewRecord.self, DailySession.self,
            UserProfile.self, CharacterStats.self,
            configurations: config
        )
        let context = container.mainContext

        let stats = CharacterStats(
            character: "春", grade: 1, semester: "upper",
            lesson: 1, lessonTitle: "春夏秋冬", words: ["春天", "春风"]
        )
        context.insert(stats)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<CharacterStats>())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched[0].character, "春")
        XCTAssertEqual(fetched[0].words, ["春天", "春风"])
    }
}
