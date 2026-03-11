#if DEBUG
import SwiftData

enum UITestSeeder {
    static func seedTestData(context: ModelContext) {
        let profile = UserProfile(name: "Anna", dailyGoal: 15)
        context.insert(profile)

        let card1 = Card(type: .englishSpelling, answer: "apple", audioText: "apple")
        card1.contexts.append(CardContext(type: .phrase, text: "an ___", fullText: "an apple"))
        context.insert(card1)

        let card2 = Card(type: .englishSpelling, answer: "book", audioText: "book")
        card2.contexts.append(CardContext(type: .sentence, text: "I read a ___", fullText: "I read a book"))
        context.insert(card2)

        let card3 = Card(type: .englishSpelling, answer: "cat", audioText: "cat")
        card3.contexts.append(CardContext(type: .phrase, text: "a ___", fullText: "a cat"))
        context.insert(card3)

        let card4 = Card(type: .chineseWriting, answer: "大", audioText: "大")
        card4.contexts.append(CardContext(type: .phrase, text: "___人", fullText: "大人"))
        context.insert(card4)

        try? context.save()
    }

    static func seedEnglishCards(context: ModelContext) {
        let profile = UserProfile(name: "Anna", dailyGoal: 15)
        context.insert(profile)

        for (answer, text, fullText) in [
            ("apple", "an ___", "an apple"),
            ("book", "I read a ___", "I read a book"),
            ("cat", "a ___", "a cat")
        ] {
            let card = Card(type: .englishSpelling, answer: answer, audioText: answer)
            card.contexts.append(CardContext(type: .phrase, text: text, fullText: fullText))
            context.insert(card)
        }

        try? context.save()
    }

    static func seedSingleCard(context: ModelContext) {
        let profile = UserProfile(name: "Anna", dailyGoal: 15)
        context.insert(profile)

        let card = Card(type: .englishSpelling, answer: "apple", audioText: "apple")
        card.contexts.append(CardContext(type: .phrase, text: "an ___", fullText: "an apple"))
        context.insert(card)

        try? context.save()
    }

    /// Seed with CharacterStats to exercise SM-2 scheduling path
    static func seedWithCharacterStats(context: ModelContext) {
        let profile = UserProfile(name: "Anna", dailyGoal: 15)
        context.insert(profile)

        let chineseData: [(String, String, String, [String])] = [
            ("大", "___人", "大人", ["大人", "大小"]),
            ("小", "___鸟", "小鸟", ["小鸟", "大小"]),
            ("天", "___空", "天空", ["天空", "今天"])
        ]

        for (char, text, fullText, words) in chineseData {
            let card = Card(type: .chineseWriting, answer: char, audioText: char,
                            hint: words.joined(separator: "、"), tags: ["一年级上册", "天地人"], source: .textbook)
            card.contexts.append(CardContext(type: .phrase, text: text, fullText: fullText, source: .textbook))
            context.insert(card)

            let stats = CharacterStats(character: char, grade: 1, semester: "upper",
                                       lesson: 1, lessonTitle: "天地人", words: words)
            context.insert(stats)
        }

        let card = Card(type: .englishSpelling, answer: "apple", audioText: "apple")
        card.contexts.append(CardContext(type: .phrase, text: "an ___", fullText: "an apple"))
        context.insert(card)

        try? context.save()
    }
}
#endif
