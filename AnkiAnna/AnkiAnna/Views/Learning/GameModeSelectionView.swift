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
        case .quickLearn: return DesignTokens.Colors.quickLearn
        case .timeAttack: return DesignTokens.Colors.timeAttack
        case .survival: return DesignTokens.Colors.survival
        case .levels: return DesignTokens.Colors.levels
        case .match: return DesignTokens.Colors.match
        }
    }
}

struct GameModeSelectionView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DesignTokens.Spacing.lg) {
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
            .animation(DesignTokens.Animation.cardPress, value: configuration.isPressed)
    }
}

struct GameModeCard: View {
    let mode: GameMode

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: mode.icon)
                .font(.system(size: DesignTokens.IconSize.lg))
                .foregroundColor(DesignTokens.Colors.onPrimary)

            Text(mode.rawValue)
                .font(DesignTokens.Font.title2)
                .foregroundColor(DesignTokens.Colors.onPrimary)

            Text(mode.description)
                .font(DesignTokens.Font.caption)
                .foregroundColor(DesignTokens.Colors.onPrimary.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 140)
        .padding(.vertical, DesignTokens.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .fill(mode.color.gradient)
        )
    }
}
