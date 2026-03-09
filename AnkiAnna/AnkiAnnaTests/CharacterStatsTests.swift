import XCTest
import SwiftData
@testable import AnkiAnna

@MainActor
final class CharacterStatsTests: XCTestCase {

    func testMasteryLevelRawValues() {
        XCTAssertEqual(MasteryLevel.new.rawValue, "new")
        XCTAssertEqual(MasteryLevel.learning.rawValue, "learning")
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
        XCTAssertFalse(stats.isManuallyReset)
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

    func testIsDifficultFalseWhenFewPractices() {
        let stats = CharacterStats(
            character: "春", grade: 1, semester: "upper",
            lesson: 1, lessonTitle: "春夏秋冬", words: []
        )
        stats.practiceCount = 2
        stats.errorCount = 2
        XCTAssertFalse(stats.isDifficult)
    }

    func testIsDifficultTrueWhenHighErrorRate() {
        let stats = CharacterStats(
            character: "春", grade: 1, semester: "upper",
            lesson: 1, lessonTitle: "春夏秋冬", words: []
        )
        stats.practiceCount = 5
        stats.errorCount = 3  // 60% error rate
        XCTAssertTrue(stats.isDifficult)
    }

    func testUpdateMasteryLevelNew() {
        let stats = CharacterStats(
            character: "春", grade: 1, semester: "upper",
            lesson: 1, lessonTitle: "春夏秋冬", words: []
        )
        stats.updateMasteryLevel()
        XCTAssertEqual(stats.masteryLevel, .new)
    }

    func testUpdateMasteryLevelLearning() {
        let stats = CharacterStats(
            character: "春", grade: 1, semester: "upper",
            lesson: 1, lessonTitle: "春夏秋冬", words: []
        )
        stats.practiceCount = 2
        stats.repetition = 2
        stats.updateMasteryLevel()
        XCTAssertEqual(stats.masteryLevel, .learning)
    }

    func testUpdateMasteryLevelMastered() {
        let stats = CharacterStats(
            character: "春", grade: 1, semester: "upper",
            lesson: 1, lessonTitle: "春夏秋冬", words: []
        )
        stats.practiceCount = 5
        stats.repetition = 3
        stats.interval = 21
        stats.updateMasteryLevel()
        XCTAssertEqual(stats.masteryLevel, .mastered)
    }

    func testManualResetOverridesMastery() {
        let stats = CharacterStats(
            character: "春", grade: 1, semester: "upper",
            lesson: 1, lessonTitle: "春夏秋冬", words: []
        )
        stats.practiceCount = 5
        stats.repetition = 3
        stats.interval = 21
        stats.isManuallyReset = true
        stats.updateMasteryLevel()
        XCTAssertEqual(stats.masteryLevel, .learning)
    }

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
        XCTAssertEqual(stats.masteryLevel, .learning)
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

    func testResetMastery() {
        let stats = CharacterStats(
            character: "春", grade: 1, semester: "upper",
            lesson: 1, lessonTitle: "春夏秋冬", words: []
        )
        stats.practiceCount = 5
        stats.repetition = 3
        stats.interval = 21
        stats.ease = 3.0
        stats.updateMasteryLevel()
        XCTAssertEqual(stats.masteryLevel, .mastered)

        stats.resetMastery()
        XCTAssertTrue(stats.isManuallyReset)
        XCTAssertEqual(stats.masteryLevel, .learning)
        XCTAssertEqual(stats.ease, 2.5)
        XCTAssertEqual(stats.interval, 0)
        XCTAssertEqual(stats.repetition, 0)
        XCTAssertNil(stats.nextReviewDate)
    }

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
