import SwiftUI
import SwiftData
import PencilKit

@Observable
final class LearningViewModel {
    var currentCard: Card?
    var currentContext: CardContext?
    var showResult: Bool = false
    var isCorrect: Bool = false
    var charResults: [SpellingChecker.CharResult] = []
    var sessionComplete: Bool = false
    var completedCount: Int = 0
    var correctCount: Int = 0
    var totalCount: Int = 0
    var combo: Int = 0

    private var dueCards: [Card] = []
    private var currentIndex: Int = 0
    private var usedContextIds: Set<UUID> = []

    func loadDueCards(from cards: [Card], dailyGoal: Int) {
        // Filter cards that are due (simplified: all cards for now)
        dueCards = Array(cards.prefix(dailyGoal))
        totalCount = dueCards.count
        currentIndex = 0
        completedCount = 0
        correctCount = 0
        combo = 0
        sessionComplete = dueCards.isEmpty
        if !dueCards.isEmpty {
            advanceToNext()
        }
    }

    func advanceToNext() {
        guard currentIndex < dueCards.count else {
            sessionComplete = true
            return
        }
        currentCard = dueCards[currentIndex]
        currentContext = selectRandomContext(for: currentCard!)
        showResult = false
        isCorrect = false
        charResults = []
    }

    func submitAnswer(recognized: String, modelContext: ModelContext, profile: UserProfile?) {
        guard let card = currentCard else { return }
        isCorrect = HandwritingRecognizer.matches(recognized: recognized, expected: card.answer)
        showResult = true
        completedCount += 1
        if isCorrect {
            correctCount += 1
            combo += 1
        } else {
            combo = 0
        }

        // SM-2
        let quality = isCorrect ? 4 : 1
        let sm2 = SM2Engine.calculateNext(
            quality: quality,
            previousEase: 2.5,
            previousInterval: 0,
            repetition: 0
        )
        let record = ReviewRecord(
            card: card,
            result: isCorrect ? .correct : .wrong,
            ease: sm2.ease,
            interval: sm2.interval,
            nextReviewDate: sm2.nextReviewDate
        )
        modelContext.insert(record)

        // Points
        if let profile {
            let points = PointsService.pointsForAnswer(correct: isCorrect, combo: combo)
            profile.totalPoints += points
        }
    }

    func submitTypedAnswer(typed: String, modelContext: ModelContext, profile: UserProfile?) {
        guard let card = currentCard else { return }
        let result = SpellingChecker.check(typed: typed, expected: card.answer)
        isCorrect = result.isCorrect
        charResults = result.charResults
        showResult = true
        completedCount += 1
        if isCorrect {
            correctCount += 1
            combo += 1
        } else {
            combo = 0
        }

        // SM-2
        let quality = isCorrect ? 4 : 1
        let sm2 = SM2Engine.calculateNext(
            quality: quality,
            previousEase: 2.5,
            previousInterval: 0,
            repetition: 0
        )
        let record = ReviewRecord(
            card: card,
            result: isCorrect ? .correct : .wrong,
            ease: sm2.ease,
            interval: sm2.interval,
            nextReviewDate: sm2.nextReviewDate
        )
        modelContext.insert(record)

        // Points
        if let profile {
            let points = PointsService.pointsForAnswer(correct: isCorrect, combo: combo)
            profile.totalPoints += points
        }
    }

    func next() {
        currentIndex += 1
        advanceToNext()
    }

    func retry() {
        showResult = false
        charResults = []
        completedCount -= 1 // Don't double count
    }

    private func selectRandomContext(for card: Card) -> CardContext? {
        let available = card.contexts.filter { !usedContextIds.contains($0.id) }
        let selected = (available.isEmpty ? card.contexts : available).randomElement()
        if let selected { usedContextIds.insert(selected.id) }
        return selected
    }
}
