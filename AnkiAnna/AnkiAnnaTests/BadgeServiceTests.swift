import XCTest
@testable import AnkiAnna

final class BadgeServiceTests: XCTestCase {
    // MARK: - Badge Definition

    func testAllBadgesHaveUniqueIds() {
        let ids = Badge.allCases.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count, "Badge IDs must be unique")
    }

    func testAllBadgesHaveNames() {
        for badge in Badge.allCases {
            XCTAssertFalse(badge.name.isEmpty, "\(badge) should have a name")
            XCTAssertFalse(badge.icon.isEmpty, "\(badge) should have an icon")
        }
    }

    // MARK: - Unlock Logic

    func testFirstLearningBadge() {
        let stats = BadgeService.Stats(totalReviews: 1, correctReviews: 1, streak: 0, totalPoints: 10)
        let unlocked = BadgeService.checkNewBadges(stats: stats, existingBadges: [])
        XCTAssertTrue(unlocked.contains(.firstStep), "Should unlock firstStep badge on first review")
    }

    func testFirstLearningBadgeNotDuplicated() {
        let stats = BadgeService.Stats(totalReviews: 5, correctReviews: 3, streak: 0, totalPoints: 50)
        let unlocked = BadgeService.checkNewBadges(stats: stats, existingBadges: [Badge.firstStep.id])
        XCTAssertFalse(unlocked.contains(.firstStep), "Should not re-unlock already earned badge")
    }

    func testStreakBadge7Days() {
        let stats = BadgeService.Stats(totalReviews: 50, correctReviews: 40, streak: 7, totalPoints: 500)
        let unlocked = BadgeService.checkNewBadges(stats: stats, existingBadges: [Badge.firstStep.id])
        XCTAssertTrue(unlocked.contains(.streak7), "Should unlock 7-day streak badge")
    }

    func testStreakBadge30Days() {
        let stats = BadgeService.Stats(totalReviews: 200, correctReviews: 150, streak: 30, totalPoints: 2000)
        let unlocked = BadgeService.checkNewBadges(stats: stats, existingBadges: [Badge.firstStep.id, Badge.streak7.id])
        XCTAssertTrue(unlocked.contains(.streak30), "Should unlock 30-day streak badge")
    }

    func testReviewCountBadge() {
        let stats = BadgeService.Stats(totalReviews: 100, correctReviews: 80, streak: 5, totalPoints: 800)
        let unlocked = BadgeService.checkNewBadges(stats: stats, existingBadges: [Badge.firstStep.id])
        XCTAssertTrue(unlocked.contains(.century), "Should unlock 100 reviews badge")
    }

    func testPointsBadge() {
        let stats = BadgeService.Stats(totalReviews: 200, correctReviews: 150, streak: 10, totalPoints: 1000)
        let unlocked = BadgeService.checkNewBadges(stats: stats, existingBadges: [Badge.firstStep.id])
        XCTAssertTrue(unlocked.contains(.points1000), "Should unlock 1000 points badge")
    }

    func testNoBadgesUnlockedWhenNotQualified() {
        let stats = BadgeService.Stats(totalReviews: 0, correctReviews: 0, streak: 0, totalPoints: 0)
        let unlocked = BadgeService.checkNewBadges(stats: stats, existingBadges: [])
        XCTAssertTrue(unlocked.isEmpty, "Should not unlock any badges with no activity")
    }
}
