import Foundation
import SwiftData

enum TextbookSeeder {

    static func createCard(from char: TextbookDataProvider.TextbookCharacter,
                           type: CardType, tags: [String]) -> Card {
        let phrases = TextbookDataProvider.phrasesFromTextbookWords(char: char.char, words: char.words)
        let contexts = phrases.map { phrase in
            CardContext(
                type: phrase.type,
                text: phrase.text,
                fullText: phrase.fullText,
                source: .textbook
            )
        }
        let card = Card(
            type: type,
            answer: char.char,
            audioText: char.char,
            hint: char.words.joined(separator: "、"),
            tags: tags,
            source: .textbook
        )
        card.contexts = contexts
        return card
    }

    static func createCharacterStats(from char: TextbookDataProvider.TextbookCharacter,
                                     grade: Int, semester: String,
                                     lesson: Int, lessonTitle: String) -> CharacterStats {
        CharacterStats(
            character: char.char,
            grade: grade,
            semester: semester,
            lesson: lesson,
            lessonTitle: lessonTitle,
            words: char.words
        )
    }

    /// Add a single character to the user's card library. Returns true if added, false if already exists.
    @MainActor
    static func addCharacterToLibrary(
        _ char: TextbookDataProvider.TextbookCharacter,
        grade: TextbookDataProvider.Grade,
        semester: TextbookDataProvider.Semester,
        lesson: Int, lessonTitle: String,
        modelContext: ModelContext
    ) -> Bool {
        // Check if card already exists
        let answer = char.char
        let descriptor = FetchDescriptor<Card>(predicate: #Predicate { $0.answer == answer })
        if let existing = try? modelContext.fetch(descriptor), !existing.isEmpty {
            return false
        }

        let tags = ["\(grade.displayName)\(semester.displayName)", lessonTitle]
        let card = createCard(from: char, type: .chineseWriting, tags: tags)
        modelContext.insert(card)

        // Create CharacterStats if missing
        let charStr = char.char
        let statsDescriptor = FetchDescriptor<CharacterStats>(predicate: #Predicate { $0.character == charStr })
        if let existingStats = try? modelContext.fetch(statsDescriptor), existingStats.isEmpty {
            let stats = createCharacterStats(
                from: char, grade: grade.rawValue,
                semester: semester.rawValue,
                lesson: lesson, lessonTitle: lessonTitle
            )
            modelContext.insert(stats)
        }

        return true
    }

    /// Seed only grade 2 upper semester lesson 1 as default content
    @MainActor
    static func seedDefaultLesson(modelContext: ModelContext) {
        let lessons = TextbookDataProvider.loadLessons(grade: .grade2, semester: .upper)
        guard let firstLesson = lessons.first else { return }

        let tags = ["\(TextbookDataProvider.Grade.grade2.displayName)\(TextbookDataProvider.Semester.upper.displayName)",
                    firstLesson.displayLabel]

        for char in firstLesson.characters {
            let card = createCard(from: char, type: .chineseWriting, tags: tags)
            modelContext.insert(card)

            let stats = createCharacterStats(
                from: char, grade: 2,
                semester: TextbookDataProvider.Semester.upper.rawValue,
                lesson: firstLesson.lesson,
                lessonTitle: firstLesson.title
            )
            modelContext.insert(stats)
        }
    }

    @MainActor
    static func seedAllTextbooks(modelContext: ModelContext) {
        var seenCharacters: Set<String> = []

        for grade in TextbookDataProvider.Grade.allCases {
            for semester in TextbookDataProvider.Semester.allCases {
                let lessons = TextbookDataProvider.loadLessons(grade: grade, semester: semester)
                for lesson in lessons {
                    for char in lesson.characters {
                        let tags = ["\(grade.displayName)\(semester.displayName)",
                                    lesson.displayLabel]
                        let card = createCard(from: char, type: .chineseWriting, tags: tags)
                        modelContext.insert(card)

                        // Only create one CharacterStats per unique character
                        if !seenCharacters.contains(char.char) {
                            seenCharacters.insert(char.char)
                            let stats = createCharacterStats(
                                from: char, grade: grade.rawValue,
                                semester: semester.rawValue,
                                lesson: lesson.lesson,
                                lessonTitle: lesson.title
                            )
                            modelContext.insert(stats)
                        }
                    }
                }
            }
        }
    }
}
