import SwiftUI

/// Centralized design tokens for AnkiAnna — colors, typography, spacing, radii, shadows.
/// All views should reference these tokens instead of hardcoding values.
enum DesignTokens {

    // MARK: - Colors (semantic)

    enum Colors {
        // Brand
        static let primary = Color.blue
        static let accent = Color.orange
        static let accentSecondary = Color.pink

        // Feedback
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red

        // Surfaces (auto-adapt to dark mode)
        static let surface = Color(.systemGray6)
        static let surfaceSecondary = Color(.systemGray5)
        static let canvas = Color(.systemBackground)

        // Text
        static let onPrimary = Color.white
        static let onSurface = Color.primary
        static let onSurfaceSecondary = Color.secondary

        // Game mode colors
        static let quickLearn = Color.orange
        static let timeAttack = Color.red
        static let survival = Color.pink
        static let levels = Color.blue
        static let match = Color.green
    }

    // MARK: - Typography (SF Rounded, Dynamic Type)

    enum Font {
        // Standard text styles — auto-scale with Dynamic Type
        static let caption = SwiftUI.Font.system(.caption, design: .rounded)
        static let caption2 = SwiftUI.Font.system(.caption2, design: .rounded)
        static let footnote = SwiftUI.Font.system(.footnote, design: .rounded)
        static let body = SwiftUI.Font.system(.body, design: .rounded)
        static let headline = SwiftUI.Font.system(.headline, design: .rounded)
        static let subheadline = SwiftUI.Font.system(.subheadline, design: .rounded)
        static let title3 = SwiftUI.Font.system(.title3, design: .rounded, weight: .semibold)
        static let title2 = SwiftUI.Font.system(.title2, design: .rounded, weight: .bold)
        static let title = SwiftUI.Font.system(.title, design: .rounded, weight: .bold)
        static let largeTitle = SwiftUI.Font.system(.largeTitle, design: .rounded, weight: .bold)

        // Semantic aliases — mapped to closest text style for Dynamic Type
        static let comboText = SwiftUI.Font.system(.title2, design: .rounded, weight: .bold)
        static let encouragement = SwiftUI.Font.system(.title2, design: .rounded, weight: .semibold)
        static let points = SwiftUI.Font.system(.title, design: .rounded, weight: .bold)
        static let sectionTitle = SwiftUI.Font.system(.title, design: .rounded, weight: .bold)
        static let feedbackTitle = SwiftUI.Font.system(.largeTitle, design: .rounded, weight: .bold)
        static let inputField = SwiftUI.Font.system(.largeTitle, design: .rounded)
        static let promptText = SwiftUI.Font.system(.largeTitle, design: .rounded, weight: .medium)
        static let spellingChar = SwiftUI.Font.system(.largeTitle, design: .monospaced, weight: .bold)

        /// Fixed-size SF Rounded font for display characters (CharSize/IconSize).
        /// These intentionally do NOT scale with Dynamic Type — character display
        /// sizes are layout-dependent and already large enough for readability.
        static func rounded(size: CGFloat, weight: SwiftUI.Font.Weight = .regular) -> SwiftUI.Font {
            .system(size: size, weight: weight, design: .rounded)
        }
    }

    // MARK: - Spacing (4pt scale)

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }

    // MARK: - Corner Radius

    enum Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        static let clay: CGFloat = 28
    }

    // MARK: - Icon Sizes

    enum IconSize {
        static let sm: CGFloat = 16
        static let md: CGFloat = 24
        static let lg: CGFloat = 40
        static let xl: CGFloat = 60
        static let xxl: CGFloat = 80
    }

    // MARK: - Character Display Sizes

    enum CharSize {
        static let library: CGFloat = 44
        static let answer: CGFloat = 48
        static let practice: CGFloat = 72
    }

    // MARK: - Shadow

    enum Shadow {
        static let radius: CGFloat = 2
        static let lg: CGFloat = 8
        static let xl: CGFloat = 16
    }

    // MARK: - Animation

    enum Animation {
        static let cardPress = SwiftUI.Animation.easeInOut(duration: 0.15)
        static let bounce = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.4)
        static let gentle = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.6)
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.3)
    }
}

// MARK: - Claymorphism ViewModifier

struct ClaymorphismCard: ViewModifier {
    var cornerRadius: CGFloat = DesignTokens.Radius.clay
    var fillColor: Color = DesignTokens.Colors.surface
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        let isDark = colorScheme == .dark
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(fillColor)
                    .shadow(color: (isDark ? Color.white.opacity(0.08) : Color.white.opacity(0.6)), radius: 6, x: -4, y: -4)
                    .shadow(color: .black.opacity(isDark ? 0.4 : 0.15), radius: 8, x: 6, y: 6)
                    .shadow(color: .black.opacity(isDark ? 0.2 : 0.05), radius: 16, x: 10, y: 10)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

struct ClaymorphismGradientCard: ViewModifier {
    let gradient: AnyShapeStyle
    var cornerRadius: CGFloat = DesignTokens.Radius.clay
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        let isDark = colorScheme == .dark
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(gradient)
                    .shadow(color: (isDark ? Color.white.opacity(0.05) : Color.white.opacity(0.4)), radius: 4, x: -3, y: -3)
                    .shadow(color: .black.opacity(isDark ? 0.35 : 0.2), radius: 8, x: 6, y: 6)
                    .shadow(color: .black.opacity(isDark ? 0.15 : 0.08), radius: 16, x: 10, y: 10)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

extension View {
    func claymorphism(cornerRadius: CGFloat = DesignTokens.Radius.clay, fillColor: Color = DesignTokens.Colors.surface) -> some View {
        modifier(ClaymorphismCard(cornerRadius: cornerRadius, fillColor: fillColor))
    }

    func claymorphismGradient(_ gradient: some ShapeStyle, cornerRadius: CGFloat = DesignTokens.Radius.clay) -> some View {
        modifier(ClaymorphismGradientCard(gradient: AnyShapeStyle(gradient), cornerRadius: cornerRadius))
    }
}
