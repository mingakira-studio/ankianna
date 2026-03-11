import Foundation
import SwiftData

@Model
final class LevelProgress {
    var id: UUID
    var grade: Int
    var semester: String
    var lesson: Int
    var isUnlocked: Bool
    var stars: Int
    var bestErrors: Int?

    init(grade: Int, semester: String, lesson: Int, isUnlocked: Bool = false) {
        self.id = UUID()
        self.grade = grade
        self.semester = semester
        self.lesson = lesson
        self.isUnlocked = isUnlocked
        self.stars = 0
        self.bestErrors = nil
    }
}
