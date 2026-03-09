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
