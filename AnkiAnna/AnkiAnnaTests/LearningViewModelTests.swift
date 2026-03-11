import XCTest
import SwiftData
@testable import AnkiAnna

@MainActor
final class LearningViewModelTests: XCTestCase {
    var container: ModelContainer!

    override func setUp() {
        super.setUp()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try! ModelContainer(
            for: Card.self, ReviewRecord.self, DailySession.self, UserProfile.self, CharacterStats.self,
            configurations: config
        )
    }

    // MARK: - Load tests

    func testLoadDueCardsResetsStateAndSelectsFirstCard() {
        let viewModel = LearningViewModel()
        let cards = makeCards()

        viewModel.showResult = true
        viewModel.completedCount = 99
        viewModel.correctCount = 88
        viewModel.combo = 7
        viewModel.sessionComplete = true

        viewModel.loadDueCards(from: cards, dailyGoal: 2)

        XCTAssertEqual(viewModel.totalCount, 2)
        XCTAssertEqual(viewModel.completedCount, 0)
        XCTAssertEqual(viewModel.correctCount, 0)
        XCTAssertEqual(viewModel.combo, 0)
        XCTAssertFalse(viewModel.sessionComplete)
        XCTAssertFalse(viewModel.showResult)
        XCTAssertNotNil(viewModel.currentCard)
        XCTAssertNotNil(viewModel.currentContext)
    }

    func testLoadDueCardsWithCharacterStatsUsesSM2() {
        let viewModel = LearningViewModel()
        let card = makeChineseCard(answer: "大", text: "___人", fullText: "大人")
        let stats = CharacterStats(
            character: "大", grade: 1, semester: "upper",
            lesson: 1, lessonTitle: "天地人", words: ["大人"]
        )
        viewModel.loadDueCards(allCards: [card], characterStats: [stats], dailyGoal: 1)
        XCTAssertEqual(viewModel.totalCount, 1)
        XCTAssertEqual(viewModel.currentCard?.answer, "大")
    }

    func testLoadDueCardsFiltersMasteredCards() {
        let viewModel = LearningViewModel()
        let card1 = makeChineseCard(answer: "大", text: "___人", fullText: "大人")
        let card2 = makeChineseCard(answer: "小", text: "___人", fullText: "小人")
        let stats1 = CharacterStats(character: "大", grade: 1, semester: "upper", lesson: 1, lessonTitle: "天地人", words: ["大人"])
        stats1.markMastered()
        let stats2 = CharacterStats(character: "小", grade: 1, semester: "upper", lesson: 1, lessonTitle: "天地人", words: ["小人"])

        viewModel.loadDueCards(allCards: [card1, card2], characterStats: [stats1, stats2], dailyGoal: 2)
        XCTAssertEqual(viewModel.totalCount, 1)
        XCTAssertEqual(viewModel.currentCard?.answer, "小")
    }

    // MARK: - Queue consumption model

    func testQueueConsumptionRemovesFromFront() {
        let viewModel = LearningViewModel()
        let cards = [
            makeEnglishCard(answer: "apple", text: "an ___", fullText: "an apple"),
            makeEnglishCard(answer: "cat", text: "a ___", fullText: "a cat")
        ]
        viewModel.loadDueCards(from: cards, dailyGoal: 2)

        XCTAssertEqual(viewModel.currentCard?.answer, "apple")
        XCTAssertEqual(viewModel.queue.count, 1)  // one remaining after dequeue
    }

    // MARK: - Submit answer + SM-2

