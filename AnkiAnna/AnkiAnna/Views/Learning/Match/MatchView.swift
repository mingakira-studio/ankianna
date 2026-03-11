import SwiftUI
import SwiftData

struct MatchView: View {
    @Query var cards: [Card]
    @State private var viewModel = MatchViewModel(pairs: 6)
    @State private var hasStarted = false
    @State private var timer: Timer?

    var body: some View {
        if viewModel.isComplete {
            completeView
        } else if hasStarted {
            gameplayView
        } else {
            startView
        }
    }

    private var startView: some View {
        VStack(spacing: 24) {
            Image(systemName: "link")
                .font(.system(size: 60))
                .foregroundColor(.green)

            Text("连连看")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("将汉字与对应的词语配对")
                .foregroundColor(.secondary)

            Button("开始游戏") {
                setupGame()
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .font(.title2)
            .disabled(cards.count < 3)

            if cards.count < 3 {
                Text("至少需要3张卡片")
                    .foregroundColor(.orange)
            }
        }
        .navigationTitle("连连看")
    }

    private var gameplayView: some View {
        VStack(spacing: 0) {
            // Top bar
            HStack {
                Text("已配对 \(viewModel.matchedPairs)/\(viewModel.totalPairs)")
                    .font(.headline)

                Spacer()

                Text("用时 \(viewModel.elapsedTime)s")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            .padding()

            Divider()

            // Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                ForEach(viewModel.tiles.indices, id: \.self) { index in
                    let tile = viewModel.tiles[index]
                    Button {
                        viewModel.selectTile(at: index)
                    } label: {
                        Text(tile.text)
                            .font(tile.isCharacter ? .system(size: 28) : .body)
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .frame(height: 70)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(tileColor(tile))
                            )
                            .foregroundColor(tile.isMatched ? .clear : .primary)
                    }
                    .disabled(tile.isMatched)
                    .opacity(tile.isMatched ? 0.3 : 1)
                }
            }
            .padding()

            Spacer()
        }
    }

    private func tileColor(_ tile: MatchViewModel.Tile) -> Color {
        if tile.isMatched { return Color.green.opacity(0.2) }
        if tile.isSelected { return Color.blue.opacity(0.3) }
        return tile.isCharacter ? Color(.systemGray5) : Color(.systemGray6)
    }

    private var completeView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)

            Text("全部配对成功！")
                .font(.largeTitle)
                .fontWeight(.bold)

            VStack(spacing: 12) {
                statRow(label: "用时", value: "\(viewModel.elapsedTime) 秒")
                statRow(label: "错误次数", value: "\(viewModel.wrongAttempts)")
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)

            Button("再来一次") {
                viewModel = MatchViewModel(pairs: 6)
                hasStarted = false
                timer?.invalidate()
                timer = nil
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .font(.title3)

            Spacer()
        }
        .navigationTitle("连连看")
        .onAppear {
            timer?.invalidate()
            timer = nil
        }
    }

    private func statRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.bold)
        }
    }

    private func setupGame() {
        let pairs = cards.prefix(6).map { card -> (char: String, word: String) in
            let word = card.contexts.first?.text ?? card.audioText
            return (char: card.answer, word: word)
        }
        viewModel.setup(characters: Array(pairs))
        hasStarted = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            viewModel.tick()
        }
    }
}
