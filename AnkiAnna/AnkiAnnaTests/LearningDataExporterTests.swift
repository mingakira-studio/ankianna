import XCTest
import SwiftData
@testable import AnkiAnna

// MARK: - LearningDataExporter Contract Tests
// These tests define the expected interface for LearningDataExporter.
// They will compile and run once Services/LearningDataExporter.swift is created.
// Expected interface: LearningDataExporter.exportJSON(context: ModelContext) throws -> Data
//
// Remove the #if LEARNING_DATA_EXPORTER_READY guard once the implementation exists.

#if LEARNING_DATA_EXPORTER_READY

@MainActor
final class LearningDataExporterTests: XCTestCase {

    var container: ModelContainer!
    var context: ModelContext!

    override func setUp() {
        super.setUp()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try! ModelContainer(
            for: Card.self, ReviewRecord.self, DailySession.self,
            UserProfile.self, CharacterStats.self, WritingAttempt.self,
            configurations: config
        )
        context = container.mainContext
    }

    // MARK: - Export JSON structure

    func testExportEmptyDatabase() throws {
        let data = try LearningDataExporter.exportJSON(context: context)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertNotNil(json["exportDate"])
        XCTAssertTrue((json["writingAttempts"] as? [Any])?.isEmpty ?? false)
        XCTAssertTrue((json["characterStats"] as? [Any])?.isEmpty ?? false)
        XCTAssertTrue((json["dailySessions"] as? [Any])?.isEmpty ?? false)
    }

    func testExportContainsWritingAttempts() throws {
        let attempt = WritingAttempt(
            character: "龙",
            correct: true,
            writingDuration: 3.5,
            gameMode: "quick",
            sessionId: "s1"
        )
        context.insert(attempt)
        try context.save()

        let data = try LearningDataExporter.exportJSON(context: context)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let attempts = json["writingAttempts"] as! [[String: Any]]

        XCTAssertEqual(attempts.count, 1)
        let first = attempts[0]
        XCTAssertEqual(first["character"] as? String, "龙")
        XCTAssertEqual(first["correct"] as? Bool, true)
        XCTAssertEqual(first["writingDuration"] as! Double, 3.5, accuracy: 0.001)
        XCTAssertEqual(first["gameMode"] as? String, "quick")
        XCTAssertEqual(first["sessionId"] as? String, "s1")
        XCTAssertNotNil(first["timestamp"])
        XCTAssertNotNil(first["id"])
    }

    func testExportContainsCharacterStats() throws {
        let stats = CharacterStats(
            character: "春", grade: 1, semester: "upper",
            lesson: 1, lessonTitle: "春夏秋冬", words: ["春天"]
        )
        stats.practiceCount = 5
        stats.correctCount = 4
        stats.errorCount = 1
        context.insert(stats)
        try context.save()

        let data = try LearningDataExporter.exportJSON(context: context)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let statsArray = json["characterStats"] as! [[String: Any]]

        XCTAssertEqual(statsArray.count, 1)
        let first = statsArray[0]
        XCTAssertEqual(first["character"] as? String, "春")
        XCTAssertEqual(first["practiceCount"] as? Int, 5)
        XCTAssertEqual(first["correctCount"] as? Int, 4)
        XCTAssertEqual(first["errorCount"] as? Int, 1)
        XCTAssertEqual(first["masteryLevel"] as? String, "new")
    }

    func testExportContainsDailySessions() throws {
        let session = DailySession(date: Date(), targetCount: 8)
        session.completedCount = 5
        session.correctCount = 4
        context.insert(session)
        try context.save()

        let data = try LearningDataExporter.exportJSON(context: context)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let sessions = json["dailySessions"] as! [[String: Any]]

        XCTAssertEqual(sessions.count, 1)
        let first = sessions[0]
        XCTAssertEqual(first["targetCount"] as? Int, 8)
        XCTAssertEqual(first["completedCount"] as? Int, 5)
        XCTAssertEqual(first["correctCount"] as? Int, 4)
    }

    // MARK: - JSON validity

    func testExportProducesValidJSON() throws {
        // Insert mixed data
        context.insert(WritingAttempt(character: "龙", correct: true, writingDuration: 2.0, gameMode: "quick"))
        context.insert(WritingAttempt(character: "凤", correct: false, writingDuration: 6.0, gameMode: "survival"))
        context.insert(CharacterStats(character: "龙", grade: 1, semester: "upper", lesson: 1, lessonTitle: "test", words: []))
        context.insert(DailySession(date: Date(), targetCount: 10))
        try context.save()

        let data = try LearningDataExporter.exportJSON(context: context)

        // Should be valid JSON
        let json = try JSONSerialization.jsonObject(with: data)
        XCTAssertTrue(json is [String: Any])

        // Should also be valid UTF-8 string containing Chinese characters
        let jsonString = String(data: data, encoding: .utf8)
        XCTAssertNotNil(jsonString)
        XCTAssertTrue(jsonString!.contains("龙"))
        XCTAssertTrue(jsonString!.contains("凤"))
    }

    func testExportMultipleAttemptsSameSession() throws {
        let sessionId = "session-123"
        context.insert(WritingAttempt(character: "春", correct: true, writingDuration: 2.0, gameMode: "timeAttack", sessionId: sessionId))
        context.insert(WritingAttempt(character: "夏", correct: true, writingDuration: 3.0, gameMode: "timeAttack", sessionId: sessionId))
        context.insert(WritingAttempt(character: "秋", correct: false, writingDuration: 5.0, gameMode: "timeAttack", sessionId: sessionId))
        try context.save()

        let data = try LearningDataExporter.exportJSON(context: context)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let attempts = json["writingAttempts"] as! [[String: Any]]

        XCTAssertEqual(attempts.count, 3)
        let sessionIds = attempts.compactMap { $0["sessionId"] as? String }
        XCTAssertTrue(sessionIds.allSatisfy { $0 == sessionId })
    }

    // MARK: - Export date

    func testExportDateIsISO8601() throws {
        let data = try LearningDataExporter.exportJSON(context: context)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let exportDate = json["exportDate"] as? String
        XCTAssertNotNil(exportDate)

        // Should be parseable as ISO8601
        let formatter = ISO8601DateFormatter()
        XCTAssertNotNil(formatter.date(from: exportDate!), "exportDate should be ISO8601 format")
    }
}

#endif
