import SwiftUI
import Charts

struct TrendChartView: View {
    let sessions: [DailySession]
    @State private var period: TrendPeriod = .week

    enum TrendPeriod: String, CaseIterable {
        case week = "7天"
        case month = "30天"

        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            }
        }
    }

    private var filteredSessions: [DailySession] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -period.days, to: Date())!
        return sessions.filter { $0.date >= cutoff }.sorted { $0.date < $1.date }
    }

    var body: some View {
        if sessions.isEmpty {
            emptyState
        } else {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                Picker("时间范围", selection: $period) {
                    ForEach(TrendPeriod.allCases, id: \.self) { Text($0.rawValue) }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("trendPeriodPicker")

                if filteredSessions.isEmpty {
                    Text("该时间段暂无数据")
                        .font(DesignTokens.Font.body)
                        .foregroundStyle(DesignTokens.Colors.onSurfaceSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical)
                } else {
                    practiceChart
                    accuracyChart
                }
            }
            .padding(.vertical, DesignTokens.Spacing.sm)
        }
    }

    private var emptyState: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: DesignTokens.IconSize.lg))
                .foregroundStyle(DesignTokens.Colors.onSurfaceSecondary)
            Text("开始学习后这里会显示趋势")
                .font(DesignTokens.Font.body)
                .foregroundStyle(DesignTokens.Colors.onSurfaceSecondary)
        }
        .padding(.vertical)
    }

    private var practiceChart: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            Text("每日练习数")
                .font(DesignTokens.Font.caption)
                .foregroundStyle(DesignTokens.Colors.onSurfaceSecondary)
            Chart(filteredSessions, id: \.id) { session in
                BarMark(
                    x: .value("日期", session.date, unit: .day),
                    y: .value("练习数", session.completedCount)
                )
                .foregroundStyle(DesignTokens.Colors.primary.gradient)
                .cornerRadius(4)
            }
            .frame(height: 120)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisValueLabel(format: .dateTime.day())
                }
            }
            .accessibilityIdentifier("practiceCountChart")
        }
    }

    private var accuracyChart: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            Text("正确率")
                .font(DesignTokens.Font.caption)
                .foregroundStyle(DesignTokens.Colors.onSurfaceSecondary)
            Chart(filteredSessions, id: \.id) { session in
                let accuracy = session.completedCount > 0
                    ? Double(session.correctCount) / Double(session.completedCount) * 100
                    : 0
                LineMark(
                    x: .value("日期", session.date, unit: .day),
                    y: .value("正确率", accuracy)
                )
                .foregroundStyle(DesignTokens.Colors.success)
                .symbol(.circle)
                .interpolationMethod(.catmullRom)

                AreaMark(
                    x: .value("日期", session.date, unit: .day),
                    y: .value("正确率", accuracy)
                )
                .foregroundStyle(DesignTokens.Colors.success.opacity(0.1))
                .interpolationMethod(.catmullRom)
            }
            .frame(height: 120)
            .chartYScale(domain: 0...100)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisValueLabel(format: .dateTime.day())
                }
            }
            .accessibilityIdentifier("accuracyChart")
        }
    }
}
