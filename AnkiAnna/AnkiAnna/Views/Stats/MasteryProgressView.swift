import SwiftUI

struct MasteryProgressView: View {
    let stats: [CharacterStats]

    private var masteredCount: Int { stats.filter { $0.masteryLevel == .mastered }.count }
    private var learningCount: Int { stats.filter { $0.masteryLevel == .learning }.count }
    private var difficultCount: Int { stats.filter { $0.masteryLevel == .difficult }.count }
    private var newCount: Int { stats.filter { $0.masteryLevel == .new }.count }
    private var total: Int { stats.count }

    var body: some View {
        if stats.isEmpty {
            emptyState
        } else {
            VStack(spacing: DesignTokens.Spacing.lg) {
                donutSection
                gradeProgressSection
            }
            .padding(.vertical, DesignTokens.Spacing.sm)
        }
    }

    private var emptyState: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            Image(systemName: "chart.pie")
                .font(.system(size: DesignTokens.IconSize.lg))
                .foregroundStyle(DesignTokens.Colors.onSurfaceSecondary)
            Text("还没有学习数据")
                .font(DesignTokens.Font.body)
                .foregroundStyle(DesignTokens.Colors.onSurfaceSecondary)
        }
        .padding(.vertical)
    }

    private var donutSection: some View {
        HStack(spacing: DesignTokens.Spacing.xl) {
            DonutChart(
                segments: [
                    .init(value: Double(masteredCount), color: DesignTokens.Colors.success),
                    .init(value: Double(learningCount), color: DesignTokens.Colors.primary),
                    .init(value: Double(difficultCount), color: DesignTokens.Colors.warning),
                    .init(value: Double(newCount), color: Color(.systemGray4)),
                ]
            )
            .frame(width: 120, height: 120)
            .accessibilityIdentifier("masteryDonutChart")

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                legendRow(color: DesignTokens.Colors.success, label: "已掌握", count: masteredCount)
                legendRow(color: DesignTokens.Colors.primary, label: "学习中", count: learningCount)
                legendRow(color: DesignTokens.Colors.warning, label: "疑难字", count: difficultCount)
                legendRow(color: Color(.systemGray4), label: "未学习", count: newCount)
            }
        }
    }

    private func legendRow(color: Color, label: String, count: Int) -> some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(label)
                .font(DesignTokens.Font.body)
            Spacer()
            Text("\(count)")
                .font(DesignTokens.Font.headline)
                .foregroundStyle(DesignTokens.Colors.onSurfaceSecondary)
        }
    }

    private var gradeProgressSection: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            ForEach(1...5, id: \.self) { grade in
                let gradeStats = stats.filter { $0.grade == grade }
                if !gradeStats.isEmpty {
                    let mastered = gradeStats.filter { $0.masteryLevel == .mastered }.count
                    HStack(spacing: DesignTokens.Spacing.md) {
                        Text("\(grade)年级")
                            .font(DesignTokens.Font.caption)
                            .frame(width: 50, alignment: .leading)
                        ProgressView(value: Double(mastered), total: Double(gradeStats.count))
                            .tint(DesignTokens.Colors.success)
                        Text("\(mastered)/\(gradeStats.count)")
                            .font(DesignTokens.Font.caption)
                            .foregroundStyle(DesignTokens.Colors.onSurfaceSecondary)
                            .frame(width: 50, alignment: .trailing)
                    }
                }
            }
        }
    }
}

// MARK: - Donut Chart

private struct DonutSegment {
    let value: Double
    let color: Color
}

private struct DonutChart: View {
    let segments: [DonutSegment]

    var body: some View {
        let total = segments.reduce(0) { $0 + $1.value }
        if total == 0 {
            Circle()
                .stroke(Color(.systemGray4), lineWidth: 20)
        } else {
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let radius = min(size.width, size.height) / 2
                let lineWidth: CGFloat = 20
                var startAngle = Angle.degrees(-90)
                for segment in segments where segment.value > 0 {
                    let fraction = segment.value / total
                    let endAngle = startAngle + Angle.degrees(360 * fraction)

                    let path = Path { p in
                        p.addArc(center: center, radius: radius - lineWidth / 2,
                                 startAngle: startAngle, endAngle: endAngle, clockwise: false)
                    }
                    context.stroke(path, with: .color(segment.color),
                                   style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt))
                    startAngle = endAngle
                }

                // Center text
                let text = Text("\(Int(segments.first?.value ?? 0))")
                    .font(DesignTokens.Font.headline)
                    .foregroundStyle(DesignTokens.Colors.onSurface)
                context.draw(text, at: center)
            }
        }
    }
}
