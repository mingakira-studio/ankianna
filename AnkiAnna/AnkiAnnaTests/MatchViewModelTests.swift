import XCTest
@testable import AnkiAnna

final class MatchViewModelTests: XCTestCase {
    func testGridSizeIs12For6Pairs() {
        let vm = MatchViewModel(pairs: 6)
        vm.setup(characters: [
            (char: "大", word: "大人"),
            (char: "小", word: "小鸟"),
            (char: "水", word: "水果"),
            (char: "火", word: "火车"),
            (char: "山", word: "山上"),
            (char: "花", word: "花朵")
        ])
        XCTAssertEqual(vm.tiles.count, 12)
    }

    func testCorrectMatchRemovesPair() {
        let vm = MatchViewModel(pairs: 2)
        vm.setup(characters: [
            (char: "大", word: "大人"),
            (char: "小", word: "小鸟")
        ])

        // Find a matching pair
        let charIdx = vm.tiles.firstIndex { $0.isCharacter && $0.text == "大" }!
        let wordIdx = vm.tiles.firstIndex { !$0.isCharacter && $0.text == "大人" }!

        vm.selectTile(at: charIdx)
        vm.selectTile(at: wordIdx)

        XCTAssertTrue(vm.tiles[charIdx].isMatched)
        XCTAssertTrue(vm.tiles[wordIdx].isMatched)
        XCTAssertEqual(vm.matchedPairs, 1)
    }

    func testWrongMatchDoesNotRemove() {
        let vm = MatchViewModel(pairs: 2)
        vm.setup(characters: [
            (char: "大", word: "大人"),
            (char: "小", word: "小鸟")
        ])

        let charIdx = vm.tiles.firstIndex { $0.isCharacter && $0.text == "大" }!
        let wrongWordIdx = vm.tiles.firstIndex { !$0.isCharacter && $0.text == "小鸟" }!

        vm.selectTile(at: charIdx)
        vm.selectTile(at: wrongWordIdx)

        XCTAssertFalse(vm.tiles[charIdx].isMatched)
        XCTAssertFalse(vm.tiles[wrongWordIdx].isMatched)
        XCTAssertEqual(vm.matchedPairs, 0)
        XCTAssertEqual(vm.wrongAttempts, 1)
    }

    func testGameCompleteWhenAllMatched() {
        let vm = MatchViewModel(pairs: 1)
        vm.setup(characters: [(char: "大", word: "大人")])

        let charIdx = vm.tiles.firstIndex { $0.isCharacter }!
        let wordIdx = vm.tiles.firstIndex { !$0.isCharacter }!

        vm.selectTile(at: charIdx)
        vm.selectTile(at: wordIdx)

        XCTAssertTrue(vm.isComplete)
    }

    func testTimerTicks() {
        let vm = MatchViewModel(pairs: 1)
        vm.setup(characters: [(char: "大", word: "大人")])
        vm.tick()
        vm.tick()
        XCTAssertEqual(vm.elapsedTime, 2)
    }

    func testTimerStopsAfterComplete() {
        let vm = MatchViewModel(pairs: 1)
        vm.setup(characters: [(char: "大", word: "大人")])

        let charIdx = vm.tiles.firstIndex { $0.isCharacter }!
        let wordIdx = vm.tiles.firstIndex { !$0.isCharacter }!
        vm.selectTile(at: charIdx)
        vm.selectTile(at: wordIdx)

        let timeAtComplete = vm.elapsedTime
        vm.tick()
        XCTAssertEqual(vm.elapsedTime, timeAtComplete) // no increment after complete
    }
}
