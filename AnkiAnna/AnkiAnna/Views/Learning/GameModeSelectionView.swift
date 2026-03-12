import SwiftUI

enum GameMode: String, CaseIterable {
    case quickLearn = "快速学习"
    case timeAttack = "限时挑战"
    case survival = "生存模式"
    case levels = "闯关模式"
    case match = "连连看"

    var icon: String {
        switch self {
        case .quickLearn: return "star.fill"
        case .timeAttack: return "timer"
        case .survival: return "heart.fill"
        case .levels: return "building.columns"
        case .match: return "link"
        }
    }

    var description: String {
        switch self {
        case .quickLearn: return "每日任务，SM-2 智能选卡"
        case .timeAttack: return "限时内尽可能多答对"
        case .survival: return "3条命，看能走多远"
        case .levels: return "按课文逐关解锁"
        case .match: return "字-词配对挑战"
        }
    }

    var color: Color {
        switch self {
        case .quickLearn: return .orange
        case .timeAttack: return .red
        case .survival: return .pink
        case .levels: return .blue
        case .match: return .green
        }
    }
}

struct GameModeSelectionView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(GameMode.allCases, id: \.self) { mode in
                        NavigationLink(destination: destinationView(for: mode)) {
                            GameModeCard(mode: mode)
                        }
                        .buttonStyle(PressableCardStyle())
                    }
                }
                .padding()
            }
            .navigationTitle("学习")
        }
    }

    @ViewBuilder
    func destinationView(for mode: GameMode) -> some View {
        switch mode {
        case .quickLearn: LearningView()
        case .timeAttack: TimeAttackView()
        case .survival: SurvivalView()
        case .levels: LevelsView()
        case .match: MatchView()
        }
    }
}

struct PressableCardStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct GameModeCard: View {
    let mode: GameMode

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: mode.icon)
                .font(.system(size: 40))
                .foregroundColor(.white)

            Text(mode.rawValue)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text(mode.description)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 160)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(mode.color.gradient)
        )
    }
}
