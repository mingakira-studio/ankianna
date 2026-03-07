import Foundation

enum Badge: String, CaseIterable {
    case firstStep
    case streak7
    case streak30
    case century
    case points1000

    var id: String { rawValue }

    var name: String {
        switch self {
        case .firstStep: return "小小学徒"
        case .streak7: return "坚持一周"
        case .streak30: return "月度之星"
        case .century: return "百题勇士"
        case .points1000: return "积分达人"
        }
    }

    var icon: String {
        switch self {
        case .firstStep: return "🌱"
        case .streak7: return "🔥"
        case .streak30: return "⭐"
        case .century: return "💯"
        case .points1000: return "💰"
        }
    }

    var description: String {
        switch self {
        case .firstStep: return "完成第一次复习"
        case .streak7: return "连续学习7天"
        case .streak30: return "连续学习30天"
        case .century: return "累计复习100次"
        case .points1000: return "累计获得1000积分"
        }
    }

    func isUnlocked(stats: BadgeService.Stats) -> Bool {
        switch self {
        case .firstStep: return stats.totalReviews >= 1
        case .streak7: return stats.streak >= 7
        case .streak30: return stats.streak >= 30
        case .century: return stats.totalReviews >= 100
        case .points1000: return stats.totalPoints >= 1000
        }
    }
}

enum BadgeService {
    struct Stats {
        let totalReviews: Int
        let correctReviews: Int
        let streak: Int
        let totalPoints: Int
    }

    static func checkNewBadges(stats: Stats, existingBadges: [String]) -> [Badge] {
        Badge.allCases.filter { badge in
            badge.isUnlocked(stats: stats) && !existingBadges.contains(badge.id)
        }
    }
}
