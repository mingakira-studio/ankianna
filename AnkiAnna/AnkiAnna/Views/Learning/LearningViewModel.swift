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
    private var characterStatsMap: [String: CharacterStats] = [:]

    /// Load due cards using SM-2 scheduling from CharacterStats
    func loadDueCards(allCards: [Card], characterStats: [CharacterStats], dailyGoal: Int) {
        // Build character -> stats map (keep first occurrence for duplicates)
        characterStatsMap = [:]
        for stats in characterStats {
            if characterStatsMap[stats.character] == nil {
                characterStatsMap[stats.character] = stats
            }
        }

        // Build schedules from CharacterStats for SM-2 selection
        let schedules = characterStats.map { stats in
            SM2Engine.CardSchedule(
                cardId: stats.id,
                nextReviewDate: stats.nextReviewDate,
                ease: stats.ease,
                interval: stats.interval,
                repetition: stats.repetition
            )
        }
        let dueSchedules = SM2Engine.selectDueCards(from: schedules, limit: dailyGoal)
        let dueCharacters = Set(dueSchedules.compactMap { schedule in
            characterStats.first(where: { $0.id == schedule.cardId })?.character
        })

        // Select cards matching due characters
        var selected = allCards.filter { dueCharacters.contains($0.answer) }
        if selected.count < dailyGoal {
            let remaining = allCards.filter { !dueCharacters.contains($0.answer) }.shuffled()
            selected.append(contentsOf: remaining.prefix(dailyGoal - selected.count))
        }

        dueCards = selected
        totalCount = dueCards.count
        currentIndex = 0
        completedCount = 0
        correctCount = 0
        combo = 0
        sessionComplete = false
        usedContextIds = []
        if !dueCards.isEmpty {
            advanceToNext()
        }
    }

    /// Backward-compatible: load cards without SM-2 scheduling (for tests or no CharacterStats)
    func loadDueCards(from cards: [Card], dailyGoal: Int) {
        characterStatsMap = [:]
        dueCards = Array(cards.prefix(dailyGoal))
        totalCount = dueCards.count
        currentIndex = 0
        completedCount = 0
        correctCount = 0
        combo = 0
        sessionComplete = false
        usedContextIds = []
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

        // Look up CharacterStats for real SM-2 state
        let stats = characterStatsMap[card.answer]
        let quality = isCorrect ? 4 : 1
        let sm2 = SM2Engine.calculateNext(
            quality: quality,
            previousEase: stats?.ease ?? 2.5,
            previousInterval: stats?.interval ?? 0,
            repetition: stats?.repetition ?? 0
        )
        let record = ReviewRecord(
            card: card,
            result: isCorrect ? .correct : .wrong,
            ease: sm2.ease,
            interval: sm2.interval,
            repetition: sm2.repetition,
            nextReviewDate: sm2.nextReviewDate
        )
        modelContext.insert(record)

        // Update CharacterStats
        stats?.recordReview(correct: isCorrect, reviewOutput: sm2)

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

        // Look up CharacterStats for real SM-2 state
        let stats = characterStatsMap[card.answer]
        let quality = isCorrect ? 4 : 1
        let sm2 = SM2Engine.calculateNext(
            quality: quality,
            previousEase: stats?.ease ?? 2.5,
            previousInterval: stats?.interval ?? 0,
            repetition: stats?.repetition ?? 0
        )
        let record = ReviewRecord(
            card: card,
            result: isCorrect ? .correct : .wrong,
            ease: sm2.ease,
            interval: sm2.interval,
            repetition: sm2.repetition,
            nextReviewDate: sm2.nextReviewDate
        )
        modelContext.insert(record)

        // Update CharacterStats
        stats?.recordReview(correct: isCorrect, reviewOutput: sm2)

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
