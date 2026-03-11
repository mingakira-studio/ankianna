import XCTest
@testable import AnkiAnna

final class TimeAttackViewModelTests: XCTestCase {
    func testInitialTimeIsSelected() {
        let vm = TimeAttackViewModel(duration: 60)
        XCTAssertEqual(vm.remainingTime, 60)
        XCTAssertFalse(vm.isRunning)
        XCTAssertFalse(vm.isGameOver)
        XCTAssertEqual(vm.score, 0)
    }

    func testCorrectAnswerAddsTime() {
        let vm = TimeAttackViewModel(duration: 60)
        vm.handleCorrectAnswer()
        XCTAssertEqual(vm.remainingTime, 63) // +3 seconds
        XCTAssertEqual(vm.correctCount, 1)
        XCTAssertEqual(vm.answeredCount, 1)
        XCTAssertTrue(vm.score > 0)
    }

    func testWrongAnswerResetsCombo() {
        let vm = TimeAttackViewModel(duration: 60)
        vm.handleCorrectAnswer()
        vm.handleCorrectAnswer()
        XCTAssertEqual(vm.combo, 2)
        vm.handleWrongAnswer()
        XCTAssertEqual(vm.combo, 0)
        XCTAssertEqual(vm.answeredCount, 3)
    }

    func testGameEndsWhenTimeExpires() {
        let vm = TimeAttackViewModel(duration: 1)
        vm.tick()
        XCTAssertTrue(vm.isGameOver)
        XCTAssertFalse(vm.isRunning)
    }

    func testBestComboTracked() {
        let vm = TimeAttackViewModel(duration: 60)
        vm.handleCorrectAnswer()
        vm.handleCorrectAnswer()
        vm.handleCorrectAnswer()
        XCTAssertEqual(vm.bestCombo, 3)
        vm.handleWrongAnswer()
        XCTAssertEqual(vm.bestCombo, 3)
        XCTAssertEqual(vm.combo, 0)
    }

    func testScoreIncludesComboBonus() {
        let vm = TimeAttackViewModel(duration: 60)
        vm.handleCorrectAnswer() // combo=1, score=10+1=11
        let score1 = vm.score
        vm.handleCorrectAnswer() // combo=2, score+=10+2=12
        let score2 = vm.score
        XCTAssertEqual(score1, 11) // 10 base + 1 combo
        XCTAssertEqual(score2, 23) // 11 + 12
    }
}
