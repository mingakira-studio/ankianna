import XCTest
@testable import AnkiAnna

final class LevelsViewModelTests: XCTestCase {
    func testStarRating() {
        XCTAssertEqual(LevelsViewModel.starRating(errors: 0), 3)
        XCTAssertEqual(LevelsViewModel.starRating(errors: 1), 2)
        XCTAssertEqual(LevelsViewModel.starRating(errors: 2), 1)
        XCTAssertEqual(LevelsViewModel.starRating(errors: 5), 1)
    }

    func testHandleCorrectAnswer() {
        let vm = LevelsViewModel()
        vm.handleCorrectAnswer()
        XCTAssertTrue(vm.isCorrect)
        XCTAssertTrue(vm.showResult)
    }

    func testHandleWrongAnswer() {
        let vm = LevelsViewModel()
        vm.handleWrongAnswer()
        XCTAssertFalse(vm.isCorrect)
        XCTAssertTrue(vm.showResult)
        XCTAssertEqual(vm.errorCount, 1)
    }

    func testErrorCountAccumulates() {
        let vm = LevelsViewModel()
        vm.handleWrongAnswer()
        vm.handleWrongAnswer()
        vm.handleWrongAnswer()
        XCTAssertEqual(vm.errorCount, 3)
        XCTAssertEqual(vm.starsForCurrentLevel(), 1)
    }

    func testPerfectLevelGets3Stars() {
        let vm = LevelsViewModel()
        // No errors
        XCTAssertEqual(vm.starsForCurrentLevel(), 3)
    }
}
