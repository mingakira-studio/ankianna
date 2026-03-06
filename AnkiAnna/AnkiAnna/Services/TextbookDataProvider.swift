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

    enum Semester: String {
        case upper = "textbook_grade2_upper"
        case lower = "textbook_grade2_lower"

        var displayName: String {
            switch self {
            case .upper: return "二年级上册"
            case .lower: return "二年级下册"
            }
        }
    }

    /// Load all lessons from a semester
    static func loadLessons(semester: Semester) -> [TextbookLesson] {
        guard let url = Bundle.main.url(forResource: semester.rawValue, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let lessons = try? JSONDecoder().decode([TextbookLesson].self, from: data) else {
            return []
        }
        return lessons
    }

    /// Find textbook words and their phrases for given target characters.
    /// Returns a context string suitable for injection into AI prompts.
    static func contextForWords(_ words: [String], semester: Semester? = nil) -> String {
        let semesters: [Semester] = semester.map { [$0] } ?? [.upper, .lower]
        var matches: [(char: String, lesson: String, words: [String])] = []

        for sem in semesters {
            let lessons = loadLessons(semester: sem)
            for lesson in lessons {
                for char in lesson.characters {
                    if words.contains(char.char) {
                        matches.append((
                            char: char.char,
                            lesson: "\(sem.displayName) \(lesson.title)",
                            words: char.words
                        ))
                    }
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

    /// Get all unique characters across both semesters
    static func allCharacters() -> [String] {
        var chars: [String] = []
        for sem in [Semester.upper, .lower] {
            for lesson in loadLessons(semester: sem) {
                for char in lesson.characters {
                    if !chars.contains(char.char) {
                        chars.append(char.char)
                    }
                }
            }
        }
        return chars
    }
}
