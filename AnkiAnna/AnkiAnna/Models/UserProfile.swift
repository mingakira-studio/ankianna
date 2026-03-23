import Foundation
import SwiftData

@Model
final class UserProfile {
    var id: UUID
    var name: String
    var dailyGoal: Int
    var totalPoints: Int
    var badges: [String]

    init(name: String, dailyGoal: Int = 8) {
        self.id = UUID()
        self.name = name
        self.dailyGoal = dailyGoal
        self.totalPoints = 0
        self.badges = []
    }
}
