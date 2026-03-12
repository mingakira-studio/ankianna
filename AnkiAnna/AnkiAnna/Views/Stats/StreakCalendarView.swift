import SwiftUI
import SwiftData

struct StreakCalendarView: View {
    let sessions: [DailySession]

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private var completedDates: Set<String> {
        Set(sessions.filter { $0.completedCount > 0 }.map { Self.dateFormatter.string(from: $0.date) })
    }

    private var last30Days: [Date] {
        let calendar = Calendar.current
        let today = Date()
        return (0..<30).reversed().map { calendar.date(byAdding: .day, value: -$0, to: today)! }
    }

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
            ForEach(last30Days, id: \.self) { day in
                let key = Self.dateFormatter.string(from: day)
                let completed = completedDates.contains(key)
                VStack(spacing: 2) {
                    Text("\(Calendar.current.component(.day, from: day))")
                        .font(.caption2)
                    Circle()
                        .fill(completed ? .green : .gray.opacity(0.2))
                        .frame(width: 28, height: 28)
                }
            }
        }
    }
}
