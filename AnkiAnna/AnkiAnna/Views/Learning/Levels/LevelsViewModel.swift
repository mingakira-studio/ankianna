import Foundation
import SwiftData

@Observable
class LevelsViewModel {
    struct LevelInfo: Identifiable {
        let id = UUID()
        let grade: Int
        let semester: String
        let lesson: Int
        let title: String
        let characterCount: Int
        var isUnlocked: Bool
        var stars: Int
    }

    var levels: [LevelInfo] = []
    var currentLevel: LevelInfo?
    var currentCards: [Card] = []
    var currentIndex: Int = 0
    var errorCount: Int = 0
    var totalCount: Int = 0
    var isPlaying: Bool = false
    var isLevelComplete: Bool = false
    var showResult: Bool = false
    var isCorrect: Bool = false
    var currentCard: Card?
    var currentContext: CardContext?

    static func starRating(errors: Int) -> Int {
        switch errors {
        case 0: return 3
        case 1: return 2
        default: return 1
        }
    }

    func loadLevels(stats: [CharacterStats], progress: [LevelProgress]) {
        // Group stats by lesson
        var lessonMap: [String: (grade: Int, semester: String, lesson: Int, title: String, count: Int)] = [:]
        for stat in stats {
            let key = "\(stat.grade)-\(stat.semester)-\(stat.lesson)"
            if lessonMap[key] == nil {
                lessonMap[key] = (stat.grade, stat.semester, stat.lesson, stat.lessonTitle, 1)
            } else {
                lessonMap[key]!.count += 1
            }
        }

        // Sort and build level info
        let sorted = lessonMap.values.sorted { a, b in
            if a.grade != b.grade { return a.grade < b.grade }
            if a.semester != b.semester { return a.semester < b.semester }
            return a.lesson < b.lesson
        }

        levels = sorted.enumerated().map { index, info in
            let prog = progress.first { $0.grade == info.grade && $0.semester == info.semester && $0.lesson == info.lesson }
            let unlocked = index == 0 || (prog?.isUnlocked ?? false)
            return LevelInfo(
                grade: info.grade,
                semester: info.semester,
                lesson: info.lesson,
                title: info.title,
                characterCount: info.count,
                isUnlocked: unlocked,
                stars: prog?.stars ?? 0
            )
        }
    }

    func isLevelUnlocked(grade: Int, semester: String, lesson: Int) -> Bool {
        levels.first { $0.grade == grade && $0.semester == semester && $0.lesson == lesson }?.isUnlocked ?? false
    }

    func startLevel(_ level: LevelInfo, cards: [Card]) {
        currentLevel = level
        // Filter cards for this lesson
        currentCards = cards.filter { card in
            card.tags.contains("grade:\(level.grade)") ||
            card.tags.contains("lesson:\(level.lesson)")
        }
        if currentCards.isEmpty {
            currentCards = Array(cards.prefix(5))
        }
        currentCards.shuffle()
        currentIndex = 0
        errorCount = 0
        totalCount = currentCards.count
        isPlaying = true
        isLevelComplete = false
        advanceToNext()
    }

    func handleCorrectAnswer() {
        isCorrect = true
        showResult = true
    }

    func handleWrongAnswer() {
        errorCount += 1
        isCorrect = false
        showResult = true
    }

    func next() {
        showResult = false
        currentIndex += 1
        if currentIndex >= currentCards.count {
            isLevelComplete = true
            isPlaying = false
        } else {
            advanceToNext()
        }
    }

    func starsForCurrentLevel() -> Int {
        Self.starRating(errors: errorCount)
    }

    private func advanceToNext() {
        guard currentIndex < currentCards.count else { return }
        currentCard = currentCards[currentIndex]
        currentContext = currentCard?.contexts.randomElement()
    }
}
