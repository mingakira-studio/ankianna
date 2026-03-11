import Foundation

@Observable
class MatchViewModel {
    struct Tile: Identifiable {
        let id: UUID
        let text: String
        let speakText: String
        let pairId: UUID
        let isCharacter: Bool
        var isMatched = false
        var isSelected = false

        init(text: String, speakText: String? = nil, pairId: UUID, isCharacter: Bool) {
            self.id = UUID()
            self.text = text
            self.speakText = speakText ?? text
            self.pairId = pairId
            self.isCharacter = isCharacter
        }
    }

    var tiles: [Tile] = []
    var selectedTileId: UUID? = nil
    var isComplete = false
    var elapsedTime: Int = 0
    var matchedPairs: Int = 0
    var totalPairs: Int
    var wrongAttempts: Int = 0

    init(pairs: Int) {
        totalPairs = pairs
    }

    func setup(characters: [(char: String, word: String, speakText: String)]) {
        tiles = []
        for pair in characters.prefix(totalPairs) {
            let pairId = UUID()
            tiles.append(Tile(text: pair.char, pairId: pairId, isCharacter: true))
            tiles.append(Tile(text: pair.word, speakText: pair.speakText, pairId: pairId, isCharacter: false))
        }
        tiles.shuffle()
    }

    func selectTile(at index: Int) {
        guard index < tiles.count, !tiles[index].isMatched else { return }

        if let selectedId = selectedTileId,
           let selectedIndex = tiles.firstIndex(where: { $0.id == selectedId }) {
            // Second selection
            let selected = tiles[selectedIndex]
            let tapped = tiles[index]

            if selected.id == tapped.id {
                // Tapped same tile — deselect
                tiles[selectedIndex].isSelected = false
                selectedTileId = nil
                return
            }

            if selected.pairId == tapped.pairId && selected.isCharacter != tapped.isCharacter {
                // Correct match
                tiles[selectedIndex].isMatched = true
                tiles[index].isMatched = true
                matchedPairs += 1
                if matchedPairs >= totalPairs { isComplete = true }
            } else {
                wrongAttempts += 1
            }
            // Reset selection
            tiles[selectedIndex].isSelected = false
            selectedTileId = nil
        } else {
            // First selection
            tiles[index].isSelected = true
            selectedTileId = tiles[index].id
        }
    }

    func tick() {
        if !isComplete {
            elapsedTime += 1
        }
    }
}
