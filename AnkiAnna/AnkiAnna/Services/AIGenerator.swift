import Foundation
import Security

enum AIGenerator {
    typealias GeneratedContext = (type: ContextType, text: String, fullText: String)
    typealias TextbookBatchResult = [String: (phrases: [GeneratedContext], sentences: [GeneratedContext])]

    static let defaultEndpoint = "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions"
    static let defaultModel = "qwen-plus"
    static let defaultAPIKey = "***REMOVED***"

    struct GeneratedCard {
        let answer: String
        let contexts: [GeneratedContext]
    }

    struct APIConfig {
        let endpoint: String
        let apiKey: String
        let model: String
    }

    static func generateCards(
        subject: CardType,
        grade: String,
        topic: String,
        config: APIConfig
    ) async throws -> [GeneratedCard] {
        let subjectText = subject == .chineseWriting ? "中文汉字" : "英文单词"
        let prompt = """
        你是一个小学语文/英语教师。请为\(grade)\(topic)生成 8 个\(subjectText)听写卡片。

        每个卡片包含：
        1. 目标字/词
        2. 5 个语境（组词或造句），用 ___ 替代目标字/词

        请只返回 JSON 数组，不要其他文字：
        [{"answer": "龙", "contexts": [{"type": "phrase", "text": "___飞凤舞", "fullText": "龙飞凤舞"}]}]
        """

        guard let url = URL(string: config.endpoint) else {
            throw GeneratorError.invalidEndpoint
        }

        let body: [String: Any] = [
            "model": config.model,
            "max_tokens": 2000,
            "messages": [
                ["role": "system", "content": "You are a helpful assistant. Always respond with valid JSON only."],
                ["role": "user", "content": prompt]
            ]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)
        return try generatedCards(from: data)
    }

    /// Generate contexts for a batch of given words/characters in one API call
    static func generateContexts(
        words: [String],
        subject: CardType,
        config: APIConfig
    ) async throws -> [GeneratedCard] {
        let wordList = words.joined(separator: "、")
        let subjectText = subject == .chineseWriting ? "汉字/词语" : "英文单词"
        let textbookContext = subject == .chineseWriting
            ? TextbookDataProvider.contextForWords(words)
            : ""
        let textbookHint = textbookContext.isEmpty ? "" : """

        \(textbookContext)
        请优先使用课本中的组词，再补充其他常用组词或造句。
        """
        let prompt = """
        请为以下\(subjectText)各生成 5 个语境（组词或造句），用 ___ 替代目标字词。

        目标字词：\(wordList)
        \(textbookHint)
        请只返回 JSON 数组，不要其他文字：
        [{"answer": "龙", "contexts": [{"type": "phrase", "text": "___飞凤舞", "fullText": "龙飞凤舞"}]}]
        """

        guard let url = URL(string: config.endpoint) else {
            throw GeneratorError.invalidEndpoint
        }

        let body: [String: Any] = [
            "model": config.model,
            "max_tokens": 4000,
            "messages": [
                ["role": "system", "content": "You are a helpful assistant. Always respond with valid JSON only."],
                ["role": "user", "content": prompt]
            ]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)
        return try generatedCards(from: data)
    }

    /// Generate contexts for a textbook lesson using parallel batch requests.
    /// Splits characters into batches of 4, calls API concurrently, then merges results.
    static func generateTextbookContexts(
        characters: [TextbookDataProvider.TextbookCharacter],
        lessonTitle: String,
        config: APIConfig
    ) async throws -> [GeneratedCard] {
        // Each character gets its own parallel request
        let batchSize = 1
        var batches: [[TextbookDataProvider.TextbookCharacter]] = []
        for i in stride(from: 0, to: characters.count, by: batchSize) {
            batches.append(Array(characters[i..<min(i + batchSize, characters.count)]))
        }

        // Run all batches concurrently
        let allAIResults = try await withThrowingTaskGroup(of: TextbookBatchResult.self) { group in
            for batch in batches {
                group.addTask {
                    try await callTextbookBatch(characters: batch, lessonTitle: lessonTitle, config: config)
                }
            }
            var merged: TextbookBatchResult = [:]
            for try await result in group {
                merged.merge(result) { _, new in new }
            }
            return merged
        }

        return mergeTextbookContexts(characters: characters, aiResults: allAIResults)
    }

    /// Call API for a single batch of characters
    private static func callTextbookBatch(
        characters: [TextbookDataProvider.TextbookCharacter],
        lessonTitle: String,
        config: APIConfig
    ) async throws -> TextbookBatchResult {
        var charLines: [String] = []
        for char in characters {
            let wordsStr = char.words.joined(separator: "、")
            let needed = max(0, 5 - char.words.count)
            charLines.append("- \(char.char)（已有：\(wordsStr)）→ 补 \(needed) 个组词 + 3 造句")
        }

        let prompt = """
        你是小学二年级语文老师。以下是课文《\(lessonTitle)》的生字。
        请为每个生字补充组词到总共5个（已有的不要重复），造3个适合二年级的短句。

        重要：只替换目标字本身为 ___ ，保留其他所有字。
        例如目标字是"肚"：正确 "小___子圆鼓鼓的"，错误 "小___圆鼓鼓的"。

        \(charLines.joined(separator: "\n"))

        JSON 格式：
        [{"answer":"肚","phrases":[{"text":"___子","fullText":"肚子"}],"sentences":[{"text":"小___子圆鼓鼓的。","fullText":"小肚子圆鼓鼓的。"}]}]
        """

        guard let url = URL(string: config.endpoint) else {
            throw GeneratorError.invalidEndpoint
        }

        let body: [String: Any] = [
            "model": config.model,
            "max_tokens": 2000,
            "messages": [
                ["role": "system", "content": "You are a helpful assistant. Always respond with valid JSON only."],
                ["role": "user", "content": prompt]
            ]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)
        return try textbookBatchResult(from: data)
    }

