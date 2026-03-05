import Foundation
import Security

enum AIGenerator {

    struct GeneratedCard {
        let answer: String
        let contexts: [(type: ContextType, text: String, fullText: String)]
    }

    static func generateCards(
        subject: CardType,
        grade: String,
        topic: String,
        apiKey: String
    ) async throws -> [GeneratedCard] {
        let subjectText = subject == .chineseWriting ? "中文汉字" : "英文单词"
        let prompt = """
        你是一个小学语文/英语教师。请为\(grade)\(topic)生成 8 个\(subjectText)听写卡片。

        每个卡片包含：
        1. 目标字/词
        2. 5 个语境（组词或造句），用 ___ 替代目标字/词

        请用 JSON 格式返回：
        [{"answer": "龙", "contexts": [{"type": "phrase", "text": "___飞凤舞", "fullText": "龙飞凤舞"}]}]
        """

        let body: [String: Any] = [
            "model": "claude-sonnet-4-20250514",
            "max_tokens": 2000,
            "messages": [["role": "user", "content": prompt]]
        ]

        var request = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)

        // Parse response - extract text content
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let textBlock = content.first(where: { $0["type"] as? String == "text" }),
              let text = textBlock["text"] as? String else {
            throw GeneratorError.parseError
        }

        // Extract JSON array from response text
        guard let jsonStart = text.firstIndex(of: "["),
              let jsonEnd = text.lastIndex(of: "]") else {
            throw GeneratorError.parseError
        }
        let jsonString = String(text[jsonStart...jsonEnd])
        let cardsData = try JSONSerialization.jsonObject(with: jsonString.data(using: .utf8)!) as? [[String: Any]] ?? []

        return cardsData.compactMap { cardDict -> GeneratedCard? in
            guard let answer = cardDict["answer"] as? String,
                  let contexts = cardDict["contexts"] as? [[String: Any]] else { return nil }
            let parsedContexts = contexts.compactMap { ctx -> (type: ContextType, text: String, fullText: String)? in
                guard let text = ctx["text"] as? String,
                      let fullText = ctx["fullText"] as? String else { return nil }
                let type: ContextType = (ctx["type"] as? String) == "sentence" ? .sentence : .phrase
                return (type: type, text: text, fullText: fullText)
            }
            return GeneratedCard(answer: answer, contexts: parsedContexts)
        }
    }

    // Keychain helpers for API key
    static func saveAPIKey(_ key: String) {
        let data = key.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "ankianna-api-key",
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    static func loadAPIKey() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "ankianna-api-key",
            kSecReturnData as String: true
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    enum GeneratorError: Error {
        case parseError
        case noAPIKey
    }
}
