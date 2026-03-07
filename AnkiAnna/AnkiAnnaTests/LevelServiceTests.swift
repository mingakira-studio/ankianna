import XCTest
@testable import AnkiAnna

final class LevelServiceTests: XCTestCase {
    // MARK: - Level Calculation

    func testLevel1AtZeroXP() {
        let info = LevelService.levelInfo(for: 0)
        XCTAssertEqual(info.level, 1)
        XCTAssertEqual(info.progressInLevel, 0)
    }

    func testLevel1AtLowXP() {
        let info = LevelService.levelInfo(for: 50)
        XCTAssertEqual(info.level, 1)
        XCTAssertEqual(info.progressInLevel, 50)
    }

    func testLevel2() {
        // Level 1 requires 100 XP, so 100 XP = level 2 with 0 progress
        let info = LevelService.levelInfo(for: 100)
        XCTAssertEqual(info.level, 2)
        XCTAssertEqual(info.progressInLevel, 0)
    }

    func testLevel2WithProgress() {
        let info = LevelService.levelInfo(for: 150)
        XCTAssertEqual(info.level, 2)
        XCTAssertEqual(info.progressInLevel, 50)
    }

    func testHighLevel() {
        // Each level needs 100 * level XP, so:
        // Level 1: 0-99 (100 XP needed)
        // Level 2: 100-299 (200 XP needed)
        // Level 3: 300-599 (300 XP needed)
        let info = LevelService.levelInfo(for: 600)
        XCTAssertEqual(info.level, 4)
        XCTAssertEqual(info.progressInLevel, 0)
    }

    // MARK: - XP Needed

    func testXPNeededForLevel() {
        XCTAssertEqual(LevelService.xpNeeded(forLevel: 1), 100)
        XCTAssertEqual(LevelService.xpNeeded(forLevel: 2), 200)
        XCTAssertEqual(LevelService.xpNeeded(forLevel: 3), 300)
    }

    // MARK: - Progress Fraction

    func testProgressFraction() {
        let info = LevelService.levelInfo(for: 50)
        // Level 1 needs 100 XP, 50/100 = 0.5
        XCTAssertEqual(info.progressFraction, 0.5, accuracy: 0.01)
    }

    func testProgressFractionAtLevelUp() {
        let info = LevelService.levelInfo(for: 100)
        // Just leveled up, progress should be 0
        XCTAssertEqual(info.progressFraction, 0.0, accuracy: 0.01)
    }

    // MARK: - Level Title

    func testLevelTitles() {
        XCTAssertFalse(LevelService.title(forLevel: 1).isEmpty)
        XCTAssertFalse(LevelService.title(forLevel: 5).isEmpty)
        XCTAssertFalse(LevelService.title(forLevel: 10).isEmpty)
    }
}
