import XCTest
@testable import AnkiAnna

final class TTSServiceTests: XCTestCase {

    func testChineseLanguageCode() {
        let lang = TTSService.languageCode(for: .chineseWriting)
        XCTAssertEqual(lang, "zh-CN")
    }

    func testEnglishLanguageCode() {
        let lang = TTSService.languageCode(for: .englishSpelling)
        XCTAssertEqual(lang, "en-US")
    }

    func testCreateUtterance() {
        let utterance = TTSService.createUtterance(text: "龙飞凤舞", cardType: .chineseWriting)
        XCTAssertEqual(utterance.speechString, "龙飞凤舞")
        XCTAssertEqual(utterance.voice?.language, "zh-CN")
    }
}
