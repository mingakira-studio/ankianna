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
        XCTAssertEqual(viewModel.currentCard?.answer, "apple")
        XCTAssertEqual(viewModel.currentContext?.fullText, "an apple")
    }

    func testSubmitTypedAnswerCorrectUpdatesRecordAndPoints() throws {
        let viewModel = LearningViewModel()
        let context = container.mainContext
        let card = makeEnglishCard(answer: "apple", text: "an ___", fullText: "an apple")
        let profile = UserProfile(name: "Anna", dailyGoal: 15)
        context.insert(card)
        context.insert(profile)

        viewModel.loadDueCards(from: [card], dailyGoal: 1)
        viewModel.submitTypedAnswer(typed: "apple", modelContext: context, profile: profile)

        let records = try context.fetch(FetchDescriptor<ReviewRecord>())
        XCTAssertTrue(viewModel.isCorrect)
        XCTAssertTrue(viewModel.showResult)
        XCTAssertEqual(viewModel.completedCount, 1)
        XCTAssertEqual(viewModel.correctCount, 1)
        XCTAssertEqual(viewModel.combo, 1)
        XCTAssertEqual(profile.totalPoints, 11)
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first?.result, .correct)
    }

    func testSubmitTypedAnswerWrongResetsComboAndStoresWrongRecord() throws {
        let viewModel = LearningViewModel()
        let context = container.mainContext
        let card = makeEnglishCard(answer: "apple", text: "an ___", fullText: "an apple")
        let profile = UserProfile(name: "Anna", dailyGoal: 15)
        context.insert(card)
        context.insert(profile)

        viewModel.combo = 3
        viewModel.loadDueCards(from: [card], dailyGoal: 1)
        viewModel.submitTypedAnswer(typed: "pear", modelContext: context, profile: profile)

        let records = try context.fetch(FetchDescriptor<ReviewRecord>())
        XCTAssertFalse(viewModel.isCorrect)
        XCTAssertTrue(viewModel.showResult)
        XCTAssertEqual(viewModel.completedCount, 1)
        XCTAssertEqual(viewModel.correctCount, 0)
        XCTAssertEqual(viewModel.combo, 0)
        XCTAssertEqual(profile.totalPoints, 0)
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first?.result, .wrong)
    }

    func testSubmitHandwritingAnswerUsesParallelPath() throws {
        let viewModel = LearningViewModel()
        let context = container.mainContext
        let card = makeChineseCard(answer: "大", text: "___人", fullText: "大人")
        let profile = UserProfile(name: "Anna", dailyGoal: 15)
        context.insert(card)
        context.insert(profile)

        viewModel.loadDueCards(from: [card], dailyGoal: 1)
        viewModel.submitAnswer(recognized: "大", modelContext: context, profile: profile)

        let records = try context.fetch(FetchDescriptor<ReviewRecord>())
        XCTAssertTrue(viewModel.isCorrect)
        XCTAssertEqual(viewModel.correctCount, 1)
        XCTAssertEqual(profile.totalPoints, 11)
        XCTAssertEqual(records.first?.result, .correct)
    }

    func testRetryClearsResultAndRevertsCompletedCount() {
        let viewModel = LearningViewModel()
        let context = container.mainContext
        let card = makeEnglishCard(answer: "apple", text: "an ___", fullText: "an apple")

        viewModel.loadDueCards(from: [card], dailyGoal: 1)
        viewModel.submitTypedAnswer(typed: "pear", modelContext: context, profile: nil)
        XCTAssertEqual(viewModel.completedCount, 1)
        XCTAssertFalse(viewModel.charResults.isEmpty)

        viewModel.retry()

        XCTAssertFalse(viewModel.showResult)
        XCTAssertTrue(viewModel.charResults.isEmpty)
        XCTAssertEqual(viewModel.completedCount, 0)
    }

    func testNextMarksSessionCompleteAfterLastCard() {
        let viewModel = LearningViewModel()
        let card = makeEnglishCard(answer: "apple", text: "an ___", fullText: "an apple")

        viewModel.loadDueCards(from: [card], dailyGoal: 1)
        viewModel.next()

        XCTAssertTrue(viewModel.sessionComplete)
    }

    // MARK: - SM-2 Integration Tests

    func testLoadDueCardsWithCharacterStatsUsesSM2() {
        let viewModel = LearningViewModel()
        let card = makeChineseCard(answer: "大", text: "___人", fullText: "大人")
        let stats = CharacterStats(
            character: "大", grade: 1, semester: "upper",
            lesson: 1, lessonTitle: "天地人", words: ["大人"]
        )
        // Stats with no nextReviewDate = due (new card)
        viewModel.loadDueCards(allCards: [card], characterStats: [stats], dailyGoal: 1)
        XCTAssertEqual(viewModel.totalCount, 1)
        XCTAssertEqual(viewModel.currentCard?.answer, "大")
    }

    func testSubmitAnswerUpdatesCharacterStats() throws {
        let viewModel = LearningViewModel()
        let context = container.mainContext
        let card = makeChineseCard(answer: "大", text: "___人", fullText: "大人")
        let stats = CharacterStats(
            character: "大", grade: 1, semester: "upper",
            lesson: 1, lessonTitle: "天地人", words: ["大人"]
        )
        let profile = UserProfile(name: "Anna", dailyGoal: 15)
        context.insert(card)
        context.insert(stats)
        context.insert(profile)

        viewModel.loadDueCards(allCards: [card], characterStats: [stats], dailyGoal: 1)
        viewModel.submitAnswer(recognized: "大", modelContext: context, profile: profile)

        // CharacterStats should be updated
        XCTAssertEqual(stats.practiceCount, 1)
        XCTAssertEqual(stats.correctCount, 1)
        XCTAssertEqual(stats.repetition, 1)
        XCTAssertEqual(stats.masteryLevel, .learning)
        XCTAssertNotNil(stats.nextReviewDate)
    }

    func testSubmitTypedAnswerUpdatesCharacterStats() throws {
        let viewModel = LearningViewModel()
        let context = container.mainContext
        let card = makeEnglishCard(answer: "cat", text: "a ___", fullText: "a cat")
        let stats = CharacterStats(
            character: "cat", grade: 1, semester: "upper",
            lesson: 1, lessonTitle: "Animals", words: ["cat"]
        )
        let profile = UserProfile(name: "Anna", dailyGoal: 15)
        context.insert(card)
        context.insert(stats)
        context.insert(profile)

        viewModel.loadDueCards(allCards: [card], characterStats: [stats], dailyGoal: 1)
        viewModel.submitTypedAnswer(typed: "cat", modelContext: context, profile: profile)

        XCTAssertEqual(stats.practiceCount, 1)
        XCTAssertEqual(stats.correctCount, 1)
        XCTAssertEqual(stats.repetition, 1)
    }

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
