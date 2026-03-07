import XCTest
@testable import AnkiAnna

/// Tests for subtask 1: English spelling keyboard input with per-character comparison
final class SpellingCheckerTests: XCTestCase {

    // MARK: - Overall correctness

    func testExactMatch() {
        let result = SpellingChecker.check(typed: "dragon", expected: "dragon")
        XCTAssertTrue(result.isCorrect)
    }

    func testCaseInsensitiveMatch() {
        let result = SpellingChecker.check(typed: "Dragon", expected: "dragon")
        XCTAssertTrue(result.isCorrect)
    }

    func testWrongAnswer() {
        let result = SpellingChecker.check(typed: "dragan", expected: "dragon")
        XCTAssertFalse(result.isCorrect)
    }

    func testEmptyTyped() {
        let result = SpellingChecker.check(typed: "", expected: "dragon")
        XCTAssertFalse(result.isCorrect)
    }

    // MARK: - Per-character comparison

    func testAllCorrectCharResults() {
        let result = SpellingChecker.check(typed: "cat", expected: "cat")
        XCTAssertEqual(result.charResults.count, 3)
        XCTAssertTrue(result.charResults.allSatisfy { $0.isCorrect })
    }

    func testWrongCharacterHighlighted() {
        // "dragan" vs "dragon" → index 4 ('a' vs 'o') is the only wrong char
        let result = SpellingChecker.check(typed: "dragan", expected: "dragon")
        XCTAssertEqual(result.charResults.count, 6)
        XCTAssertTrue(result.charResults[0].isCorrect)   // d
        XCTAssertTrue(result.charResults[1].isCorrect)   // r
        XCTAssertTrue(result.charResults[2].isCorrect)   // a
        XCTAssertTrue(result.charResults[3].isCorrect)   // g
        XCTAssertFalse(result.charResults[4].isCorrect)  // a != o
        XCTAssertTrue(result.charResults[5].isCorrect)   // n
    }

    func testTypedTooShort() {
        // "dra" vs "dragon" → 3 chars compared, remaining 3 marked wrong
        let result = SpellingChecker.check(typed: "dra", expected: "dragon")
        XCTAssertFalse(result.isCorrect)
        XCTAssertEqual(result.charResults.count, 6) // padded to expected length
        XCTAssertTrue(result.charResults[0].isCorrect)
        XCTAssertTrue(result.charResults[1].isCorrect)
        XCTAssertTrue(result.charResults[2].isCorrect)
        XCTAssertFalse(result.charResults[3].isCorrect) // missing
        XCTAssertFalse(result.charResults[4].isCorrect) // missing
        XCTAssertFalse(result.charResults[5].isCorrect) // missing
    }

    func testTypedTooLong() {
        // "dragons" vs "dragon" → extra 's' is wrong
        let result = SpellingChecker.check(typed: "dragons", expected: "dragon")
        XCTAssertFalse(result.isCorrect)
        XCTAssertEqual(result.charResults.count, 7) // includes extra char
        XCTAssertFalse(result.charResults[6].isCorrect) // extra 's'
    }

    // MARK: - CharResult character values

    func testCharResultContainsTypedCharacter() {
        let result = SpellingChecker.check(typed: "ab", expected: "ax")
        XCTAssertEqual(result.charResults[0].character, "a")
        XCTAssertEqual(result.charResults[1].character, "b") // typed char, not expected
    }
}
