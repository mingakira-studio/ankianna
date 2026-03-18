import SwiftUI
import SwiftData
import PencilKit

struct LevelsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query var cards: [Card]
    @Query var characterStats: [CharacterStats]
    @Query var levelProgress: [LevelProgress]
    @State private var viewModel = LevelsViewModel()
    @State private var drawing = PKDrawing()
    @State private var typedAnswer = ""
    @AppStorage("testModeEnabled") private var testModeEnabled = false

    var body: some View {
        Group {
            if viewModel.isGameOver {
                gameOverView
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else if viewModel.isLevelComplete {
                levelCompleteView
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else if viewModel.isPlaying {
                BattleSceneView(
                    viewModel: $viewModel,
                    drawing: $drawing,
                    typedAnswer: $typedAnswer,
                    testModeEnabled: testModeEnabled,
                    onSubmitDrawing: { submitDrawing() }
                )
                .transition(.opacity)
            } else {
                levelSelectionView
            }
        }
        .animation(reduceMotion ? nil : DesignTokens.Animation.quick, value: viewModel.isLevelComplete)
        .animation(reduceMotion ? nil : DesignTokens.Animation.quick, value: viewModel.isPlaying)
        .animation(reduceMotion ? nil : DesignTokens.Animation.quick, value: viewModel.isGameOver)
    }

    // MARK: - Level Selection (Professional Game UI)

    private var levelSelectionView: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.lg) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("闯关模式")
                            .font(DesignTokens.Font.largeTitle)
                        Text("击败字妖，征服每一课！")
                            .font(DesignTokens.Font.subheadline)
                            .foregroundStyle(DesignTokens.Colors.onSurfaceSecondary)
                        }
                        Spacer()
                        MascotView(state: .idle)
                            .scaleEffect(0.7)
                    }
                    .padding(.horizontal)

                    // Level grid
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: DesignTokens.Spacing.md),
                        GridItem(.flexible(), spacing: DesignTokens.Spacing.md),
                        GridItem(.flexible(), spacing: DesignTokens.Spacing.md),
                    ], spacing: DesignTokens.Spacing.lg) {
                        ForEach(viewModel.levels) { level in
                            levelCard(level)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
        .onAppear {
            viewModel.loadLevels(stats: characterStats, progress: levelProgress)
        }
    }

    private func levelCard(_ level: LevelsViewModel.LevelInfo) -> some View {
        Button {
            if level.isUnlocked {
                drawing = PKDrawing()
                viewModel.startLevel(level, cards: cards, stats: characterStats)
            }
        } label: {
            VStack(spacing: DesignTokens.Spacing.sm) {
                ZStack {
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                        .fill(
                            level.isUnlocked
                                ? LinearGradient(
                                    colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.2)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing)
                                : LinearGradient(
                                    colors: [Color.gray.opacity(0.15), Color.gray.opacity(0.1)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(height: 100)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                                .stroke(level.isUnlocked ? Color.purple.opacity(0.4) : Color.gray.opacity(0.2), lineWidth: 1)
                        )

                    if level.isUnlocked {
                        VStack(spacing: 4) {
                            Text("第\(level.lesson)课")
                                .font(DesignTokens.Font.headline)
                            Text(level.title)
                                .font(DesignTokens.Font.caption)
                                .foregroundStyle(DesignTokens.Colors.onSurfaceSecondary)
                                .lineLimit(1)
                            Text("\(level.characterCount)字")
                                .font(DesignTokens.Font.caption2)
                                .foregroundStyle(DesignTokens.Colors.onSurfaceSecondary)
                        }
                    } else {
                        Image(systemName: "lock.fill")
                            .font(DesignTokens.Font.title)
                            .foregroundStyle(Color.gray.opacity(0.4))
                    }
                }

                if level.stars > 0 {
                    HStack(spacing: 2) {
                        ForEach(0..<3, id: \.self) { i in
                            Image(systemName: i < level.stars ? "star.fill" : "star")
                                .font(.system(size: 12))
                                .foregroundStyle(i < level.stars ? .yellow : Color.gray.opacity(0.3))
                        }
                    }
                }
            }
        }
        .disabled(!level.isUnlocked)
    }

    // MARK: - Level Complete

    private var levelCompleteView: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            Spacer()

            let stars = viewModel.starsForCurrentLevel()

            // Trophy
            ZStack {
                Circle()
                    .fill(Color.yellow.opacity(0.1))
                    .frame(width: 120, height: 120)
                Image(systemName: "trophy.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.yellow, Color(red: 1.0, green: 0.75, blue: 0.0)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .shadow(color: .yellow.opacity(0.4), radius: 12)
            }

            Text("关卡完成！")
                .font(DesignTokens.Font.largeTitle)

            // Stars
            HStack(spacing: DesignTokens.Spacing.md) {
                ForEach(0..<3, id: \.self) { i in
                    Image(systemName: i < stars ? "star.fill" : "star")
                        .font(.system(size: 36))
                        .foregroundStyle(i < stars ? .yellow : Color.gray.opacity(0.3))
                        .shadow(color: i < stars ? .yellow.opacity(0.5) : .clear, radius: 6)
                }
            }

            // Stats
            HStack(spacing: DesignTokens.Spacing.xxl) {
                VStack {
                    Text("\(viewModel.defeatedCount)")
                        .font(DesignTokens.Font.title)
                        .foregroundStyle(.green)
                    Text("击败")
                        .font(DesignTokens.Font.caption)
                        .foregroundStyle(DesignTokens.Colors.onSurfaceSecondary)
                }
                VStack {
                    Text("\(viewModel.errorCount)")
                        .font(DesignTokens.Font.title)
                        .foregroundStyle(viewModel.errorCount > 0 ? .red : .green)
                    Text("失误")
                        .font(DesignTokens.Font.caption)
                        .foregroundStyle(DesignTokens.Colors.onSurfaceSecondary)
                }
                VStack {
                    Text("\(viewModel.dragonHp)♥")
                        .font(DesignTokens.Font.title)
                        .foregroundStyle(.red)
                    Text("剩余生命")
                        .font(DesignTokens.Font.caption)
                        .foregroundStyle(DesignTokens.Colors.onSurfaceSecondary)
                }
            }
            .padding()
            .background(DesignTokens.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.lg))

            Spacer()

            // Buttons
            HStack(spacing: DesignTokens.Spacing.lg) {
                Button {
                    saveLevelProgress(stars: stars)
                    dismiss()
                } label: {
                    Label("返回首页", systemImage: "house")
                        .font(DesignTokens.Font.headline)
                }
                .buttonStyle(.bordered)

                    Button {
                        saveLevelProgress(stars: stars)
                        viewModel = LevelsViewModel()
                        viewModel.loadLevels(stats: characterStats, progress: levelProgress)
                    } label: {
                        Label("继续闯关", systemImage: "arrow.right")
                            .font(DesignTokens.Font.headline)
                    }
                    .buttonStyle(.borderedProminent)
                }

                Spacer()
            }
    }

    // MARK: - Game Over

    private var gameOverView: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            Spacer()

            MascotView(state: .encourage)

            Text("挑战失败")
                .font(DesignTokens.Font.largeTitle)

            Text("击败了 \(viewModel.defeatedCount)/\(viewModel.totalCount) 个字妖")
                .font(DesignTokens.Font.title3)
                .foregroundStyle(DesignTokens.Colors.onSurfaceSecondary)

            Spacer()

            HStack(spacing: DesignTokens.Spacing.lg) {
                Button {
                    dismiss()
                } label: {
                    Label("返回首页", systemImage: "house")
                        .font(DesignTokens.Font.headline)
                }
                .buttonStyle(.bordered)

                    Button {
                        if let level = viewModel.currentLevel {
                            drawing = PKDrawing()
                            viewModel.startLevel(level, cards: cards, stats: characterStats)
                        }
                    } label: {
                        Label("重新挑战", systemImage: "arrow.counterclockwise")
                            .font(DesignTokens.Font.headline)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                }

                Spacer()
            }
    }

    // MARK: - Helpers

    private func submitDrawing() {
        guard let card = viewModel.currentCard else { return }
        let lang = TTSService.languageCode(for: card.type)
        HandwritingRecognizer.recognize(drawing: drawing, language: lang) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let candidates):
                    let matched = HandwritingRecognizer.bestMatch(candidates: candidates, expected: card.answer)
                    if matched {
                        viewModel.handleCorrectAnswer()
                    } else {
                        viewModel.handleWrongAnswer()
                    }
                case .failure:
                    viewModel.handleWrongAnswer()
                }
                drawing = PKDrawing()
            }
        }
    }

    private func saveLevelProgress(stars: Int) {
        guard let level = viewModel.currentLevel else { return }

        if let existing = levelProgress.first(where: {
            $0.grade == level.grade && $0.semester == level.semester && $0.lesson == level.lesson
        }) {
            existing.stars = max(existing.stars, stars)
            if let currentBest = existing.bestErrors {
                existing.bestErrors = min(currentBest, viewModel.errorCount)
            } else {
                existing.bestErrors = viewModel.errorCount
            }
        } else {
            let progress = LevelProgress(grade: level.grade, semester: level.semester, lesson: level.lesson, isUnlocked: true)
            progress.stars = stars
            progress.bestErrors = viewModel.errorCount
            modelContext.insert(progress)
        }

        // Unlock next level
        let allLevels = viewModel.levels
        if let currentIdx = allLevels.firstIndex(where: {
            $0.grade == level.grade && $0.semester == level.semester && $0.lesson == level.lesson
        }), currentIdx + 1 < allLevels.count {
            let nextLevel = allLevels[currentIdx + 1]
            if let existing = levelProgress.first(where: {
                $0.grade == nextLevel.grade && $0.semester == nextLevel.semester && $0.lesson == nextLevel.lesson
            }) {
                existing.isUnlocked = true
            } else {
                let nextProgress = LevelProgress(grade: nextLevel.grade, semester: nextLevel.semester, lesson: nextLevel.lesson, isUnlocked: true)
                modelContext.insert(nextProgress)
            }
        }
    }
}
