import SwiftUI
import SwiftData

struct TodayOverviewView: View {
    let sessions: [DailySession]
    let characterStats: [CharacterStats]
    let dailyGoal: Int

    private var todaySession: DailySession? {
        let calendar = Calendar.current
        return sessions.first { calendar.isDateInToday($0.date) }
    }

    private var practiceStreak: Int {
        var streak = 0
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        var checkDate = Date()
        for session in sessions {
            let sessionKey = formatter.string(from: session.date)
            let checkKey = formatter.string(from: checkDate)
            if sessionKey == checkKey && session.completedCount > 0 {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else {
                break
            }
        }
        return streak
    }

    /// Streak of consecutive days where completedCount >= targetCount
    private var goalStreak: Int {
        var streak = 0
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        var checkDate = Date()
        for session in sessions {
            let sessionKey = formatter.string(from: session.date)
            let checkKey = formatter.string(from: checkDate)
            if sessionKey == checkKey {
                if session.completedCount >= session.targetCount && session.targetCount > 0 {
                    streak += 1
                    checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
                } else {
                    break
                }
            } else {
                break
            }
        }
        return streak
    }

    private var todayGoalCompleted: Bool {
        guard let session = todaySession else { return false }
        return session.completedCount >= dailyGoal && dailyGoal > 0
    }

    private var todayAccuracy: Int {
        guard let session = todaySession, session.completedCount > 0 else { return 0 }
        return Int(Double(session.correctCount) / Double(session.completedCount) * 100)
    }

    private var todayNewMastered: Int {
        todaySession?.newMastered ?? 0
    }

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            // Daily goal status
            HStack(spacing: DesignTokens.Spacing.sm) {
                Image(systemName: todayGoalCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(todayGoalCompleted ? DesignTokens.Colors.success : DesignTokens.Colors.onSurfaceSecondary)
                    .font(DesignTokens.Font.title3)
                Text(todayGoalCompleted ? "今日目标已完成!" : "今日目标: \(todaySession?.completedCount ?? 0)/\(dailyGoal)")
                    .font(DesignTokens.Font.headline)
                    .foregroundStyle(todayGoalCompleted ? DesignTokens.Colors.success : DesignTokens.Colors.onSurface)
                Spacer()
                if goalStreak > 0 {
                    Label("\(goalStreak)天", systemImage: "flame.fill")
                        .font(DesignTokens.Font.caption)
                        .foregroundStyle(DesignTokens.Colors.accent)
                }
            }
            .accessibilityIdentifier("dailyGoalStatus")

            // Stats grid
            HStack(spacing: DesignTokens.Spacing.md) {
                StatCard(title: "今日练习", value: "\(todaySession?.completedCount ?? 0)", icon: "pencil.line", color: DesignTokens.Colors.primary)
                StatCard(title: "正确率", value: "\(todayAccuracy)%", icon: "checkmark.circle", color: DesignTokens.Colors.success)
                StatCard(title: "新掌握", value: "\(todayNewMastered)", icon: "star.fill", color: DesignTokens.Colors.warning)
                StatCard(title: "连续打卡", value: "\(practiceStreak)天", icon: "flame.fill", color: DesignTokens.Colors.accent)
            }
        }
        .padding(.vertical, DesignTokens.Spacing.sm)
    }
}

private struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xs) {
            Image(systemName: icon)
                .font(DesignTokens.Font.title3)
                .foregroundStyle(color)
            Text(value)
                .font(DesignTokens.Font.headline)
            Text(title)
                .font(DesignTokens.Font.caption)
                .foregroundStyle(DesignTokens.Colors.onSurfaceSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}
