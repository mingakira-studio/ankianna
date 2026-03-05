import Foundation

enum SM2Engine {

    struct ReviewOutput {
        let interval: Int
        let ease: Double
        let repetition: Int
        let nextReviewDate: Date
    }

    struct CardSchedule {
        let cardId: UUID
        let nextReviewDate: Date?
        let ease: Double
        let interval: Int
        let repetition: Int
    }

    /// SM-2 algorithm: calculate next review interval
    /// - quality: 0-5 (0=complete failure, 5=perfect)
    static func calculateNext(
        quality: Int,
        previousEase: Double,
        previousInterval: Int,
        repetition: Int,
        now: Date = Date()
    ) -> ReviewOutput {
        let q = Double(min(max(quality, 0), 5))

        // Update ease factor
        var newEase = previousEase + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))
        newEase = max(newEase, 1.3)

        let newInterval: Int
        let newRepetition: Int

        if quality >= 3 {
            // Correct response
            switch repetition {
            case 0:
                newInterval = 1
            case 1:
                newInterval = 6
            default:
                newInterval = Int(round(Double(previousInterval) * newEase))
            }
            newRepetition = repetition + 1
        } else {
            // Incorrect - reset
            newInterval = 1
            newRepetition = 0
        }

        let nextDate = Calendar.current.date(byAdding: .day, value: newInterval, to: now)!

        return ReviewOutput(
            interval: newInterval,
            ease: newEase,
            repetition: newRepetition,
            nextReviewDate: nextDate
        )
    }

    static func isCorrect(quality: Int) -> Bool {
        quality >= 3
    }

    /// Select cards due for review, sorted by priority (overdue first, then new)
    static func selectDueCards(
        from schedules: [CardSchedule],
        limit: Int,
        now: Date = Date()
    ) -> [CardSchedule] {
        let due = schedules.filter { schedule in
            guard let nextDate = schedule.nextReviewDate else {
                return true // Never reviewed = due
            }
            return nextDate <= now
        }

        // Sort: overdue cards first (by how overdue), then new cards
        let sorted = due.sorted { a, b in
            let aDate = a.nextReviewDate ?? Date.distantPast
            let bDate = b.nextReviewDate ?? Date.distantPast
            return aDate < bDate
        }

        return Array(sorted.prefix(limit))
    }
}
