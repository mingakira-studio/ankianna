import SwiftUI
import SwiftData
import PencilKit

@Observable
final class LearningViewModel {
    // MARK: - Public state

    var currentCard: Card?
    var currentContext: CardContext?
    var showResult: Bool = false
    var isCorrect: Bool = false
    var charResults: [SpellingChecker.CharResult] = []
    var sessionComplete: Bool = false
    var completedCount: Int = 0   // characters that exited the queue
    var correctCount: Int = 0     // characters that exited successfully
    var totalCount: Int = 0       // initial unique character count
    var combo: Int = 0

    // Practice mode
    var isInPracticeMode: Bool = false
    var practicePhase: Int = 0          // 1 = look-and-write, 2 = blind-write
    var practicePhase1Count: Int = 0
    var practiceCorrectAnswer: String = ""
    var practiceIsCorrect: Bool? = nil  // nil = awaiting input

    // Mastery confirmation
    var showMasteryConfirmation: Bool = false

    // Difficulty feedback
    var showDifficultyFeedback: Bool = false

    // MARK: - Internal state (private(set) for testing)

    private(set) var queue: [Card] = []
    private var usedContextIds: Set<UUID> = []
    private(set) var characterStatsMap: [String: CharacterStats] = [:]
    private(set) var sessionStates: [String: CharacterSessionState] = [:]

    struct CharacterSessionState {
        var consecutiveCorrect: Int = 0
        var consecutiveWrong: Int = 0
        var hasError: Bool = false
    }

    // MARK: - Load

    /// Load due cards using SM-2 scheduling, filtering mastered, difficult first
    func loadDueCards(allCards: [Card], characterStats: [CharacterStats], dailyGoal: Int) {
        characterStatsMap = [:]
        for stats in characterStats {
            if characterStatsMap[stats.character] == nil {
                characterStatsMap[stats.character] = stats
            }
        }

        let nonMastered = characterStats.filter { $0.masteryLevel != .mastered }
        let schedules = nonMastered.map { stats in
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
            nonMastered.first(where: { $0.id == schedule.cardId })?.character
        })

        var selected = allCards.filter { dueCharacters.contains($0.answer) }
        if selected.count < dailyGoal {
            let remaining = allCards
                .filter { !dueCharacters.contains($0.answer) }
                .filter { characterStatsMap[$0.answer]?.masteryLevel != .mastered }
                .shuffled()
            selected.append(contentsOf: remaining.prefix(dailyGoal - selected.count))
        }

        // Difficult cards first
        let difficult = selected.filter { characterStatsMap[$0.answer]?.masteryLevel == .difficult }.shuffled()
        let others = selected.filter { characterStatsMap[$0.answer]?.masteryLevel != .difficult }.shuffled()

