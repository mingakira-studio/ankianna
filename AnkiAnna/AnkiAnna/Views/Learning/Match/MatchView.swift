import SwiftUI
import SwiftData

struct MatchView: View {
    @Environment(\.dismiss) private var dismiss
    @Query var cards: [Card]
    @State private var viewModel = MatchViewModel(pairs: 6)
    @State private var hasStarted = false
    @State private var timer: Timer?

    var body: some View {
        Group {
            if viewModel.isComplete {
                completeView
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else if hasStarted {
                gameplayView
                    .transition(.opacity)
            } else {
                startView
            }
        }
        .animation(DesignTokens.Animation.quick, value: viewModel.isComplete)
        .animation(DesignTokens.Animation.quick, value: hasStarted)
    }

    private var startView: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            Image(systemName: "link")
                .font(.system(size: DesignTokens.IconSize.xl))
                .foregroundColor(DesignTokens.Colors.match)

            Text("连连看")
                .font(DesignTokens.Font.largeTitle)

            Text("将汉字与对应的词语配对")
                .font(DesignTokens.Font.body)
                .foregroundColor(DesignTokens.Colors.onSurfaceSecondary)

            Button("开始游戏") {
                setupGame()
            }
            .buttonStyle(.borderedProminent)
            .tint(DesignTokens.Colors.match)
            .font(DesignTokens.Font.title2)
            .disabled(cards.count < 3)

            if cards.count < 3 {
                Text("至少需要3张卡片")
                    .font(DesignTokens.Font.body)
                    .foregroundColor(DesignTokens.Colors.warning)
            }
        }
        .navigationTitle("连连看")
    }

    private var gameplayView: some View {
        VStack(spacing: 0) {
            // Top bar
            HStack {
                Text("已配对 \(viewModel.matchedPairs)/\(viewModel.totalPairs)")
                    .font(DesignTokens.Font.headline)

                Spacer()

                Text("用时 \(viewModel.elapsedTime)s")
                    .font(DesignTokens.Font.headline)
                    .foregroundColor(DesignTokens.Colors.onSurfaceSecondary)
            }
            .padding()

            Divider()

            // Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: DesignTokens.Spacing.md), count: 4), spacing: DesignTokens.Spacing.md) {
                ForEach(viewModel.tiles.indices, id: \.self) { index in
                    let tile = viewModel.tiles[index]
                    Button {
                        TTSService.speak(text: tile.speakText, cardType: .chineseWriting)
                        viewModel.selectTile(at: index)
                    } label: {
                        Text(tile.text)
                            .font(tile.isCharacter ? DesignTokens.Font.sectionTitle : DesignTokens.Font.body)
                            .frame(maxWidth: .infinity)
                            .frame(height: 70)
                            .background(
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.sm)
                                    .fill(tileColor(tile))
                            )
                            .foregroundColor(tile.isMatched ? .clear : DesignTokens.Colors.onSurface)
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
        if tile.isMatched { return DesignTokens.Colors.success.opacity(0.2) }
        if tile.isSelected { return DesignTokens.Colors.levels.opacity(0.3) }
        return tile.isCharacter ? DesignTokens.Colors.surfaceSecondary : DesignTokens.Colors.surface
    }

    private var completeView: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            Spacer()

            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: DesignTokens.IconSize.xl))
                .foregroundColor(DesignTokens.Colors.match)

            Text("全部配对成功！")
                .font(DesignTokens.Font.largeTitle)

            VStack(spacing: DesignTokens.Spacing.md) {
                statRow(label: "用时", value: "\(viewModel.elapsedTime) 秒")
                statRow(label: "错误次数", value: "\(viewModel.wrongAttempts)")
            }
            .padding()
            .background(DesignTokens.Colors.surface)
            .cornerRadius(DesignTokens.Radius.md)
            .padding(.horizontal)

            HStack(spacing: DesignTokens.Spacing.lg) {
                Button("返回首页") {
                    timer?.invalidate()
                    timer = nil
                    dismiss()
                }
                .buttonStyle(.bordered)
                .font(DesignTokens.Font.title3)

                Button("再来一次") {
                    viewModel = MatchViewModel(pairs: 6)
                    hasStarted = false
                    timer?.invalidate()
                    timer = nil
                }
                .buttonStyle(.borderedProminent)
                .tint(DesignTokens.Colors.match)
                .font(DesignTokens.Font.title3)
            }

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
                .font(DesignTokens.Font.body)
                .foregroundColor(DesignTokens.Colors.onSurfaceSecondary)
            Spacer()
            Text(value)
                .font(DesignTokens.Font.headline)
        }
    }

    private func setupGame() {
        let pairs = cards.prefix(6).map { card -> (char: String, word: String, speakText: String) in
            let word = card.contexts.first?.text ?? card.audioText
            let speakText = card.contexts.first?.fullText ?? card.audioText
            return (char: card.answer, word: word, speakText: speakText)
        }
        viewModel.setup(characters: Array(pairs))
        hasStarted = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            viewModel.tick()
        }
    }
}