    func testSubmitAnswerCorrectUpdatesSM2AndSessionState() throws {
        let viewModel = LearningViewModel()
        let context = container.mainContext
        let card = makeChineseCard(answer: "大", text: "___人", fullText: "大人")
        let stats = CharacterStats(character: "大", grade: 1, semester: "upper", lesson: 1, lessonTitle: "天地人", words: ["大人"])
        let profile = UserProfile(name: "Anna", dailyGoal: 15)
        context.insert(card)
        context.insert(stats)
        context.insert(profile)

        viewModel.loadDueCards(allCards: [card], characterStats: [stats], dailyGoal: 1)
        viewModel.submitAnswer(recognized: "大", modelContext: context, profile: profile)

        XCTAssertTrue(viewModel.isCorrect)
        XCTAssertTrue(viewModel.showResult)
        XCTAssertEqual(viewModel.combo, 1)
        XCTAssertEqual(stats.practiceCount, 1)
        XCTAssertEqual(stats.correctCount, 1)
        XCTAssertEqual(stats.masteryLevel, .learning)

        let state = viewModel.sessionStates["大"]
        XCTAssertEqual(state?.consecutiveCorrect, 1)
        XCTAssertEqual(state?.consecutiveWrong, 0)
        XCTAssertFalse(state?.hasError ?? true)
    }

    func testSubmitAnswerWrongUpdatesSessionState() throws {
        let viewModel = LearningViewModel()
        let context = container.mainContext
        let card = makeChineseCard(answer: "大", text: "___人", fullText: "大人")
        let profile = UserProfile(name: "Anna", dailyGoal: 15)
        context.insert(card)
        context.insert(profile)

        viewModel.loadDueCards(from: [card], dailyGoal: 1)
        viewModel.submitAnswer(recognized: "", modelContext: context, profile: profile)

        XCTAssertFalse(viewModel.isCorrect)
        XCTAssertTrue(viewModel.showResult)
        XCTAssertEqual(viewModel.combo, 0)

        let state = viewModel.sessionStates["大"]
        XCTAssertEqual(state?.consecutiveWrong, 1)
        XCTAssertEqual(state?.consecutiveCorrect, 0)
        XCTAssertTrue(state?.hasError ?? false)
    }

