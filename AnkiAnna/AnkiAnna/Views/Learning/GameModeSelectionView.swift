import SwiftUI

// MARK: - Training Group

enum TrainingGroup: String, CaseIterable, Identifiable {
    case chinese = "中文听写"
    case english = "英文拼写"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .chinese: return "character.zh"
        case .english: return "textformat.abc"
        }
    }

    var cardType: CardType {
        switch self {
        case .chinese: return .chineseWriting
        case .english: return .englishSpelling
        }
    }

    var color: Color {
        switch self {
        case .chinese: return .orange
        case .english: return .blue
        }
    }
}

// MARK: - Game Mode

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

// MARK: - Game Mode Selection View

struct GameModeSelectionView: View {
    @State private var showDailyPrompt = true
    @State private var showGroupPicker = false
    @State private var selectedGroup: TrainingGroup = .chinese
    @State private var pendingMode: GameMode?
    @State private var navigateToMode = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DesignTokens.Spacing.lg) {
                    ForEach(GameMode.allCases, id: \.self) { mode in
                        Button {
                            if mode == .levels {
                                // Levels already filters by textbook, go directly
                                pendingMode = mode
                                navigateToMode = true
                            } else {
                                pendingMode = mode
                                showGroupPicker = true
                            }
                        } label: {
                            GameModeCard(mode: mode)
                        }
                        .buttonStyle(PressableCardStyle())
                    }
                }
                .padding()
            }
            .navigationTitle("学习")
            .navigationDestination(isPresented: $navigateToMode) {
                if let mode = pendingMode {
                    destinationView(for: mode, group: selectedGroup)
                }
            }
            .sheet(isPresented: $showGroupPicker) {
                groupPickerSheet
            }
            .alert("每日练习", isPresented: $showDailyPrompt) {
                Button("中文听写") {
                    selectedGroup = .chinese
                    pendingMode = .quickLearn
                    navigateToMode = true
                }
                Button("英文拼写") {
                    selectedGroup = .english
                    pendingMode = .quickLearn
                    navigateToMode = true
                }
                Button("自由选择", role: .cancel) { }
            } message: {
                Text("今天的练习准备好了，选择题组开始吧！")
            }
        }
    }

    // MARK: - Group Picker

    private var groupPickerSheet: some View {
        NavigationStack {
            VStack(spacing: DesignTokens.Spacing.xl) {
                Text("选择题组")
                    .font(DesignTokens.Font.title)
                    .padding(.top)

                ForEach(TrainingGroup.allCases) { group in
                    Button {
                        selectedGroup = group
                        showGroupPicker = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            navigateToMode = true
                        }
                    } label: {
                        HStack(spacing: DesignTokens.Spacing.md) {
                            Image(systemName: group.icon)
                                .font(DesignTokens.Font.title2)
                                .foregroundStyle(group.color)
                                .frame(width: 40)
                            Text(group.rawValue)
                                .font(DesignTokens.Font.title3)
                                .foregroundStyle(DesignTokens.Colors.onSurface)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(DesignTokens.Colors.onSurfaceSecondary)
                        }
                        .padding()
                        .background(DesignTokens.Colors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
                    }
                }

                Spacer()
            }
            .padding()
            .presentationDetents([.medium])
        }
    }

    // MARK: - Destination

    @ViewBuilder
    func destinationView(for mode: GameMode, group: TrainingGroup) -> some View {
        switch mode {
        case .quickLearn: LearningView(cardTypeFilter: group.cardType)
        case .timeAttack: TimeAttackView(cardTypeFilter: group.cardType)
        case .survival: SurvivalView(cardTypeFilter: group.cardType)
        case .levels: LevelsView()
        case .match: MatchView(cardTypeFilter: group.cardType)
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
        .claymorphismGradient(mode.color.gradient)
    }
}
