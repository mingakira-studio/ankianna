import Foundation
import SwiftData

@Observable
class TimeAttackViewModel {
    var remainingTime: Int
    var isRunning = false
    var isGameOver = false
    var score: Int = 0
    var answeredCount: Int = 0
    var correctCount: Int = 0
    var combo: Int = 0
    var bestCombo: Int = 0
    var currentCard: Card?
    var currentContext: CardContext?
    var showResult = false
    var isCorrect = false

    private var cards: [Card] = []
    private var currentIndex = 0
    private let bonusTime = 3

    init(duration: Int) {
        self.remainingTime = duration
    }

    func start(cards: [Card]) {
        self.cards = cards.shuffled()
        currentIndex = 0
        isRunning = true
        advanceToNext()
    }

    func tick() {
        if remainingTime > 0 {
            remainingTime -= 1
        }
        if remainingTime <= 0 {
            isRunning = false
            isGameOver = true
        }
    }

    func handleCorrectAnswer() {
        combo += 1
        bestCombo = max(bestCombo, combo)
        correctCount += 1
        answeredCount += 1
        score += PointsService.pointsForAnswer(correct: true, combo: combo)
        remainingTime += bonusTime
        isCorrect = true
        showResult = true
    }

    func handleWrongAnswer() {
        combo = 0
        answeredCount += 1
        isCorrect = false
        showResult = true
    }

    func next() {
        showResult = false
        currentIndex += 1
        if currentIndex >= cards.count {
            currentIndex = 0
            cards.shuffle()
        }
        advanceToNext()
    }

    private func advanceToNext() {
        guard currentIndex < cards.count else { return }
        currentCard = cards[currentIndex]
        currentContext = currentCard?.contexts.randomElement()
    }
}
