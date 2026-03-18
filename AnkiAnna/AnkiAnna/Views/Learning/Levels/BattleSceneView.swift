import SwiftUI
import PencilKit

struct BattleSceneView: View {
    @Binding var viewModel: LevelsViewModel
    @Binding var drawing: PKDrawing
    @Binding var typedAnswer: String
    let testModeEnabled: Bool
    let onSubmitDrawing: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var dragonAttacking = false
    @State private var monsterAttacking = false
    @State private var showDamageFlash = false

    var body: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height

            ZStack {
                // Background gradient
                battleBackground

                VStack(spacing: 0) {
                    // Top HUD
                    battleHUD
                        .padding(.horizontal)
                        .padding(.top, 8)

                    if isLandscape {
                        landscapeLayout(geo: geo)
                    } else {
                        portraitLayout(geo: geo)
                    }
                }
            }
        }
    }

    // MARK: - Background

    private var battleBackground: some View {
        GeometryReader { geo in
            if let uiImage = UIImage(named: "jurassic_bg") ?? UIImage(contentsOfFile: Bundle.main.path(forResource: "jurassic_bg", ofType: "png") ?? "") {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - HUD

    private var battleHUD: some View {
        HStack {
            // Level info
            VStack(alignment: .leading, spacing: 2) {
                Text("第\(viewModel.currentLevel?.lesson ?? 0)课")
                    .font(DesignTokens.Font.headline)
                    .foregroundStyle(DesignTokens.Colors.onSurface)
                Text(viewModel.currentLevel?.title ?? "")
                    .font(DesignTokens.Font.caption)
                    .foregroundStyle(DesignTokens.Colors.onSurfaceSecondary)
            }

            Spacer()

            // Dragon HP (hearts)
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { i in
                    Image(systemName: i < viewModel.dragonHp ? "heart.fill" : "heart")
                        .font(.system(size: 18))
                        .foregroundStyle(i < viewModel.dragonHp ? .red : Color.gray.opacity(0.3))
                }
            }

            Spacer()

            // Progress counter
            Text("\(viewModel.defeatedCount)/\(viewModel.totalCount)")
                .font(DesignTokens.Font.headline)
                .foregroundStyle(DesignTokens.Colors.onSurface)
        }
    }

    // MARK: - Landscape Layout

    private func landscapeLayout(geo: GeometryProxy) -> some View {
        HStack(spacing: 0) {
            // Left: Battle arena
            VStack(spacing: DesignTokens.Spacing.md) {
                Spacer()

                battleArena(width: geo.size.width * 0.5)

                // Monster progress grid
                monsterGrid
                    .padding(.horizontal)

                Spacer()
            }
            .frame(maxWidth: .infinity)

            // Divider
            Rectangle()
                .fill(Color.gray.opacity(0.15))
                .frame(width: 1)

            // Right: Input area
            VStack(spacing: DesignTokens.Spacing.md) {
                // Context prompt
                if let ctx = viewModel.currentContext {
                    promptView(ctx: ctx)
                }

                Spacer()

                inputSection

                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Portrait Layout

    private func portraitLayout(geo: GeometryProxy) -> some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            battleArena(width: geo.size.width * 0.85)
                .frame(height: geo.size.height * 0.3)

            if let ctx = viewModel.currentContext {
                promptView(ctx: ctx)
            }

            monsterGrid
                .padding(.horizontal)

            Spacer()

            inputSection

            Spacer()
        }
    }

    // MARK: - Battle Arena

    private func battleArena(width: CGFloat) -> some View {
        HStack(spacing: 0) {
            // Dragon (hero)
            ZStack {
                DragonBattleAvatar(
                    state: viewModel.battleAnimState == .dragonAttack ? .happy :
                           (viewModel.battleAnimState == .monsterAttack ? .encourage : .idle)
                )
                .frame(width: 80, height: 80)
                .offset(x: dragonAttacking ? 30 : 0)

                // Damage flash on dragon
                if showDamageFlash {
                    Circle()
                        .fill(Color.red.opacity(0.4))
                        .frame(width: 90, height: 90)
                        .transition(.opacity)
                }
            }
            .frame(maxWidth: .infinity)

            // VS / attack effects
            ZStack {
                if viewModel.battleAnimState == .dragonAttack {
                    // Fire blast effect
                    Image(systemName: "flame.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.yellow, .orange, .red],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: .orange.opacity(0.6), radius: 8)
                        .transition(.scale.combined(with: .opacity))
                } else if viewModel.battleAnimState == .monsterAttack {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.purple)
                        .shadow(color: .purple.opacity(0.6), radius: 8)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(width: 50)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.3), value: viewModel.battleAnimState)

            // Monster
            ZStack {
                if let card = viewModel.currentCard {
                    MonsterCharacter(
                        character: card.answer,
                        isBoss: viewModel.isCurrentBoss,
                        state: viewModel.monsterState,
                        hp: viewModel.monsterHp,
                        maxHp: viewModel.monsterMaxHp
                    )
                    .frame(width: viewModel.isCurrentBoss ? 100 : 80,
                           height: viewModel.isCurrentBoss ? 100 : 80)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .onChange(of: viewModel.battleAnimState) {
            handleBattleAnimation()
        }
    }

    // MARK: - Prompt

    private func promptView(ctx: CardContext) -> some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            Text(viewModel.currentCard.map { ctx.displayText(answer: $0.answer) } ?? ctx.text)
                .font(DesignTokens.Font.title2)
                .foregroundStyle(DesignTokens.Colors.onSurface)
                .multilineTextAlignment(.center)

            Button {
                if let card = viewModel.currentCard {
                    TTSService.speak(text: ctx.fullText, cardType: card.type)
                }
            } label: {
                Image(systemName: "speaker.wave.2.fill")
                    .font(DesignTokens.Font.title3)
                    .foregroundStyle(DesignTokens.Colors.onSurfaceSecondary)
            }
            .accessibilityLabel("朗读")
        }
        .padding(.horizontal, DesignTokens.Spacing.lg)
        .padding(.vertical, DesignTokens.Spacing.sm)
        .background(DesignTokens.Colors.surface)
        .clipShape(Capsule())
        .onAppear {
            if let card = viewModel.currentCard {
                TTSService.speak(text: ctx.fullText, cardType: card.type)
            }
        }
    }

    // MARK: - Monster Grid

    private var monsterGrid: some View {
        let monsters = viewModel.allMonsters
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(Array(monsters.enumerated()), id: \.offset) { idx, m in
                    MiniMonster(
                        character: m.character,
                        isDefeated: m.isDefeated,
                        isBoss: m.isBoss,
                        isCurrent: idx == viewModel.currentIndex
                    )
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Input Section

    @ViewBuilder
    private var inputSection: some View {
        if viewModel.showResult {
            resultOverlay
        } else if let card = viewModel.currentCard {
            if card.type == .chineseWriting {
                WritingCanvasWithTools(drawing: $drawing)
                    .aspectRatio(1, contentMode: .fit)
                    .frame(maxHeight: 280)
                    .claymorphism(fillColor: DesignTokens.Colors.canvas)
                    .padding(.horizontal)

                Button("提交") {
                    onSubmitDrawing()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.bottom)

                if testModeEnabled {
                    HStack(spacing: DesignTokens.Spacing.lg) {
                        Button("模拟写对") {
                            drawing = PKDrawing()
                            viewModel.handleCorrectAnswer()
                        }
                        .buttonStyle(.bordered)
                        .tint(.green)

                        Button("模拟写错") {
                            drawing = PKDrawing()
                            viewModel.handleWrongAnswer()
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                    }
                }
            } else {
                TextField("输入答案", text: $typedAnswer)
                    .textFieldStyle(.roundedBorder)
                    .font(DesignTokens.Font.title2)
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
        }
    }

    // MARK: - Result Overlay

    private var resultOverlay: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            if viewModel.isCorrect {
                Image(systemName: "flame.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.orange)
                    .shadow(color: .orange.opacity(0.5), radius: 8)
                Text("命中!")
                    .font(DesignTokens.Font.title)
                    .foregroundStyle(DesignTokens.Colors.onSurface)
            } else {
                Image(systemName: "shield.lefthalf.filled.slash")
                    .font(.system(size: 40))
                    .foregroundStyle(.red)
                Text("没写对...")
                    .font(DesignTokens.Font.title)
                    .foregroundStyle(DesignTokens.Colors.onSurface)

                if let card = viewModel.currentCard {
                    Text(card.answer)
                        .font(DesignTokens.Font.rounded(size: DesignTokens.CharSize.answer, weight: .bold))
                        .foregroundStyle(DesignTokens.Colors.onSurfaceSecondary)
                }
            }
        }
        .padding()
    }

    // MARK: - Animation Handling

    private func handleBattleAnimation() {
        guard !reduceMotion else { return }
        switch viewModel.battleAnimState {
        case .dragonAttack:
            withAnimation(.easeOut(duration: 0.2)) { dragonAttacking = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                withAnimation(.easeIn(duration: 0.15)) { dragonAttacking = false }
            }
        case .monsterAttack:
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeInOut(duration: 0.15)) { showDamageFlash = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation { showDamageFlash = false }
                }
            }
        default:
            break
        }
    }
}

// MARK: - Dragon Battle Avatar (reuses DragonCharacter states)

private struct DragonBattleAvatar: View {
    let state: MascotState

    var body: some View {
        MascotView(state: state)
    }
}

