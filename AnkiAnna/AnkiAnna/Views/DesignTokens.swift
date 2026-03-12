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

        // Surfaces
        static let surface = Color(.systemGray6)
        static let surfaceSecondary = Color(.systemGray5)
        static let canvas = Color.white

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

    // MARK: - Typography (SF Rounded)

    enum Font {
        static let caption = SwiftUI.Font.system(size: 12, weight: .regular, design: .rounded)
        static let caption2 = SwiftUI.Font.system(size: 11, weight: .regular, design: .rounded)
        static let footnote = SwiftUI.Font.system(size: 13, weight: .regular, design: .rounded)
        static let body = SwiftUI.Font.system(size: 17, weight: .regular, design: .rounded)
        static let headline = SwiftUI.Font.system(size: 17, weight: .semibold, design: .rounded)
        static let subheadline = SwiftUI.Font.system(size: 15, weight: .regular, design: .rounded)
        static let title3 = SwiftUI.Font.system(size: 20, weight: .semibold, design: .rounded)
        static let title2 = SwiftUI.Font.system(size: 22, weight: .bold, design: .rounded)
        static let title = SwiftUI.Font.system(size: 28, weight: .bold, design: .rounded)
        static let largeTitle = SwiftUI.Font.system(size: 34, weight: .bold, design: .rounded)

        // Custom sizes for specific use cases
        static let comboText = SwiftUI.Font.system(size: 22, weight: .bold, design: .rounded)
        static let encouragement = SwiftUI.Font.system(size: 24, weight: .semibold, design: .rounded)
        static let points = SwiftUI.Font.system(size: 28, weight: .bold, design: .rounded)
        static let sectionTitle = SwiftUI.Font.system(size: 28, weight: .bold, design: .rounded)
        static let feedbackTitle = SwiftUI.Font.system(size: 32, weight: .bold, design: .rounded)
        static let inputField = SwiftUI.Font.system(size: 32, design: .rounded)
        static let promptText = SwiftUI.Font.system(size: 36, weight: .medium, design: .rounded)
        static let spellingChar = SwiftUI.Font.system(size: 36, weight: .bold, design: .monospaced)

        /// SF Rounded font at arbitrary size/weight for special cases
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
    }

    // MARK: - Animation

    enum Animation {
        static let cardPress = SwiftUI.Animation.easeInOut(duration: 0.15)
        static let bounce = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.4)
        static let gentle = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.6)
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.3)
    }
}
