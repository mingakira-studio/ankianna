import Foundation
import SwiftData

enum MasteryLevel: String, Codable {
    case new
    case learning
    case difficult
    case mastered
}

@Model
final class CharacterStats {
    var id: UUID
    var character: String
    var grade: Int
    var semester: String
    var lesson: Int
    var lessonTitle: String
    var words: [String]

    var masteryLevel: MasteryLevel
    var practiceCount: Int
    var correctCount: Int
    var errorCount: Int
    var lastPracticed: Date?

    var ease: Double
    var interval: Int
    var repetition: Int
    var nextReviewDate: Date?

    var errorRate: Double {
        practiceCount > 0 ? Double(errorCount) / Double(practiceCount) : 0
    }

    init(character: String, grade: Int, semester: String, lesson: Int,
         lessonTitle: String, words: [String]) {
        self.id = UUID()
        self.character = character
        self.grade = grade
        self.semester = semester
        self.lesson = lesson
        self.lessonTitle = lessonTitle
        self.words = words
        self.masteryLevel = .new
        self.practiceCount = 0
        self.correctCount = 0
        self.errorCount = 0
        self.lastPracticed = nil
        self.ease = 2.5
        self.interval = 0
        self.repetition = 0
        self.nextReviewDate = nil
    }

    func markMastered() {
        masteryLevel = .mastered
    }

    func markDifficult() {
        masteryLevel = .difficult
    }

    func markLearning() {
        masteryLevel = .learning
    }

    func recordReview(correct: Bool, reviewOutput: SM2Engine.ReviewOutput) {
        practiceCount += 1
        if correct {
            correctCount += 1
        } else {
            errorCount += 1
        }
        lastPracticed = Date()
        ease = reviewOutput.ease
        interval = reviewOutput.interval
        repetition = reviewOutput.repetition
        nextReviewDate = reviewOutput.nextReviewDate
    }

    func resetMastery() {
        masteryLevel = .learning
        ease = 2.5
        interval = 0
        repetition = 0
        nextReviewDate = nil
    }
}
