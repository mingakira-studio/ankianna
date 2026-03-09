import XCTest
@testable import AnkiAnna

final class TextbookDataProviderTests: XCTestCase {
    func testCharactersForUnitMatchesUnderlyingLessonFilter() {
        let expected = TextbookDataProvider.loadLessons(semester: .upper)
            .filter { $0.unit == 1 }
            .flatMap(\.characters)
            .map(\.char)
        let actual = TextbookDataProvider.charactersForUnit(semester: .upper, unit: 1).map(\.char)

        XCTAssertEqual(actual, expected)
        XCTAssertFalse(actual.isEmpty)
    }

    func testPhrasesFromTextbookWordsReplacesTargetCharacter() {
        let contexts = TextbookDataProvider.phrasesFromTextbookWords(char: "大", words: ["大人", "大小"])

        XCTAssertEqual(contexts.count, 2)
        XCTAssertEqual(contexts[0].text, "___人")
        XCTAssertEqual(contexts[0].fullText, "大人")
        XCTAssertEqual(contexts[1].text, "___小")
    }

    func testContextForWordsAcrossAllGradesIncludesHeader() {
        let context = TextbookDataProvider.contextForWords(["两"])

        XCTAssertTrue(context.hasPrefix("以下是课本中这些字的组词参考："))
        XCTAssertTrue(context.contains("两"))
    }

    func testContextForWordsReturnsEmptyWhenNoMatch() {
        XCTAssertEqual(TextbookDataProvider.contextForWords(["不存在的字词"]), "")
        XCTAssertEqual(TextbookDataProvider.contextForWords(["不存在的字词"], grade: .grade2, semester: .upper), "")
    }
}
