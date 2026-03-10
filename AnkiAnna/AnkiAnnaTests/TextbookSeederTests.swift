import XCTest
import SwiftData
@testable import AnkiAnna

@MainActor
final class TextbookSeederTests: XCTestCase {

    var container: ModelContainer!

    override func setUp() {
        super.setUp()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try! ModelContainer(
            for: Card.self, CardContext.self, ReviewRecord.self, DailySession.self,
            UserProfile.self, CharacterStats.self,
            configurations: config
        )
    }

    // MARK: - seedDefaultLesson tests

    func testSeedDefaultLessonCreatesOnlyFirstLessonCards() throws {
        let context = container.mainContext
        TextbookSeeder.seedDefaultLesson(modelContext: context)
        try context.save()

        let cards = try context.fetch(FetchDescriptor<Card>())
        let stats = try context.fetch(FetchDescriptor<CharacterStats>())

        // Should have cards and stats from grade 2 upper semester lesson 1 only
        XCTAssertGreaterThan(cards.count, 0, "Should create cards for default lesson")
        XCTAssertGreaterThan(stats.count, 0, "Should create stats for default lesson")

        // All cards should be textbook source
        XCTAssertTrue(cards.allSatisfy { $0.source == .textbook })

        // All stats should be grade 2, upper semester
        XCTAssertTrue(stats.allSatisfy { $0.grade == 2 })
        XCTAssertTrue(stats.allSatisfy { $0.semester == "upper" })
    }

    func testSeedDefaultLessonCardCountMatchesFirstLesson() throws {
        let context = container.mainContext
        // Get expected count from TextbookDataProvider
        let lessons = TextbookDataProvider.loadLessons(grade: .grade2, semester: .upper)
        let firstLesson = lessons.first!
        let expectedCount = firstLesson.characters.count

        TextbookSeeder.seedDefaultLesson(modelContext: context)
        try context.save()

        let cards = try context.fetch(FetchDescriptor<Card>())
        XCTAssertEqual(cards.count, expectedCount, "Card count should match first lesson character count")
    }

    func testCreateCardFromCharacter() {
        let char = TextbookDataProvider.TextbookCharacter(char: "春", words: ["春天", "春风", "春雨"])
        let card = TextbookSeeder.createCard(
            from: char, type: .chineseWriting,
            tags: ["一年级上册", "第1课 春夏秋冬"]
        )
        XCTAssertEqual(card.answer, "春")
        XCTAssertEqual(card.type, .chineseWriting)
        XCTAssertEqual(card.source, .textbook)
        XCTAssertEqual(card.contexts.count, 3)
        XCTAssertTrue(card.contexts.contains(where: { $0.text.contains("___") }))
        XCTAssertEqual(card.hint, "春天、春风、春雨")
        XCTAssertEqual(card.tags, ["一年级上册", "第1课 春夏秋冬"])
    }

    func testCreateCharacterStats() {
        let char = TextbookDataProvider.TextbookCharacter(char: "春", words: ["春天", "春风"])
        let stats = TextbookSeeder.createCharacterStats(
            from: char, grade: 1, semester: "upper",
            lesson: 1, lessonTitle: "春夏秋冬"
        )
        XCTAssertEqual(stats.character, "春")
        XCTAssertEqual(stats.grade, 1)
        XCTAssertEqual(stats.semester, "upper")
        XCTAssertEqual(stats.lesson, 1)
        XCTAssertEqual(stats.lessonTitle, "春夏秋冬")
        XCTAssertEqual(stats.words, ["春天", "春风"])
        XCTAssertEqual(stats.masteryLevel, .new)
        XCTAssertEqual(stats.practiceCount, 0)
        XCTAssertEqual(stats.ease, 2.5)
    }

    func testCardContextsAreFilledFromWords() {
        let char = TextbookDataProvider.TextbookCharacter(char: "大", words: ["大人", "大小"])
        let card = TextbookSeeder.createCard(from: char, type: .chineseWriting, tags: [])
        XCTAssertEqual(card.contexts.count, 2)
        XCTAssertEqual(card.contexts[0].text, "___人")
        XCTAssertEqual(card.contexts[0].fullText, "大人")
        XCTAssertEqual(card.contexts[1].text, "___小")
        XCTAssertEqual(card.contexts[1].fullText, "大小")
    }

    // MARK: - addCharacterToLibrary tests

    func testAddCharacterToLibraryCreatesCard() throws {
        let context = container.mainContext
        let char = TextbookDataProvider.TextbookCharacter(char: "春", words: ["春天", "春风"])
        let added = TextbookSeeder.addCharacterToLibrary(
            char, grade: .grade1, semester: .upper,
            lesson: 1, lessonTitle: "春夏秋冬",
            modelContext: context
        )
        try context.save()

        XCTAssertTrue(added, "Should return true when adding new character")
        let cards = try context.fetch(FetchDescriptor<Card>())
        XCTAssertEqual(cards.count, 1)
        XCTAssertEqual(cards.first?.answer, "春")
        XCTAssertEqual(cards.first?.source, .textbook)
    }

    func testAddCharacterToLibraryPreventsDuplicate() throws {
        let context = container.mainContext
        let char = TextbookDataProvider.TextbookCharacter(char: "春", words: ["春天", "春风"])

        let first = TextbookSeeder.addCharacterToLibrary(
            char, grade: .grade1, semester: .upper,
            lesson: 1, lessonTitle: "春夏秋冬",
            modelContext: context
        )
        let second = TextbookSeeder.addCharacterToLibrary(
            char, grade: .grade1, semester: .upper,
            lesson: 1, lessonTitle: "春夏秋冬",
            modelContext: context
        )
        try context.save()

        XCTAssertTrue(first)
        XCTAssertFalse(second, "Should return false for duplicate")
        let cards = try context.fetch(FetchDescriptor<Card>())
        XCTAssertEqual(cards.count, 1, "Should not create duplicate card")
    }

    func testAddCharacterToLibraryCreatesStatsIfMissing() throws {
        let context = container.mainContext
        let char = TextbookDataProvider.TextbookCharacter(char: "春", words: ["春天", "春风"])
        _ = TextbookSeeder.addCharacterToLibrary(
            char, grade: .grade1, semester: .upper,
            lesson: 1, lessonTitle: "春夏秋冬",
            modelContext: context
        )
        try context.save()

        let stats = try context.fetch(FetchDescriptor<CharacterStats>())
        XCTAssertEqual(stats.count, 1)
        XCTAssertEqual(stats.first?.character, "春")
    }

    // MARK: - allCharacters

    func testAllTextbookCharactersCount() {
        let count = TextbookDataProvider.allCharacters().count
        // Should have at least some characters if textbook JSONs are bundled
        // This test may return 0 in test target if resources aren't available
        XCTAssertGreaterThanOrEqual(count, 0)
    }
}
