import SwiftUI
import SwiftData
import PencilKit

struct LevelsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query var cards: [Card]
    @Query var characterStats: [CharacterStats]
    @Query var levelProgress: [LevelProgress]
    @State private var viewModel = LevelsViewModel()
    @State private var drawing = PKDrawing()
    @State private var typedAnswer = ""

    var body: some View {
        if viewModel.isLevelComplete {
            levelCompleteView
        } else if viewModel.isPlaying {
            gameplayView
        } else {
            levelSelectionView
        }
    }

    private var levelSelectionView: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(viewModel.levels) { level in
                    Button {
                        if level.isUnlocked {
                            viewModel.startLevel(level, cards: cards)
                        }
                    } label: {
                        VStack(spacing: 8) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(level.isUnlocked ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                                    .frame(height: 100)

                                if level.isUnlocked {
                                    VStack {
                                        Text("第\(level.lesson)课")
                                            .font(.headline)
                                        Text(level.title)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                } else {
                                    Image(systemName: "lock.fill")
                                        .font(.title)
                                        .foregroundColor(.gray)
                                }
                            }

                            if level.stars > 0 {
                                HStack(spacing: 2) {
                                    ForEach(0..<3, id: \.self) { i in
                                        Image(systemName: i < level.stars ? "star.fill" : "star")
                                            .font(.caption)
                                            .foregroundColor(.yellow)
                                    }
                                }
                            }
                        }
                    }
                    .disabled(!level.isUnlocked)
                }
            }
            .padding()
        }
        .navigationTitle("闯关模式")
        .onAppear {
            viewModel.loadLevels(stats: characterStats, progress: levelProgress)
        }
    }

    private var gameplayView: some View {
        VStack(spacing: 0) {
            // Top bar: progress
            HStack {
                Text("第\(viewModel.currentLevel?.lesson ?? 0)课")
                    .font(.headline)

                Spacer()

                Text("\(viewModel.currentIndex + 1)/\(viewModel.totalCount)")
                    .font(.headline)

                Spacer()

                Text("错误 \(viewModel.errorCount)")
                    .font(.headline)
                    .foregroundColor(viewModel.errorCount > 0 ? .red : .secondary)
            }
            .padding()

            ProgressView(value: Double(viewModel.currentIndex), total: Double(viewModel.totalCount))
                .padding(.horizontal)

            Divider()

            if viewModel.showResult {
                resultView
            } else if let card = viewModel.currentCard, let ctx = viewModel.currentContext {
                questionView(card: card, context: ctx)
            }
        }
    }

    private func questionView(card: Card, context: CardContext) -> some View {
        VStack(spacing: 20) {
            Spacer()

            Text(context.text)
                .font(.title)
                .multilineTextAlignment(.center)
                .padding()
                .onAppear {
                    TTSService.speak(text: context.fullText, cardType: card.type)
                }

            if card.type == .chineseWriting {
                WritingCanvasView(drawing: $drawing)
                    .frame(height: 200)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)

                HStack(spacing: 16) {
                    #if DEBUG
                    Button("模拟写对") {
                        drawing = PKDrawing()
                        viewModel.handleCorrectAnswer()
                    }
                    .buttonStyle(.bordered)

                    Button("模拟写错") {
                        drawing = PKDrawing()
                        viewModel.handleWrongAnswer()
                    }
                    .buttonStyle(.bordered)
                    #endif
                }
            } else {
                TextField("输入答案", text: $typedAnswer)
                    .textFieldStyle(.roundedBorder)
                    .font(.title2)
                    .padding(.horizontal)
                    .onSubmit {
                        let correct = typedAnswer.lowercased().trimmingCharacters(in: .whitespaces) == card.answer.lowercased()
                        typedAnswer = ""
                        if correct {
                            viewModel.handleCorrectAnswer()
                        } else {
                            viewModel.handleWrongAnswer()
                        }
                    }
            }

            Spacer()
        }
    }

    private var resultView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: viewModel.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(viewModel.isCorrect ? .green : .red)

            if let card = viewModel.currentCard {
                Text(card.answer)
                    .font(.system(size: 48))
                    .fontWeight(.bold)
            }

            Button("继续") {
                viewModel.next()
            }
            .buttonStyle(.borderedProminent)
            .font(.title3)

            Spacer()
        }
    }

    private var levelCompleteView: some View {
        VStack(spacing: 24) {
            Spacer()

            let stars = viewModel.starsForCurrentLevel()

            Image(systemName: "trophy.fill")
                .font(.system(size: 60))
                .foregroundColor(.yellow)

            Text("关卡完成！")
                .font(.largeTitle)
                .fontWeight(.bold)

            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { i in
                    Image(systemName: i < stars ? "star.fill" : "star")
                        .font(.system(size: 36))
                        .foregroundColor(.yellow)
                }
            }

            Text("错误: \(viewModel.errorCount)")
                .font(.title2)
                .foregroundColor(.secondary)

            Button("返回关卡列表") {
                saveLevelProgress(stars: stars)
                viewModel = LevelsViewModel()
                viewModel.loadLevels(stats: characterStats, progress: levelProgress)
            }
            .buttonStyle(.borderedProminent)
            .font(.title3)

            Spacer()
        }
        .navigationTitle("闯关模式")
    }

    private func saveLevelProgress(stars: Int) {
        guard let level = viewModel.currentLevel else { return }

        // Find or create progress
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
