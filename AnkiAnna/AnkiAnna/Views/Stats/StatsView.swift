import SwiftUI
import SwiftData

struct StatsView: View {
    @Query(sort: \DailySession.date, order: .reverse) private var sessions: [DailySession]
    @Query private var profiles: [UserProfile]

    private var profile: UserProfile? { profiles.first }
    private var currentStreak: Int {
        var streak = 0
        let calendar = Calendar.current
        var checkDate = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
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

    var body: some View {
        NavigationStack {
            List {
                Section {
                    let info = LevelService.levelInfo(for: profile?.totalPoints ?? 0)
                    VStack(spacing: DesignTokens.Spacing.md) {
                        Text("Lv.\(info.level) \(LevelService.title(forLevel: info.level))")
                            .font(DesignTokens.Font.sectionTitle)

                        ProgressView(value: info.progressFraction)
                            .tint(.purple)

                        Text("\(info.progressInLevel)/\(info.xpNeededForCurrentLevel) XP")
                            .font(DesignTokens.Font.caption)
                            .foregroundStyle(DesignTokens.Colors.onSurfaceSecondary)
                    }
                    .padding(.vertical)
                }

                Section {
                    HStack {
                        VStack {
                            Text("\(profile?.totalPoints ?? 0)")
                                .font(DesignTokens.Font.promptText)
                            Text("积分")
                                .font(DesignTokens.Font.caption)
                                .foregroundStyle(DesignTokens.Colors.onSurfaceSecondary)
                        }
                        .frame(maxWidth: .infinity)

                        VStack {
                            Text("\(currentStreak)")
                                .font(DesignTokens.Font.promptText)
                                .foregroundStyle(DesignTokens.Colors.accent)
                            Text("连续打卡")
                                .font(DesignTokens.Font.caption)
                                .foregroundStyle(DesignTokens.Colors.onSurfaceSecondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.vertical)
                }

                Section("打卡日历（近30天）") {
                    StreakCalendarView(sessions: sessions)
                        .padding(.vertical)
                }

                Section("徽章") {
                    let earnedBadges = Set(profile?.badges ?? [])
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 80), spacing: DesignTokens.Spacing.lg)
                    ], spacing: DesignTokens.Spacing.lg) {
                        ForEach(Badge.allCases, id: \.id) { badge in
                            let isEarned = earnedBadges.contains(badge.id)
                            VStack(spacing: DesignTokens.Spacing.xs) {
                                Text(badge.icon)
                                    .font(DesignTokens.Font.promptText)
                                Text(badge.name)
                                    .font(DesignTokens.Font.caption)
                                    .multilineTextAlignment(.center)
                            }
                            .opacity(isEarned ? 1.0 : 0.3)
                            .grayscale(isEarned ? 0.0 : 1.0)
                        }
                    }
                    .padding(.vertical, DesignTokens.Spacing.sm)
                }
            }
            .navigationTitle("统计")
        }
    }
}
