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
                    VStack(spacing: 12) {
                        Text("Lv.\(info.level) \(LevelService.title(forLevel: info.level))")
                            .font(.system(size: 28, weight: .bold))

                        ProgressView(value: info.progressFraction)
                            .tint(.purple)

                        Text("\(info.progressInLevel)/\(info.xpNeededForCurrentLevel) XP")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical)
                }

                Section {
                    HStack {
                        VStack {
                            Text("\(profile?.totalPoints ?? 0)")
                                .font(.system(size: 36, weight: .bold))
                            Text("积分")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)

                        VStack {
                            Text("\(currentStreak)")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundStyle(.orange)
                            Text("连续打卡")
                                .font(.caption)
                                .foregroundStyle(.secondary)
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
                        GridItem(.adaptive(minimum: 80), spacing: 16)
                    ], spacing: 16) {
                        ForEach(Badge.allCases, id: \.id) { badge in
                            let isEarned = earnedBadges.contains(badge.id)
                            VStack(spacing: 4) {
                                Text(badge.icon)
                                    .font(.system(size: 36))
                                Text(badge.name)
                                    .font(.caption)
                                    .multilineTextAlignment(.center)
                            }
                            .opacity(isEarned ? 1.0 : 0.3)
                            .grayscale(isEarned ? 0.0 : 1.0)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("统计")
        }
    }
}
