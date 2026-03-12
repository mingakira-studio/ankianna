import Foundation
import SwiftData

@Observable
class SurvivalViewModel {
    var lives: Int = 3
    var survivedCount: Int = 0
    var combo: Int = 0
    var bestCombo: Int = 0
    var isGameOver: Bool = false
    var currentCard: Card?
    var currentContext: CardContext?
    var showResult = false
    var isCorrect = false

    private var cards: [Card] = []
    private var currentIndex = 0
    private(set) var consecutiveCorrect = 0

    var currentMaxGrade: Int {
        min(5, 2 + survivedCount / 10)
    }

    func start(cards: [Card]) {
        self.cards = cards.shuffled()
        currentIndex = 0
        advanceToNext()
    }

    func handleCorrectAnswer() {
        combo += 1
        bestCombo = max(bestCombo, combo)
        survivedCount += 1
        consecutiveCorrect += 1
        isCorrect = true
        showResult = true
        HapticService.success()
        if consecutiveCorrect >= 5 && lives < 3 {
            lives += 1
            consecutiveCorrect = 0
        }
    }

    func handleWrongAnswer() {
        combo = 0
        consecutiveCorrect = 0
        lives -= 1
        isCorrect = false
        showResult = true
        HapticService.error()
        if lives <= 0 {
            isGameOver = true
        }
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
