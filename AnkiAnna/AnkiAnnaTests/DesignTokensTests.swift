import XCTest
@testable import AnkiAnna

final class DesignTokensTests: XCTestCase {

    // MARK: - Spacing values follow 4pt scale

    func testSpacingScale() {
        XCTAssertEqual(DesignTokens.Spacing.xs, 4)
        XCTAssertEqual(DesignTokens.Spacing.sm, 8)
        XCTAssertEqual(DesignTokens.Spacing.md, 12)
        XCTAssertEqual(DesignTokens.Spacing.lg, 16)
        XCTAssertEqual(DesignTokens.Spacing.xl, 24)
        XCTAssertEqual(DesignTokens.Spacing.xxl, 32)
    }

    // MARK: - Corner radius values

    func testCornerRadiusScale() {
        XCTAssertEqual(DesignTokens.Radius.sm, 8)
        XCTAssertEqual(DesignTokens.Radius.md, 12)
        XCTAssertEqual(DesignTokens.Radius.lg, 16)
        XCTAssertEqual(DesignTokens.Radius.xl, 24)
    }

    // MARK: - Spacing monotonically increasing

    func testSpacingMonotonicallyIncreasing() {
        let values = [
            DesignTokens.Spacing.xs,
            DesignTokens.Spacing.sm,
            DesignTokens.Spacing.md,
            DesignTokens.Spacing.lg,
            DesignTokens.Spacing.xl,
            DesignTokens.Spacing.xxl
        ]
        for i in 1..<values.count {
            XCTAssertGreaterThan(values[i], values[i - 1])
        }
    }

    // MARK: - Icon sizes

    func testIconSizes() {
        XCTAssertEqual(DesignTokens.IconSize.sm, 16)
        XCTAssertEqual(DesignTokens.IconSize.md, 24)
        XCTAssertEqual(DesignTokens.IconSize.lg, 40)
        XCTAssertEqual(DesignTokens.IconSize.xl, 60)
        XCTAssertEqual(DesignTokens.IconSize.xxl, 80)
    }

    // MARK: - Character display sizes

    func testCharacterDisplaySizes() {
        XCTAssertEqual(DesignTokens.CharSize.answer, 48)
        XCTAssertEqual(DesignTokens.CharSize.practice, 72)
        XCTAssertEqual(DesignTokens.CharSize.library, 44)
    }
}
