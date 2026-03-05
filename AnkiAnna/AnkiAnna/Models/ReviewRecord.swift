import Foundation
import SwiftData

enum ReviewResult: String, Codable {
    case correct
    case wrong
}

@Model
final class ReviewRecord {
    var id: UUID
    var card: Card?
    var reviewedAt: Date
    var result: ReviewResult
    var ease: Double
    var interval: Int
    var nextReviewDate: Date
    var handwritingImage: Data?

    init(
        card: Card,
        result: ReviewResult,
        ease: Double,
        interval: Int,
        nextReviewDate: Date
    ) {
        self.id = UUID()
        self.card = card
        self.reviewedAt = Date()
        self.result = result
        self.ease = ease
        self.interval = interval
        self.nextReviewDate = nextReviewDate
    }
}
