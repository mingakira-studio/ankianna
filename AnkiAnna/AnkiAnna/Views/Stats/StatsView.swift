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
                    if let badges = profile?.badges, !badges.isEmpty {
                        ForEach(badges, id: \.self) { badge in
                            Text(badge)
                        }
                    } else {
                        Text("继续学习解锁徽章").foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("统计")
        }
    }
}
