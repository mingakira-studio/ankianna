import XCTest
@testable import AnkiAnna

final class HandwritingRecognizerTests: XCTestCase {

    func testMatchExact() {
        XCTAssertTrue(HandwritingRecognizer.matches(recognized: "龙", expected: "龙"))
    }

    func testMatchCaseInsensitive() {
        XCTAssertTrue(HandwritingRecognizer.matches(recognized: "Dragon", expected: "dragon"))
    }

    func testMatchWithWhitespace() {
        XCTAssertTrue(HandwritingRecognizer.matches(recognized: " dragon ", expected: "dragon"))
    }

    func testNoMatch() {
        XCTAssertFalse(HandwritingRecognizer.matches(recognized: "虎", expected: "龙"))
    }

    func testBestMatchFromCandidates() {
        let candidates = ["虎", "龙", "马"]
        let result = HandwritingRecognizer.bestMatch(candidates: candidates, expected: "龙")
        XCTAssertTrue(result)
    }

    func testBestMatchNoMatch() {
        let candidates = ["虎", "马", "牛"]
        let result = HandwritingRecognizer.bestMatch(candidates: candidates, expected: "龙")
        XCTAssertFalse(result)
    }
}
