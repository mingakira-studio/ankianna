import Foundation

enum LevelService {
    struct LevelInfo {
        let level: Int
        let progressInLevel: Int
        let xpNeededForCurrentLevel: Int
        var progressFraction: Double {
            guard xpNeededForCurrentLevel > 0 else { return 0 }
            return Double(progressInLevel) / Double(xpNeededForCurrentLevel)
        }
    }

    /// XP required to complete a given level.
    /// Level 1 = 100, Level 2 = 200, Level 3 = 300, etc.
    static func xpNeeded(forLevel level: Int) -> Int {
        return 100 * level
    }

    /// Determine level info from total accumulated XP.
    ///
    /// Level thresholds (cumulative):
    ///   Level 1:   0 –  99  (needs 100)
    ///   Level 2: 100 – 299  (needs 200)
    ///   Level 3: 300 – 599  (needs 300)
    ///   ...
    static func levelInfo(for totalXP: Int) -> LevelInfo {
        var xp = max(totalXP, 0)
        var level = 1
        while xp >= xpNeeded(forLevel: level) {
            xp -= xpNeeded(forLevel: level)
            level += 1
        }
        return LevelInfo(
            level: level,
            progressInLevel: xp,
            xpNeededForCurrentLevel: xpNeeded(forLevel: level)
        )
    }

    /// Chinese title for a given level.
    static func title(forLevel level: Int) -> String {
        switch level {
        case 1: return "小学徒"
        case 2: return "学习者"
        case 3: return "知识探索者"
        case 4: return "记忆达人"
        case 5: return "学霸"
        default: return "学神"
        }
    }
}
