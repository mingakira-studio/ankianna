import XCTest
@testable import AnkiAnna

final class SurvivalViewModelTests: XCTestCase {
    func testStartsWith3Lives() {
        let vm = SurvivalViewModel()
        XCTAssertEqual(vm.lives, 3)
        XCTAssertFalse(vm.isGameOver)
    }

    func testWrongAnswerLosesLife() {
        let vm = SurvivalViewModel()
        vm.handleWrongAnswer()
        XCTAssertEqual(vm.lives, 2)
    }

    func testGameOverAtZeroLives() {
        let vm = SurvivalViewModel()
        vm.handleWrongAnswer()
        vm.handleWrongAnswer()
        vm.handleWrongAnswer()
        XCTAssertTrue(vm.isGameOver)
        XCTAssertEqual(vm.lives, 0)
    }

    func testConsecutive5CorrectRestoresLife() {
        let vm = SurvivalViewModel()
        vm.lives = 2
        for _ in 0..<5 { vm.handleCorrectAnswer() }
        XCTAssertEqual(vm.lives, 3)
    }

    func testLifeCapAt3() {
        let vm = SurvivalViewModel()
        for _ in 0..<10 { vm.handleCorrectAnswer() }
        XCTAssertEqual(vm.lives, 3)
    }

    func testDifficultyScalesWithSurvived() {
        let vm = SurvivalViewModel()
        XCTAssertEqual(vm.currentMaxGrade, 2)
        vm.survivedCount = 10
        XCTAssertEqual(vm.currentMaxGrade, 3)
        vm.survivedCount = 20
        XCTAssertEqual(vm.currentMaxGrade, 4)
    }

    func testCorrectAnswerIncrementsSurvived() {
        let vm = SurvivalViewModel()
        vm.handleCorrectAnswer()
        XCTAssertEqual(vm.survivedCount, 1)
        vm.handleCorrectAnswer()
        XCTAssertEqual(vm.survivedCount, 2)
    }

    func testWrongAnswerResetsConsecutiveCorrect() {
        let vm = SurvivalViewModel()
        vm.lives = 2
        vm.handleCorrectAnswer()
        vm.handleCorrectAnswer()
        vm.handleWrongAnswer()
        vm.handleCorrectAnswer()
        vm.handleCorrectAnswer()
        vm.handleCorrectAnswer()
        vm.handleCorrectAnswer()
        vm.handleCorrectAnswer()
        // 5 consecutive after wrong → restore
        XCTAssertEqual(vm.lives, 2)
    }
}
