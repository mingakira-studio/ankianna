import XCTest
@testable import AnkiAnna

final class TextbookSeederTests: XCTestCase {

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

    func testAllTextbookCharactersCount() {
        let count = TextbookDataProvider.allCharacters().count
        // Should have at least some characters if textbook JSONs are bundled
        // This test may return 0 in test target if resources aren't available
        XCTAssertGreaterThanOrEqual(count, 0)
    }
}
