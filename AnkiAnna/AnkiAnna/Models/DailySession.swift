import Foundation
import SwiftData

@Model
final class DailySession {
    var id: UUID
    var date: Date
    var targetCount: Int
    var completedCount: Int
    var correctCount: Int
    var newMastered: Int
    var streak: Int
    var gameMode: String?

    init(date: Date, targetCount: Int) {
        self.id = UUID()
        self.date = date
        self.targetCount = targetCount
        self.completedCount = 0
        self.correctCount = 0
        self.newMastered = 0
        self.streak = 0
        self.gameMode = nil
    }
}
