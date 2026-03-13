import SwiftUI

struct OnboardingView: View {
    @Binding var hasSeenOnboarding: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var currentPage = 0

    private let pages: [(icon: String, title: String, description: String, color: Color)] = [
        ("pencil.and.outline", "学写汉字", "听语境，动手写，科学记忆", DesignTokens.Colors.primary),
        ("gamecontroller.fill", "趣味模式", "限时挑战、生存模式、闯关解锁", DesignTokens.Colors.accent),
        ("chart.line.uptrend.xyaxis", "看见进步", "每日打卡，掌握进度一目了然", DesignTokens.Colors.success),
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    VStack(spacing: DesignTokens.Spacing.xl) {
                        Spacer()

                        Image(systemName: page.icon)
                            .font(.system(size: 80))
                            .foregroundStyle(page.color)
                            .symbolEffect(.bounce, value: currentPage == index)

                        Text(page.title)
                            .font(DesignTokens.Font.largeTitle)

                        Text(page.description)
                            .font(DesignTokens.Font.title3)
                            .foregroundStyle(DesignTokens.Colors.onSurfaceSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, DesignTokens.Spacing.xxl)

                        Spacer()
                        Spacer()
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .animation(reduceMotion ? nil : .easeInOut, value: currentPage)

            Button {
                if currentPage < pages.count - 1 {
                    withAnimation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.7)) {
                        currentPage += 1
                    }
                } else {
                    hasSeenOnboarding = true
                }
            } label: {
                Text(currentPage < pages.count - 1 ? "下一步" : "开始学习")
                    .font(DesignTokens.Font.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignTokens.Spacing.lg)
                    .background(pages[currentPage].color, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.clay))
            }
            .padding(.horizontal, DesignTokens.Spacing.xxl)
            .padding(.bottom, DesignTokens.Spacing.xxl)

            if currentPage < pages.count - 1 {
                Button("跳过") {
                    hasSeenOnboarding = true
                }
                .font(DesignTokens.Font.subheadline)
                .foregroundStyle(DesignTokens.Colors.onSurfaceSecondary)
                .padding(.bottom, DesignTokens.Spacing.lg)
            }
        }
    }
}
