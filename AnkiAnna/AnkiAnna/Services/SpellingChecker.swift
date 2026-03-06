import Foundation

enum SpellingChecker {
    struct CharResult {
        let character: Character
        let isCorrect: Bool
    }

    static func check(typed: String, expected: String) -> (isCorrect: Bool, charResults: [CharResult]) {
        let typedChars = Array(typed)
        let expectedChars = Array(expected)
        let maxLen = max(typedChars.count, expectedChars.count)

        var charResults: [CharResult] = []

        for i in 0..<maxLen {
            if i < typedChars.count && i < expectedChars.count {
                let typedChar = typedChars[i]
                let expectedChar = expectedChars[i]
                let match = typedChar.lowercased() == expectedChar.lowercased()
                charResults.append(CharResult(character: typedChar, isCorrect: match))
            } else if i < typedChars.count {
                // Extra typed characters beyond expected length
                charResults.append(CharResult(character: typedChars[i], isCorrect: false))
            } else {
                // Missing characters (typed too short)
                charResults.append(CharResult(character: " ", isCorrect: false))
            }
        }

        let isCorrect = typed.lowercased() == expected.lowercased()
        return (isCorrect: isCorrect, charResults: charResults)
    }
}
