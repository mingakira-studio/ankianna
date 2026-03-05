import Foundation

enum PointsService {
    static let dailyCompletionBonus = 50

    static func pointsForAnswer(correct: Bool, combo: Int) -> Int {
        guard correct else { return 0 }
        let bonus = min(combo, 10) // Cap combo at 10
        return 10 + bonus
    }
}