        resetSession()
        queue = difficult + others
        totalCount = queue.count
        advanceToNextCard()
    }

    /// Backward-compatible: load cards without SM-2 scheduling
    func loadDueCards(from cards: [Card], dailyGoal: Int) {
        characterStatsMap = [:]
        resetSession()
        queue = Array(cards.prefix(dailyGoal))
        totalCount = queue.count
        advanceToNextCard()
    }

    private func resetSession() {
        completedCount = 0
        correctCount = 0
        combo = 0
        sessionComplete = false
        usedContextIds = []
        sessionStates = [:]
        isInPracticeMode = false
        showMasteryConfirmation = false
        showDifficultyFeedback = false
        showResult = false
        isCorrect = false
        charResults = []
    }

    // MARK: - Main flow answer submission

    func submitAnswer(recognized: String, modelContext: ModelContext, profile: UserProfile?) {
        guard let card = currentCard else { return }
        isCorrect = HandwritingRecognizer.matches(recognized: recognized, expected: card.answer)
        showResult = true
        processMainAnswer(card: card, modelContext: modelContext, profile: profile)
    }

    func submitTypedAnswer(typed: String, modelContext: ModelContext, profile: UserProfile?) {
        guard let card = currentCard else { return }
        let result = SpellingChecker.check(typed: typed, expected: card.answer)
        isCorrect = result.isCorrect
        charResults = result.charResults
        showResult = true
        processMainAnswer(card: card, modelContext: modelContext, profile: profile)
    }

    private func processMainAnswer(card: Card, modelContext: ModelContext, profile: UserProfile?) {
        // Update session state
        var state = sessionStates[card.answer] ?? CharacterSessionState()
        if isCorrect {
            state.consecutiveCorrect += 1
            state.consecutiveWrong = 0
            combo += 1
        } else {
            state.consecutiveWrong += 1
            state.consecutiveCorrect = 0
            state.hasError = true
            combo = 0
        }
        sessionStates[card.answer] = state

        // SM-2 scoring
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

        stats?.recordReview(correct: isCorrect, reviewOutput: sm2)
        if stats?.masteryLevel == .new {
            stats?.markLearning()
        }

        // Points
        if let profile {
            let points = PointsService.pointsForAnswer(correct: isCorrect, combo: combo)
            profile.totalPoints += points
        }
    }

    // MARK: - After result actions

    /// Called when user taps "下一个" after correct, or "跳过" after wrong
    func next() {
        guard let card = currentCard else { return }

        if isCorrect {
            let state = sessionStates[card.answer] ?? CharacterSessionState()
            let masteryLevel = characterStatsMap[card.answer]?.masteryLevel ?? .learning

            if state.consecutiveCorrect >= 3 {
                if masteryLevel == .difficult {
                    characterStatsMap[card.answer]?.markLearning()
                    exitCard(asCorrect: true)
                } else {
                    showMasteryConfirmation = true
                }
            } else if state.hasError && state.consecutiveCorrect >= 2 {
                exitCard(asCorrect: true)
            } else {
                // Not ready to exit, keep practicing
                reinsertCard(card)
                advanceToNextCard()
            }
        } else {
            // Skip practice, just reinsert
            reinsertCard(card)
            advanceToNextCard()
        }
    }

    /// Called when user taps "再试一次" after wrong → enters practice mode
    func retry() {
        guard let card = currentCard else { return }
        enterPracticeMode(for: card)
    }

    // MARK: - Mastery confirmation

    func confirmMastered() {
        characterStatsMap[currentCard?.answer ?? ""]?.markMastered()
        showMasteryConfirmation = false
        exitCard(asCorrect: true)
    }

    func declineMastered() {
        showMasteryConfirmation = false
        exitCard(asCorrect: true)
    }

    // MARK: - Practice mode

    private func enterPracticeMode(for card: Card) {
        isInPracticeMode = true
        practicePhase = 1
        practicePhase1Count = 0
        practiceCorrectAnswer = card.answer
        practiceIsCorrect = nil
        showResult = false
    }

    func submitPracticeAnswer(recognized: String) {
        let correct = HandwritingRecognizer.matches(recognized: recognized, expected: practiceCorrectAnswer)
        handlePracticeResult(correct: correct)
    }

    func submitPracticeTypedAnswer(typed: String) {
        let correct = typed.lowercased().trimmingCharacters(in: .whitespaces)
            == practiceCorrectAnswer.lowercased()
        handlePracticeResult(correct: correct)
    }

    func clearPracticeFeedback() {
        practiceIsCorrect = nil
    }

    private func handlePracticeResult(correct: Bool) {
        practiceIsCorrect = correct

        if practicePhase == 1 {
            if correct {
                practicePhase1Count += 1
                if practicePhase1Count >= 2 {
                    practicePhase = 2
                }
                practiceIsCorrect = nil  // ready for next attempt
            }
            // Wrong in phase 1: stay, UI shows feedback via practiceIsCorrect == false
        } else {
            // Phase 2: blind write
            if correct {
                completePractice()
            } else {
                // Failed blind write → back to phase 1
                practicePhase = 1
                practicePhase1Count = 0
                practiceIsCorrect = nil
            }
        }
    }

    private func completePractice() {
        guard let card = currentCard else { return }
        let state = sessionStates[card.answer] ?? CharacterSessionState()

        isInPracticeMode = false
        practiceIsCorrect = nil

        if state.consecutiveWrong >= 3 {
            characterStatsMap[card.answer]?.markDifficult()
            showDifficultyFeedback = true
            exitCard(asCorrect: false)
        } else {
            reinsertCard(card)
            advanceToNextCard()
        }
    }

    // MARK: - Queue management

    private func advanceToNextCard() {
        showResult = false
        isCorrect = false
        charResults = []
        practiceIsCorrect = nil
        showDifficultyFeedback = false

        if queue.isEmpty {
            currentCard = nil
            currentContext = nil
            if totalCount > 0 {
                sessionComplete = true
            }
            return
        }

        currentCard = queue.removeFirst()
        currentContext = selectRandomContext(for: currentCard!)
    }

    private func exitCard(asCorrect: Bool) {
        completedCount += 1
        if asCorrect {
            correctCount += 1
        }
        advanceToNextCard()
    }

    private func reinsertCard(_ card: Card) {
        if queue.isEmpty {
            queue.append(card)
        } else {
            let insertIndex = Int.random(in: 1...queue.count)
            queue.insert(card, at: insertIndex)
        }
    }

    private func selectRandomContext(for card: Card) -> CardContext? {
        let available = card.contexts.filter { !usedContextIds.contains($0.id) }
        let selected = (available.isEmpty ? card.contexts : available).randomElement()
        if let selected { usedContextIds.insert(selected.id) }
        return selected
    }
}
