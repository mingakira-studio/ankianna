import XCTest
@testable import AnkiAnna

final class AIGeneratorTests: XCTestCase {
    func testGeneratedCardsParsesEmbeddedJSONArray() throws {
        let data = """
        {
          "choices": [
            {
              "message": {
                "content": "好的，下面是结果:\\n[{\\\"answer\\\":\\\"龙\\\",\\\"contexts\\\":[{\\\"type\\\":\\\"phrase\\\",\\\"text\\\":\\\"___飞凤舞\\\",\\\"fullText\\\":\\\"龙飞凤舞\\\"},{\\\"type\\\":\\\"sentence\\\",\\\"text\\\":\\\"我喜欢___。\\\",\\\"fullText\\\":\\\"我喜欢龙。\\\"}]}]\\n请查收"
              }
            }
          ]
        }
        """.data(using: .utf8)!

        let cards = try AIGenerator.generatedCards(from: data)

        XCTAssertEqual(cards.count, 1)
        XCTAssertEqual(cards.first?.answer, "龙")
        XCTAssertEqual(cards.first?.contexts.count, 2)
        XCTAssertEqual(cards.first?.contexts.first?.type, .phrase)
        XCTAssertEqual(cards.first?.contexts.last?.type, .sentence)
    }

    func testGeneratedCardsThrowsAPIError() {
        let data = """
        {
          "error": {
            "message": "quota exceeded"
          }
        }
        """.data(using: .utf8)!

        XCTAssertThrowsError(try AIGenerator.generatedCards(from: data)) { error in
            guard case AIGenerator.GeneratorError.apiError(let message) = error else {
                return XCTFail("Expected apiError, got \(error)")
            }
            XCTAssertEqual(message, "quota exceeded")
        }
    }

    func testGeneratedCardsThrowsParseErrorWhenArrayMissing() {
        let data = """
        {
          "choices": [
            {
              "message": {
                "content": "not json"
              }
            }
          ]
        }
        """.data(using: .utf8)!

        XCTAssertThrowsError(try AIGenerator.generatedCards(from: data)) { error in
            XCTAssertEqual(error as? AIGenerator.GeneratorError, .parseError)
        }
    }

    func testTextbookBatchResultParsesPhrasesAndSentences() throws {
        let data = """
        {
          "choices": [
            {
              "message": {
                "content": "[{\\\"answer\\\":\\\"肚\\\",\\\"phrases\\\":[{\\\"text\\\":\\\"___子\\\",\\\"fullText\\\":\\\"肚子\\\"}],\\\"sentences\\\":[{\\\"text\\\":\\\"小___子圆鼓鼓的。\\\",\\\"fullText\\\":\\\"小肚子圆鼓鼓的。\\\"}]}]"
              }
            }
          ]
        }
        """.data(using: .utf8)!

        let result = try AIGenerator.textbookBatchResult(from: data)

        XCTAssertEqual(result["肚"]?.phrases.count, 1)
        XCTAssertEqual(result["肚"]?.phrases.first?.type, .phrase)
        XCTAssertEqual(result["肚"]?.sentences.count, 1)
        XCTAssertEqual(result["肚"]?.sentences.first?.type, .sentence)
    }

    func testMergeTextbookContextsDeduplicatesAndCapsPhrases() {
        let characters = [
            TextbookDataProvider.TextbookCharacter(char: "大", words: ["大人", "大小"])
        ]
        let aiResults: AIGenerator.TextbookBatchResult = [
            "大": (
                phrases: [
                    (type: .phrase, text: "___人", fullText: "大人"),
                    (type: .phrase, text: "___海", fullText: "大海"),
                    (type: .phrase, text: "___地", fullText: "大地"),
                    (type: .phrase, text: "___门", fullText: "大门"),
                    (type: .phrase, text: "___树", fullText: "大树")
                ],
                sentences: [
                    (type: .sentence, text: "___海真美。", fullText: "大海真美。"),
                    (type: .sentence, text: "___门打开了。", fullText: "大门打开了。"),
                    (type: .sentence, text: "___树很高。", fullText: "大树很高。"),
                    (type: .sentence, text: "___地很宽。", fullText: "大地很宽。")
                ]
            )
        ]

        let cards = AIGenerator.mergeTextbookContexts(characters: characters, aiResults: aiResults)

        XCTAssertEqual(cards.count, 1)
        XCTAssertEqual(cards[0].answer, "大")
        XCTAssertEqual(cards[0].contexts.count, 8)
        XCTAssertEqual(cards[0].contexts.filter { $0.type == .phrase }.count, 5)
        XCTAssertEqual(cards[0].contexts.filter { $0.type == .sentence }.count, 3)
        XCTAssertEqual(cards[0].contexts.filter { $0.fullText == "大人" }.count, 1)
        XCTAssertEqual(cards[0].contexts[2].fullText, "大海")
        XCTAssertEqual(cards[0].contexts[4].fullText, "大门")
    }
}
