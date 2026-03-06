import Foundation

/// Loads textbook vocabulary data from bundled JSON resources
/// to provide context for AI card generation.
enum TextbookDataProvider {

    struct TextbookLesson: Decodable {
        let lesson: Int
        let title: String
        let type: String
        let unit: Int
        let characters: [TextbookCharacter]

        var displayLabel: String {
            type == "识字" ? "识字\(lesson) \(title)" : "第\(lesson)课 \(title)"
        }
    }

    struct TextbookCharacter: Decodable {
        let char: String
        let words: [String]
    }

    // MARK: - Grade enum

    enum Grade: Int, CaseIterable, Codable {
        case grade1 = 1, grade2, grade3, grade4, grade5

        var displayName: String {
            switch self {
            case .grade1: return "一年级"
            case .grade2: return "二年级"
            case .grade3: return "三年级"
            case .grade4: return "四年级"
            case .grade5: return "五年级"
            }
        }
    }

    // MARK: - Semester enum

    enum Semester: String, CaseIterable, Codable {
        case upper
        case lower

        var displayName: String {
            switch self {
            case .upper: return "上册"
            case .lower: return "下册"
            }
        }
    }

    // MARK: - Resource naming

    /// Build the JSON resource name for a given grade and semester
    static func resourceName(grade: Grade, semester: Semester) -> String {
        "textbook_grade\(grade.rawValue)_\(semester.rawValue)"
    }

    /// Human-readable display name combining grade and semester
    static func semesterDisplayName(grade: Grade, semester: Semester) -> String {
        let semesterSuffix = semester == .upper ? "上册" : "下册"
        return "\(grade.displayName)\(semesterSuffix)"
    }

    // MARK: - Loading

    /// Load all lessons for a specific grade and semester
    static func loadLessons(grade: Grade, semester: Semester) -> [TextbookLesson] {
        let name = resourceName(grade: grade, semester: semester)
        guard let url = Bundle.main.url(forResource: name, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let lessons = try? JSONDecoder().decode([TextbookLesson].self, from: data) else {
            return []
        }
        return lessons
    }

    /// Backward-compatible: load lessons for grade 2 (existing callers)
    static func loadLessons(semester: Semester) -> [TextbookLesson] {
        loadLessons(grade: .grade2, semester: semester)
    }

    // MARK: - Context

    /// Find textbook words and their phrases for given target characters.
    /// Returns a context string suitable for injection into AI prompts.
    static func contextForWords(_ words: [String], grade: Grade, semester: Semester) -> String {
        let lessons = loadLessons(grade: grade, semester: semester)
        var matches: [(char: String, lesson: String, words: [String])] = []
        let displayName = semesterDisplayName(grade: grade, semester: semester)

        for lesson in lessons {
            for char in lesson.characters {
                if words.contains(char.char) {
                    matches.append((
                        char: char.char,
                        lesson: "\(displayName) \(lesson.title)",
                        words: char.words
                    ))
                }
            }
        }

        guard !matches.isEmpty else { return "" }

        var lines: [String] = ["以下是课本中这些字的组词参考："]
        for match in matches {
            lines.append("- \(match.char)（\(match.lesson)）：\(match.words.joined(separator: "、"))")
        }
        return lines.joined(separator: "\n")
    }

    /// Backward-compatible: search across all grades and semesters
    static func contextForWords(_ words: [String], semester: Semester? = nil) -> String {
        var allMatches: [(char: String, lesson: String, words: [String])] = []

        let grades = Grade.allCases
        let semesters: [Semester] = semester.map { [$0] } ?? Semester.allCases

        for grade in grades {
            for sem in semesters {
                let lessons = loadLessons(grade: grade, semester: sem)
                let displayName = semesterDisplayName(grade: grade, semester: sem)
                for lesson in lessons {
                    for char in lesson.characters {
                        if words.contains(char.char) {
                            allMatches.append((
                                char: char.char,
                                lesson: "\(displayName) \(lesson.title)",
                                words: char.words
                            ))
                        }
                    }
                }
            }
        }

        guard !allMatches.isEmpty else { return "" }

        var lines: [String] = ["以下是课本中这些字的组词参考："]
        for match in allMatches {
            lines.append("- \(match.char)（\(match.lesson)）：\(match.words.joined(separator: "、"))")
        }
        return lines.joined(separator: "\n")
    }

    /// Get all characters from a specific unit for browsing
    static func charactersForUnit(semester: Semester, unit: Int) -> [TextbookCharacter] {
        loadLessons(semester: semester)
            .filter { $0.unit == unit }
            .flatMap { $0.characters }
    }

    /// Convert textbook words into phrase contexts (deterministic, no AI)
    static func phrasesFromTextbookWords(char: String, words: [String])
        -> [(type: ContextType, text: String, fullText: String)] {
        words.map { word in
            (type: .phrase,
             text: word.replacingOccurrences(of: char, with: "___"),
             fullText: word)
        }
    }

    /// Get all unique characters across all grades and semesters
    static func allCharacters() -> [String] {
        var chars: [String] = []
        for grade in Grade.allCases {
            for sem in Semester.allCases {
                for lesson in loadLessons(grade: grade, semester: sem) {
                    for char in lesson.characters {
                        if !chars.contains(char.char) {
                            chars.append(char.char)
                        }
                    }
                }
            }
        }
        return chars
    }
}