    static func generatedCards(from data: Data) throws -> [GeneratedCard] {
        let text = try messageContent(from: data)
        guard let jsonStart = text.firstIndex(of: "["),
              let jsonEnd = text.lastIndex(of: "]") else {
            throw GeneratorError.parseError
        }
        let jsonString = String(text[jsonStart...jsonEnd])
        let cardsData = try JSONSerialization.jsonObject(with: jsonString.data(using: .utf8)!) as? [[String: Any]] ?? []

        return cardsData.compactMap { cardDict -> GeneratedCard? in
            guard let answer = cardDict["answer"] as? String,
                  let contexts = cardDict["contexts"] as? [[String: Any]] else { return nil }
            let parsedContexts = contexts.compactMap { parseContext($0) }
            return GeneratedCard(answer: answer, contexts: parsedContexts)
        }
    }

    static func textbookBatchResult(from data: Data) throws -> TextbookBatchResult {
        let text = try messageContent(from: data)
        guard let jsonStart = text.firstIndex(of: "["),
              let jsonEnd = text.lastIndex(of: "]") else {
            throw GeneratorError.parseError
        }
        let jsonString = String(text[jsonStart...jsonEnd])
        let cardsData = try JSONSerialization.jsonObject(with: jsonString.data(using: .utf8)!) as? [[String: Any]] ?? []

        var results: TextbookBatchResult = [:]
        for cardDict in cardsData {
            guard let answer = cardDict["answer"] as? String else { continue }
            let phrases = (cardDict["phrases"] as? [[String: Any]] ?? []).compactMap {
                parseContext($0, defaultType: .phrase)
            }
            let sentences = (cardDict["sentences"] as? [[String: Any]] ?? []).compactMap {
                parseContext($0, defaultType: .sentence)
            }
            results[answer] = (phrases: phrases, sentences: sentences)
        }
        return results
    }

    static func mergeTextbookContexts(
        characters: [TextbookDataProvider.TextbookCharacter],
        aiResults: TextbookBatchResult
    ) -> [GeneratedCard] {
        characters.map { char in
            let textbookPhrases = TextbookDataProvider.phrasesFromTextbookWords(char: char.char, words: char.words)
            var seenFullTexts = Set(textbookPhrases.map(\.fullText))

            var allPhrases = textbookPhrases
            if let ai = aiResults[char.char] {
                for phrase in ai.phrases {
                    if allPhrases.count >= 5 { break }
                    if seenFullTexts.insert(phrase.fullText).inserted {
                        allPhrases.append(phrase)
                    }
                }
                let sentences = Array(ai.sentences.prefix(3))
                return GeneratedCard(answer: char.char, contexts: allPhrases + sentences)
            }
            return GeneratedCard(answer: char.char, contexts: allPhrases)
        }
    }

    private static func messageContent(from data: Data) throws -> String {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let text = message["content"] as? String else {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = json["error"] as? [String: Any],
               let msg = error["message"] as? String {
                throw GeneratorError.apiError(msg)
            }
            throw GeneratorError.parseError
        }
        return text
    }

    private static func parseContext(
        _ ctx: [String: Any],
        defaultType: ContextType = .phrase
    ) -> GeneratedContext? {
        guard let text = ctx["text"] as? String,
              let fullText = ctx["fullText"] as? String else { return nil }
        let type: ContextType
        if let rawType = ctx["type"] as? String {
            type = rawType == "sentence" ? .sentence : .phrase
        } else {
            type = defaultType
        }
        return (type: type, text: text, fullText: fullText)
    }

    static func loadConfig() -> APIConfig {
        let key = loadAPIKey() ?? defaultAPIKey
        let ep = loadEndpoint() ?? defaultEndpoint
        let md = loadModel() ?? defaultModel
        let savedModel = loadModel()
        NSLog("[AIGenerator] savedModel=%@ defaultModel=%@ usingModel=%@", savedModel ?? "nil", defaultModel, md)
        return APIConfig(endpoint: ep, apiKey: key, model: md)
    }

    // MARK: - Keychain helpers

    private static func saveKeychain(_ value: String, account: String) {
        let data = value.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    private static func loadKeychain(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func saveAPIKey(_ key: String) { saveKeychain(key, account: "ankianna-api-key") }
    static func loadAPIKey() -> String? { loadKeychain(account: "ankianna-api-key") }

    static func saveEndpoint(_ endpoint: String) { saveKeychain(endpoint, account: "ankianna-endpoint") }
    static func loadEndpoint() -> String? { loadKeychain(account: "ankianna-endpoint") }

    static func saveModel(_ model: String) { saveKeychain(model, account: "ankianna-model") }
    static func loadModel() -> String? { loadKeychain(account: "ankianna-model") }

    enum GeneratorError: LocalizedError, Equatable {
        case parseError
        case noAPIKey
        case invalidEndpoint
        case apiError(String)

        var errorDescription: String? {
            switch self {
            case .parseError: return "无法解析 AI 返回的内容"
            case .noAPIKey: return "请先设置 API Key"
            case .invalidEndpoint: return "无效的 API 地址"
            case .apiError(let msg): return "API 错误: \(msg)"
            }
        }
    }
}
