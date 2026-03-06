import SwiftUI
import SwiftData
import PencilKit

struct LearningView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var cards: [Card]
    @Query private var profiles: [UserProfile]
    @State private var viewModel = LearningViewModel()
    @State private var drawing = PKDrawing()

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.sessionComplete {
                    sessionCompleteView
                } else if let card = viewModel.currentCard {
                    learningContentView(card: card)
                } else {
                    emptyStateView
                }
            }
            .navigationTitle("学习")
            .onAppear {
                viewModel.loadDueCards(from: cards, dailyGoal: 15)
                HandwritingRecognizer.downloadModel(language: "zh-CN") { _ in }
            }
        }
    }

    private func learningContentView(card: Card) -> some View {
        HStack(spacing: 0) {
            // Left: prompt + controls
            VStack {
                Spacer()
                CardPromptView(
                    context: viewModel.currentContext,
                    cardType: card.type,
                    onSpeak: {
                        if let ctx = viewModel.currentContext {
                            TTSService.speak(text: ctx.fullText, cardType: card.type)
                        }
                    }
                )
                Spacer()

                // Progress
                Text("\(viewModel.completedCount)/\(viewModel.totalCount)")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .padding(.bottom)
            }
            .frame(maxWidth: .infinity)

            // Right: writing area or result
            VStack {
                if viewModel.showResult {
                    ResultFeedbackView(
                        isCorrect: viewModel.isCorrect,
                        correctAnswer: card.answer,
                        onNext: {
                            drawing = PKDrawing()
                            viewModel.next()
                        },
                        onRetry: {
                            drawing = PKDrawing()
                            viewModel.retry()
                        }
                    )
                } else {
                    WritingCanvasView(drawing: $drawing)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.white)
                                .shadow(radius: 2)
                        )
                        .padding()

                    Button("提交") {
                        submitDrawing(card: card)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding(.bottom)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var sessionCompleteView: some View {
        VStack(spacing: 20) {
            Image(systemName: "star.fill")
                .font(.system(size: 80))
                .foregroundStyle(.yellow)
            Text("今天的学习完成了！")
                .font(.system(size: 28, weight: .bold))
            Text("正确 \(viewModel.correctCount)/\(viewModel.totalCount)")
                .font(.title2)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "rectangle.stack.badge.plus")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text("还没有卡片")
                .font(.title2)
            Text("去「添加」页面创建一些卡片吧")
                .foregroundStyle(.secondary)
        }
    }

    private func submitDrawing(card: Card) {
        let lang = TTSService.languageCode(for: card.type)
        HandwritingRecognizer.recognize(drawing: drawing, language: lang) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let candidates):
                    let matched = HandwritingRecognizer.bestMatch(candidates: candidates, expected: card.answer)
                    if matched {
                        viewModel.submitAnswer(recognized: card.answer, modelContext: modelContext, profile: profile)
                    } else {
                        viewModel.submitAnswer(recognized: candidates.first ?? "", modelContext: modelContext, profile: profile)
                    }
                case .failure:
                    viewModel.submitAnswer(recognized: "", modelContext: modelContext, profile: profile)
                }
            }
        }
    }
}
