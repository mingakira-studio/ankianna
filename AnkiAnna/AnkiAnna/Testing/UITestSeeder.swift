#if DEBUG
import SwiftData

enum UITestSeeder {
    static func seedTestData(context: ModelContext) {
        // Profile
        let profile = UserProfile(name: "Anna", dailyGoal: 15)
        context.insert(profile)

        // English cards
        let card1 = Card(type: .englishSpelling, answer: "apple", audioText: "apple")
        let ctx1 = CardContext(type: .phrase, text: "an ___", fullText: "an apple")
        card1.contexts.append(ctx1)
        context.insert(card1)

        let card2 = Card(type: .englishSpelling, answer: "book", audioText: "book")
        let ctx2 = CardContext(type: .sentence, text: "I read a ___", fullText: "I read a book")
        card2.contexts.append(ctx2)
        context.insert(card2)

        let card3 = Card(type: .englishSpelling, answer: "cat", audioText: "cat")
        let ctx3 = CardContext(type: .phrase, text: "a ___", fullText: "a cat")
        card3.contexts.append(ctx3)
        context.insert(card3)

        // Chinese card
        let card4 = Card(type: .chineseWriting, answer: "大", audioText: "大")
        let ctx4 = CardContext(type: .phrase, text: "___人", fullText: "大人")
        card4.contexts.append(ctx4)
        context.insert(card4)

        try? context.save()
    }

    static func seedSingleCard(context: ModelContext) {
        let profile = UserProfile(name: "Anna", dailyGoal: 15)
        context.insert(profile)

        let card = Card(type: .englishSpelling, answer: "apple", audioText: "apple")
        let ctx = CardContext(type: .phrase, text: "an ___", fullText: "an apple")
        card.contexts.append(ctx)
        context.insert(card)

        try? context.save()
    }
}
#endif
