import Foundation
import SwiftData

enum BattleAnimState: Equatable {
    case idle
    case dragonAttack
    case monsterAttack
}

struct MonsterInfo {
    let character: String
    let isBoss: Bool
    var isDefeated: Bool = false
}

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

    // Level selection
    var levels: [LevelInfo] = []
    var currentLevel: LevelInfo?

    // Battle state
    var currentCards: [Card] = []
    var currentIndex: Int = 0
    var totalCount: Int = 0
    var isPlaying: Bool = false
    var isLevelComplete: Bool = false
    var isGameOver: Bool = false // Dragon lost all HP
    var showResult: Bool = false
    var isCorrect: Bool = false
    var currentCard: Card?
    var currentContext: CardContext?

    // HP system
    var dragonHp: Int = 3
    var monsterHp: Int = 1
    var monsterMaxHp: Int = 1
    var isCurrentBoss: Bool = false
    var defeatedCount: Int = 0
    var errorCount: Int = 0

    // Animation
    var battleAnimState: BattleAnimState = .idle
    var monsterState: MonsterState = .idle

    // Monster grid
    var allMonsters: [MonsterInfo] = []

    // MARK: - Level Loading

    func loadLevels(stats: [CharacterStats], progress: [LevelProgress]) {
        var lessonMap: [String: (grade: Int, semester: String, lesson: Int, title: String, count: Int)] = [:]
        for stat in stats {
            let key = "\(stat.grade)-\(stat.semester)-\(stat.lesson)"
            if lessonMap[key] == nil {
                lessonMap[key] = (stat.grade, stat.semester, stat.lesson, stat.lessonTitle, 1)
            } else {
                lessonMap[key]!.count += 1
            }
        }

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

    // MARK: - Start Level

    func startLevel(_ level: LevelInfo, cards: [Card], stats: [CharacterStats]) {
        currentLevel = level

        // Filter cards for this lesson
        var levelCards = cards.filter { card in
            card.tags.contains(level.title)
        }
        if levelCards.isEmpty {
            levelCards = Array(cards.prefix(5))
        }

        // Sort by error rate (hardest last = boss)
        let statsMap = Dictionary(uniqueKeysWithValues: stats.map { ($0.character, $0) })
        levelCards.sort { a, b in
            let aRate = statsMap[a.answer]?.errorRate ?? 0
            let bRate = statsMap[b.answer]?.errorRate ?? 0
            return aRate < bRate
        }

        currentCards = levelCards
        totalCount = levelCards.count
        currentIndex = 0
        defeatedCount = 0
        errorCount = 0
        dragonHp = 3
        isPlaying = true
        isLevelComplete = false
        isGameOver = false
        showResult = false
        battleAnimState = .idle

        // Build monster grid
        allMonsters = levelCards.enumerated().map { idx, card in
            MonsterInfo(
                character: card.answer,
                isBoss: idx == levelCards.count - 1
            )
        }

        advanceToMonster()
    }

    // MARK: - Battle Actions

    func handleCorrectAnswer() {
        isCorrect = true
        showResult = true
        monsterHp -= 1

        // Dragon attacks
        battleAnimState = .dragonAttack
        monsterState = .hit
        HapticService.success()

        // Delay for animation then resolve
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.resolveAfterAnswer()
        }
    }

    func handleWrongAnswer() {
        isCorrect = false
        errorCount += 1
        showResult = true
        dragonHp -= 1

        // Monster attacks dragon
        battleAnimState = .monsterAttack
        monsterState = .attacking
        HapticService.error()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.resolveAfterAnswer()
        }
    }

    private func resolveAfterAnswer() {
        showResult = false
        battleAnimState = .idle
        monsterState = .idle

        if dragonHp <= 0 {
            isGameOver = true
            isPlaying = false
            return
        }

        if monsterHp <= 0 {
            // Monster defeated
            allMonsters[currentIndex].isDefeated = true
            monsterState = .defeated
            defeatedCount += 1
            currentIndex += 1

            if currentIndex >= currentCards.count {
                isLevelComplete = true
                isPlaying = false
            } else {
                advanceToMonster()
            }
        }
        // If monster still has HP (boss), stay on same monster
    }

    // MARK: - Navigation

    private func advanceToMonster() {
        guard currentIndex < currentCards.count else { return }
        currentCard = currentCards[currentIndex]
        currentContext = currentCard?.contexts.randomElement()

        isCurrentBoss = currentIndex == currentCards.count - 1
        monsterMaxHp = isCurrentBoss ? 2 : 1
        monsterHp = monsterMaxHp
        monsterState = .idle
    }

    func starsForCurrentLevel() -> Int {
        Self.starRating(errors: errorCount)
    }

    static func starRating(errors: Int) -> Int {
        switch errors {
        case 0: return 3
        case 1: return 2
        default: return 1
        }
    }

    func resetForRetry() {
        guard currentLevel != nil else { return }
        isGameOver = false
        isLevelComplete = false
    }
}