    func testSubmitTypedAnswerCorrect() throws {
        let viewModel = LearningViewModel()
        let context = container.mainContext
        let card = makeEnglishCard(answer: "apple", text: "an ___", fullText: "an apple")
        let profile = UserProfile(name: "Anna", dailyGoal: 15)
        context.insert(card)
        context.insert(profile)

        viewModel.loadDueCards(from: [card], dailyGoal: 1)
        viewModel.submitTypedAnswer(typed: "apple", modelContext: context, profile: profile)

        XCTAssertTrue(viewModel.isCorrect)
        XCTAssertEqual(viewModel.combo, 1)
        XCTAssertEqual(profile.totalPoints, 11)

        let records = try context.fetch(FetchDescriptor<ReviewRecord>())
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first?.result, .correct)
    }

    // MARK: - Exit conditions

    func testThreeConsecutiveCorrectShowsMasteryPrompt() {
        let viewModel = LearningViewModel()
        let context = container.mainContext
        let card = makeChineseCard(answer: "大", text: "___人", fullText: "大人")
        let stats = CharacterStats(character: "大", grade: 1, semester: "upper", lesson: 1, lessonTitle: "天地人", words: ["大人"])
        stats.masteryLevel = .learning
        context.insert(card)
        context.insert(stats)

        viewModel.loadDueCards(allCards: [card], characterStats: [stats], dailyGoal: 1)

        // Answer correctly 3 times
        for _ in 0..<3 {
            viewModel.submitAnswer(recognized: "大", modelContext: context, profile: nil)
            if viewModel.showMasteryConfirmation { break }
            viewModel.next()  // reinserts card, advances to it
        }

        // On 3rd correct, next() should show mastery prompt
        viewModel.next()
        XCTAssertTrue(viewModel.showMasteryConfirmation)
    }

    func testConfirmMasteredMarksMasteredAndExitsCard() {
        let viewModel = LearningViewModel()
        let context = container.mainContext
        let card = makeChineseCard(answer: "大", text: "___人", fullText: "大人")
        let stats = CharacterStats(character: "大", grade: 1, semester: "upper", lesson: 1, lessonTitle: "天地人", words: ["大人"])
        stats.masteryLevel = .learning
        context.insert(card)
        context.insert(stats)

        viewModel.loadDueCards(allCards: [card], characterStats: [stats], dailyGoal: 1)

        // Get to mastery prompt
        for _ in 0..<3 {
            viewModel.submitAnswer(recognized: "大", modelContext: context, profile: nil)
            viewModel.next()
        }

        viewModel.confirmMastered()
        XCTAssertEqual(stats.masteryLevel, .mastered)
        XCTAssertFalse(viewModel.showMasteryConfirmation)
        XCTAssertEqual(viewModel.completedCount, 1)
        XCTAssertTrue(viewModel.sessionComplete)
    }

    func testDeclineMasteredExitsWithoutMarkingMastered() {
        let viewModel = LearningViewModel()
        let context = container.mainContext
        let card = makeChineseCard(answer: "大", text: "___人", fullText: "大人")
        let stats = CharacterStats(character: "大", grade: 1, semester: "upper", lesson: 1, lessonTitle: "天地人", words: ["大人"])
        stats.masteryLevel = .learning
        context.insert(card)
        context.insert(stats)

        viewModel.loadDueCards(allCards: [card], characterStats: [stats], dailyGoal: 1)

        for _ in 0..<3 {
            viewModel.submitAnswer(recognized: "大", modelContext: context, profile: nil)
            viewModel.next()
        }

        viewModel.declineMastered()
        XCTAssertEqual(stats.masteryLevel, .learning)
        XCTAssertEqual(viewModel.completedCount, 1)
        XCTAssertTrue(viewModel.sessionComplete)
    }

    func testThreeConsecutiveCorrectOnDifficultTransitionsToLearning() {
        let viewModel = LearningViewModel()
        let context = container.mainContext
        let card = makeChineseCard(answer: "大", text: "___人", fullText: "大人")
        let stats = CharacterStats(character: "大", grade: 1, semester: "upper", lesson: 1, lessonTitle: "天地人", words: ["大人"])
        stats.masteryLevel = .difficult
        context.insert(card)
        context.insert(stats)

        viewModel.loadDueCards(allCards: [card], characterStats: [stats], dailyGoal: 1)

        for _ in 0..<3 {
            viewModel.submitAnswer(recognized: "大", modelContext: context, profile: nil)
            viewModel.next()
        }

        // Should transition to learning and show exit feedback (no mastery prompt)
        XCTAssertFalse(viewModel.showMasteryConfirmation)
        XCTAssertEqual(stats.masteryLevel, .learning)
        XCTAssertTrue(viewModel.showCardExitFeedback)
        viewModel.dismissCardExitFeedback()
        XCTAssertEqual(viewModel.completedCount, 1)
        XCTAssertTrue(viewModel.sessionComplete)
    }

    func testHasErrorAndTwoConsecutiveCorrectExits() {
        let viewModel = LearningViewModel()
        let context = container.mainContext
        let card = makeChineseCard(answer: "大", text: "___人", fullText: "大人")
        context.insert(card)

        viewModel.loadDueCards(from: [card], dailyGoal: 1)

        // Wrong answer first → retry + practice
        viewModel.submitAnswer(recognized: "", modelContext: context, profile: nil)
        viewModel.retry()
        viewModel.submitPracticeAnswer(recognized: "大")
        viewModel.submitPracticeAnswer(recognized: "大")
        viewModel.submitPracticeAnswer(recognized: "大")

        // Now answer correctly 2 times
        viewModel.submitAnswer(recognized: "大", modelContext: context, profile: nil)
        viewModel.next()  // reinserts (only 1 consecutive correct + hasError, need 2)

        viewModel.submitAnswer(recognized: "大", modelContext: context, profile: nil)
        viewModel.next()  // 2 consecutive correct + hasError → shows exit feedback

        XCTAssertTrue(viewModel.showCardExitFeedback)
        viewModel.dismissCardExitFeedback()
        XCTAssertEqual(viewModel.completedCount, 1)
        XCTAssertTrue(viewModel.sessionComplete)
    }

    // MARK: - Practice mode

    func testWrongAnswerAndRetryEntersPracticeMode() {
        let viewModel = LearningViewModel()
        let context = container.mainContext
        let card = makeChineseCard(answer: "大", text: "___人", fullText: "大人")
        context.insert(card)

        viewModel.loadDueCards(from: [card], dailyGoal: 1)
        viewModel.submitAnswer(recognized: "", modelContext: context, profile: nil)
        viewModel.retry()

        XCTAssertTrue(viewModel.isInPracticeMode)
        XCTAssertEqual(viewModel.practicePhase, 1)
        XCTAssertEqual(viewModel.practicePhase1Count, 0)
        XCTAssertEqual(viewModel.practiceCorrectAnswer, "大")
    }

    func testPracticePhase1CorrectTwiceAdvancesToPhase2() {
        let viewModel = LearningViewModel()
        let context = container.mainContext
        let card = makeChineseCard(answer: "大", text: "___人", fullText: "大人")
        context.insert(card)

        viewModel.loadDueCards(from: [card], dailyGoal: 1)
        viewModel.submitAnswer(recognized: "", modelContext: context, profile: nil)
        viewModel.retry()

        // Phase 1: write correctly twice
        viewModel.submitPracticeAnswer(recognized: "大")
        XCTAssertEqual(viewModel.practicePhase1Count, 1)
        XCTAssertEqual(viewModel.practicePhase, 1)

        viewModel.submitPracticeAnswer(recognized: "大")
        XCTAssertEqual(viewModel.practicePhase1Count, 2)
        XCTAssertEqual(viewModel.practicePhase, 2)
    }

    func testPracticePhase1WrongDoesNotCount() {
        let viewModel = LearningViewModel()
        let context = container.mainContext
        let card = makeChineseCard(answer: "大", text: "___人", fullText: "大人")
        context.insert(card)

        viewModel.loadDueCards(from: [card], dailyGoal: 1)
        viewModel.submitAnswer(recognized: "", modelContext: context, profile: nil)
        viewModel.retry()

        viewModel.submitPracticeAnswer(recognized: "")  // wrong
        XCTAssertEqual(viewModel.practicePhase1Count, 0)
        XCTAssertEqual(viewModel.practiceIsCorrect, false)  // shows feedback
    }

    func testPracticePhase2CorrectCompletesPractice() {
        let viewModel = LearningViewModel()
        let context = container.mainContext
        let card = makeChineseCard(answer: "大", text: "___人", fullText: "大人")
        context.insert(card)

        viewModel.loadDueCards(from: [card], dailyGoal: 1)
        viewModel.submitAnswer(recognized: "", modelContext: context, profile: nil)
        viewModel.retry()

        // Phase 1: 2 correct
        viewModel.submitPracticeAnswer(recognized: "大")
        viewModel.submitPracticeAnswer(recognized: "大")

        // Phase 2: blind write correct
        viewModel.submitPracticeAnswer(recognized: "大")

        XCTAssertFalse(viewModel.isInPracticeMode)
        // Card reinserted then immediately dequeued as currentCard (single card scenario)
        XCTAssertEqual(viewModel.currentCard?.answer, "大", "Card should be reinserted and become current again")
    }

    func testPracticePhase2WrongResetsToPhase1() {
        let viewModel = LearningViewModel()
        let context = container.mainContext
        let card = makeChineseCard(answer: "大", text: "___人", fullText: "大人")
        context.insert(card)

        viewModel.loadDueCards(from: [card], dailyGoal: 1)
        viewModel.submitAnswer(recognized: "", modelContext: context, profile: nil)
        viewModel.retry()

        // Phase 1: 2 correct
        viewModel.submitPracticeAnswer(recognized: "大")
        viewModel.submitPracticeAnswer(recognized: "大")
        XCTAssertEqual(viewModel.practicePhase, 2)

        // Phase 2: wrong → back to phase 1
        viewModel.submitPracticeAnswer(recognized: "")
        XCTAssertEqual(viewModel.practicePhase, 1)
        XCTAssertEqual(viewModel.practicePhase1Count, 0)
    }

    func testPracticeDoesNotAffectSM2() throws {
        let viewModel = LearningViewModel()
        let context = container.mainContext
        let card = makeChineseCard(answer: "大", text: "___人", fullText: "大人")
        let stats = CharacterStats(character: "大", grade: 1, semester: "upper", lesson: 1, lessonTitle: "天地人", words: ["大人"])
        context.insert(card)
        context.insert(stats)

        viewModel.loadDueCards(allCards: [card], characterStats: [stats], dailyGoal: 1)

        // Main answer (wrong) → creates 1 ReviewRecord
        viewModel.submitAnswer(recognized: "", modelContext: context, profile: nil)
        let recordsBefore = try context.fetch(FetchDescriptor<ReviewRecord>())
        XCTAssertEqual(recordsBefore.count, 1)
        let statsBefore = stats.practiceCount

        // Practice (should NOT create ReviewRecords or update stats)
        viewModel.retry()
        viewModel.submitPracticeAnswer(recognized: "大")
        viewModel.submitPracticeAnswer(recognized: "大")
        viewModel.submitPracticeAnswer(recognized: "大")

        let recordsAfter = try context.fetch(FetchDescriptor<ReviewRecord>())
        XCTAssertEqual(recordsAfter.count, 1, "Practice should not create ReviewRecords")
        XCTAssertEqual(stats.practiceCount, statsBefore, "Practice should not update CharacterStats")
    }

    // MARK: - Three wrong → difficult

    func testThreeWrongsWithRetryMarksDifficult() {
        let viewModel = LearningViewModel()
        let context = container.mainContext
        let card = makeChineseCard(answer: "大", text: "___人", fullText: "大人")
        let stats = CharacterStats(character: "大", grade: 1, semester: "upper", lesson: 1, lessonTitle: "天地人", words: ["大人"])
        stats.masteryLevel = .learning
        context.insert(card)
        context.insert(stats)

        viewModel.loadDueCards(allCards: [card], characterStats: [stats], dailyGoal: 1)

        // Helper: wrong → retry → complete practice
        func wrongAndPractice() {
            viewModel.submitAnswer(recognized: "", modelContext: context, profile: nil)
            viewModel.retry()
            viewModel.submitPracticeAnswer(recognized: "大")  // phase1 correct 1
            viewModel.submitPracticeAnswer(recognized: "大")  // phase1 correct 2 → phase2
            viewModel.submitPracticeAnswer(recognized: "大")  // phase2 correct → completePractice
        }

        // 1st wrong + practice (totalWrong=1) → reinsert
        wrongAndPractice()
        XCTAssertEqual(stats.masteryLevel, .learning)

        // 2nd wrong + practice (totalWrong=2) → reinsert
        wrongAndPractice()
        XCTAssertEqual(stats.masteryLevel, .learning)

        // 3rd wrong + practice (totalWrong=3) → mark difficult
        wrongAndPractice()
        XCTAssertEqual(stats.masteryLevel, .difficult)
        XCTAssertTrue(viewModel.showDifficultyFeedback)
        viewModel.dismissDifficultyFeedback()
        XCTAssertTrue(viewModel.sessionComplete)
    }

    func testAccumulatedNonConsecutiveWrongsMarksDifficult() {
        let viewModel = LearningViewModel()
        let context = container.mainContext
        let card = makeChineseCard(answer: "大", text: "___人", fullText: "大人")
        let stats = CharacterStats(character: "大", grade: 1, semester: "upper", lesson: 1, lessonTitle: "天地人", words: ["大人"])
        stats.masteryLevel = .learning
        context.insert(card)
        context.insert(stats)

        viewModel.loadDueCards(allCards: [card], characterStats: [stats], dailyGoal: 1)

        // Helper: wrong → retry → complete practice
        func wrongAndPractice() {
            viewModel.submitAnswer(recognized: "", modelContext: context, profile: nil)
            viewModel.retry()
            viewModel.submitPracticeAnswer(recognized: "大")
            viewModel.submitPracticeAnswer(recognized: "大")
            viewModel.submitPracticeAnswer(recognized: "大")
        }

        // Wrong (totalWrong=1) → practice → reinsert
        wrongAndPractice()

        // Correct (totalWrong stays 1)
        viewModel.submitAnswer(recognized: "大", modelContext: context, profile: nil)
        viewModel.next()  // consecutiveCorrect=1, not enough to exit → reinsert

        // Wrong (totalWrong=2) → practice → reinsert
        wrongAndPractice()

        // Wrong (totalWrong=3) → practice → mark difficult
        wrongAndPractice()

        XCTAssertEqual(stats.masteryLevel, .difficult)
        XCTAssertTrue(viewModel.showDifficultyFeedback)
    }

    // MARK: - Reinsert after wrong

    func testWrongAnswerReinsertsCardAfterPractice() {
        let viewModel = LearningViewModel()
        let context = container.mainContext
        let card1 = makeChineseCard(answer: "大", text: "___人", fullText: "大人")
        let card2 = makeChineseCard(answer: "小", text: "___人", fullText: "小人")
        context.insert(card1)
        context.insert(card2)

        viewModel.loadDueCards(from: [card1, card2], dailyGoal: 2)
        let firstAnswer = viewModel.currentCard?.answer

        // Wrong answer on first card
        viewModel.submitAnswer(recognized: "", modelContext: context, profile: nil)
        viewModel.retry()

        // Complete practice
        viewModel.submitPracticeAnswer(recognized: firstAnswer!)
        viewModel.submitPracticeAnswer(recognized: firstAnswer!)
        viewModel.submitPracticeAnswer(recognized: firstAnswer!)

        // Practice complete → card reinserted, moved to next
        XCTAssertFalse(viewModel.isInPracticeMode)
        // Queue should have the reinserted card
        XCTAssertGreaterThanOrEqual(viewModel.queue.count, 1, "Wrong card should be reinserted")
    }

    // MARK: - Session complete

    func testSessionCompleteAfterAllCardsExit() {
        let viewModel = LearningViewModel()
        let context = container.mainContext
        let card = makeEnglishCard(answer: "cat", text: "a ___", fullText: "a cat")
        context.insert(card)

        viewModel.loadDueCards(from: [card], dailyGoal: 1)

        // Answer correctly 3 times to trigger mastery → exit
        for _ in 0..<3 {
            viewModel.submitTypedAnswer(typed: "cat", modelContext: context, profile: nil)
            viewModel.next()
        }
        viewModel.declineMastered()

        XCTAssertTrue(viewModel.sessionComplete)
        XCTAssertEqual(viewModel.completedCount, 1)
        XCTAssertEqual(viewModel.correctCount, 1)
    }

    // MARK: - Combo

    func testComboResetsOnWrongAnswer() {
        let viewModel = LearningViewModel()
        let context = container.mainContext
        let card = makeChineseCard(answer: "大", text: "___人", fullText: "大人")
        context.insert(card)

        viewModel.loadDueCards(from: [card], dailyGoal: 1)
        viewModel.submitAnswer(recognized: "大", modelContext: context, profile: nil)
        XCTAssertEqual(viewModel.combo, 1)

        viewModel.next()  // reinsert
        viewModel.submitAnswer(recognized: "", modelContext: context, profile: nil)
        XCTAssertEqual(viewModel.combo, 0)
    }

    // MARK: - ReviewRecord creation

    func testReviewRecordHasRepetitionField() throws {
        let viewModel = LearningViewModel()
        let context = container.mainContext
        let card = makeEnglishCard(answer: "apple", text: "an ___", fullText: "an apple")
        context.insert(card)

        viewModel.loadDueCards(from: [card], dailyGoal: 1)
        viewModel.submitTypedAnswer(typed: "apple", modelContext: context, profile: nil)

        let records = try context.fetch(FetchDescriptor<ReviewRecord>())
        XCTAssertEqual(records.first?.repetition, 1)
    }

    // MARK: - Session summary tracking

    func testCharacterSummaryRecordsFirstSeen() {
        let viewModel = LearningViewModel()
        let card = makeChineseCard(answer: "大", text: "___人", fullText: "大人")
        viewModel.loadDueCards(from: [card], dailyGoal: 1)

        XCTAssertEqual(viewModel.characterSummaries.count, 1)
        XCTAssertNotNil(viewModel.characterSummaries["大"])
        XCTAssertEqual(viewModel.summaryOrder, ["大"])
    }

    func testAnswerSequenceTracksMainFlowOnly() {
        let viewModel = LearningViewModel()
        let context = container.mainContext
        let card = makeChineseCard(answer: "大", text: "___人", fullText: "大人")
        context.insert(card)

        viewModel.loadDueCards(from: [card], dailyGoal: 1)

        // Wrong answer
        viewModel.submitAnswer(recognized: "", modelContext: context, profile: nil)
        XCTAssertEqual(viewModel.characterSummaries["大"]?.answerSequence, [false])

        // Practice (should NOT affect answer sequence)
        viewModel.retry()
        viewModel.submitPracticeAnswer(recognized: "大")
        viewModel.submitPracticeAnswer(recognized: "大")
        viewModel.submitPracticeAnswer(recognized: "大")

        XCTAssertEqual(viewModel.characterSummaries["大"]?.answerSequence, [false],
                       "Practice answers should not be tracked in answerSequence")

        // Correct main answer
        viewModel.submitAnswer(recognized: "大", modelContext: context, profile: nil)
        XCTAssertEqual(viewModel.characterSummaries["大"]?.answerSequence, [false, true])
    }

    func testExitReasonMastered() {
        let viewModel = LearningViewModel()
        let context = container.mainContext
        let card = makeChineseCard(answer: "大", text: "___人", fullText: "大人")
        let stats = CharacterStats(character: "大", grade: 1, semester: "upper", lesson: 1, lessonTitle: "天地人", words: ["大人"])
        stats.masteryLevel = .learning
        context.insert(card)
        context.insert(stats)

        viewModel.loadDueCards(allCards: [card], characterStats: [stats], dailyGoal: 1)

        for _ in 0..<3 {
            viewModel.submitAnswer(recognized: "大", modelContext: context, profile: nil)
            viewModel.next()
        }

        viewModel.confirmMastered()
        XCTAssertEqual(viewModel.characterSummaries["大"]?.exitReason, .mastered)
        XCTAssertGreaterThan(viewModel.characterSummaries["大"]?.accumulatedDuration ?? 0, 0)
    }

    func testExitReasonCompleted() {
        let viewModel = LearningViewModel()
        let context = container.mainContext
        let card = makeChineseCard(answer: "大", text: "___人", fullText: "大人")
        let stats = CharacterStats(character: "大", grade: 1, semester: "upper", lesson: 1, lessonTitle: "天地人", words: ["大人"])
        stats.masteryLevel = .learning
        context.insert(card)
        context.insert(stats)

        viewModel.loadDueCards(allCards: [card], characterStats: [stats], dailyGoal: 1)

        for _ in 0..<3 {
            viewModel.submitAnswer(recognized: "大", modelContext: context, profile: nil)
            viewModel.next()
        }

        viewModel.declineMastered()
        XCTAssertEqual(viewModel.characterSummaries["大"]?.exitReason, .completed)
    }

    func testExitReasonDifficult() {
        let viewModel = LearningViewModel()
        let context = container.mainContext
        let card = makeChineseCard(answer: "大", text: "___人", fullText: "大人")
        let stats = CharacterStats(character: "大", grade: 1, semester: "upper", lesson: 1, lessonTitle: "天地人", words: ["大人"])
        stats.masteryLevel = .learning
        context.insert(card)
        context.insert(stats)

        viewModel.loadDueCards(allCards: [card], characterStats: [stats], dailyGoal: 1)

        // Wrong 3 times via retry → practice
        for _ in 0..<3 {
            viewModel.submitAnswer(recognized: "", modelContext: context, profile: nil)
            viewModel.retry()
            viewModel.submitPracticeAnswer(recognized: "大")
            viewModel.submitPracticeAnswer(recognized: "大")
            viewModel.submitPracticeAnswer(recognized: "大")
        }

        viewModel.dismissDifficultyFeedback()
        XCTAssertEqual(viewModel.characterSummaries["大"]?.exitReason, .difficult)
        XCTAssertGreaterThan(viewModel.characterSummaries["大"]?.accumulatedDuration ?? 0, 0)
    }

    func testSessionTotalPointsAccumulates() {
        let viewModel = LearningViewModel()
        let context = container.mainContext
        let card = makeChineseCard(answer: "大", text: "___人", fullText: "大人")
        let profile = UserProfile(name: "Anna", dailyGoal: 15)
        context.insert(card)
        context.insert(profile)

        viewModel.loadDueCards(from: [card], dailyGoal: 1)

        // Correct answer with combo=1 → 10+1=11 points
        viewModel.submitAnswer(recognized: "大", modelContext: context, profile: profile)
        XCTAssertEqual(viewModel.sessionTotalPoints, 11)

        viewModel.next()
        // Correct again with combo=2 → 10+2=12 points
        viewModel.submitAnswer(recognized: "大", modelContext: context, profile: profile)
        XCTAssertEqual(viewModel.sessionTotalPoints, 23)
    }

    func testSessionAccuracyRate() {
        let viewModel = LearningViewModel()
        let context = container.mainContext
        let card = makeChineseCard(answer: "大", text: "___人", fullText: "大人")
        context.insert(card)

        viewModel.loadDueCards(from: [card], dailyGoal: 1)

        // 1 wrong → retry + practice → 1 correct in main flow → 50%
        viewModel.submitAnswer(recognized: "", modelContext: context, profile: nil)
        viewModel.retry()
        viewModel.submitPracticeAnswer(recognized: "大")
        viewModel.submitPracticeAnswer(recognized: "大")
        viewModel.submitPracticeAnswer(recognized: "大")
        // Card reinserted, now answer correctly
        viewModel.submitAnswer(recognized: "大", modelContext: context, profile: nil)

        XCTAssertEqual(viewModel.sessionAccuracyRate, 0.5, accuracy: 0.01)
    }

    func testOrderedSummariesPreservesOrder() {
        let viewModel = LearningViewModel()
        let context = container.mainContext
        let card1 = makeChineseCard(answer: "大", text: "___人", fullText: "大人")
        let card2 = makeChineseCard(answer: "小", text: "___人", fullText: "小人")
        context.insert(card1)
        context.insert(card2)

        viewModel.loadDueCards(from: [card1, card2], dailyGoal: 2)

        let firstChar = viewModel.currentCard?.answer ?? ""
        XCTAssertEqual(viewModel.orderedSummaries.first?.character, firstChar)
        XCTAssertEqual(viewModel.orderedSummaries.count, 1, "Only first card seen so far")
    }

    func testResetSessionClearsSummaries() {
        let viewModel = LearningViewModel()
        let card = makeChineseCard(answer: "大", text: "___人", fullText: "大人")

        viewModel.loadDueCards(from: [card], dailyGoal: 1)
        XCTAssertEqual(viewModel.characterSummaries.count, 1)

        // Load again to trigger reset
        viewModel.loadDueCards(from: [card], dailyGoal: 1)
        // Should have fresh summary (count still 1, but reset happened)
        XCTAssertEqual(viewModel.sessionTotalPoints, 0)
        XCTAssertEqual(viewModel.characterSummaries.count, 1)
    }

    func testFormatDuration() {
        XCTAssertEqual(LearningViewModel.formatDuration(0), "0:00")
        XCTAssertEqual(LearningViewModel.formatDuration(65), "1:05")
        XCTAssertEqual(LearningViewModel.formatDuration(630), "10:30")
    }

    // MARK: - Helpers

    private func makeCards() -> [Card] {
        [
            makeEnglishCard(answer: "apple", text: "an ___", fullText: "an apple"),
            makeChineseCard(answer: "大", text: "___人", fullText: "大人")
        ]
    }

    private func makeEnglishCard(answer: String, text: String, fullText: String) -> Card {
        let card = Card(type: .englishSpelling, answer: answer, audioText: answer)
        card.contexts = [CardContext(type: .phrase, text: text, fullText: fullText)]
        return card
    }

    private func makeChineseCard(answer: String, text: String, fullText: String) -> Card {
        let card = Card(type: .chineseWriting, answer: answer, audioText: answer)
        card.contexts = [CardContext(type: .phrase, text: text, fullText: fullText)]
        return card
    }
}
