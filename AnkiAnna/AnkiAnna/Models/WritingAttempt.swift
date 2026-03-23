import Foundation
import SwiftData

@Model
final class WritingAttempt {
    var id: UUID
    var character: String           // 写的哪个字
    var correct: Bool               // 是否正确
    var writingDuration: Double     // 从开始写到提交的秒数
    var gameMode: String            // quick/timeAttack/survival/levels/practice
    var timestamp: Date             // 写入时间
    var sessionId: String           // 同一次练习的分组ID

    init(character: String, correct: Bool, writingDuration: Double, gameMode: String, sessionId: String = "") {
        self.id = UUID()
        self.character = character
        self.correct = correct
        self.writingDuration = writingDuration
        self.gameMode = gameMode
        self.timestamp = Date()
        self.sessionId = sessionId
    }
}
