import XCTest
@testable import AnkiAnna

final class PointsServiceTests: XCTestCase {
    func testCorrectAnswerPoints() {
        XCTAssertEqual(PointsService.pointsForAnswer(correct: true, combo: 0), 10)
    }

    func testComboBonus() {
        XCTAssertEqual(PointsService.pointsForAnswer(correct: true, combo: 3), 13)
        XCTAssertEqual(PointsService.pointsForAnswer(correct: true, combo: 10), 20) // capped
    }

    func testWrongAnswerNoPoints() {
        XCTAssertEqual(PointsService.pointsForAnswer(correct: false, combo: 5), 0)
    }

    func testDailyCompletionBonus() {
        XCTAssertEqual(PointsService.dailyCompletionBonus, 50)
    }
}
