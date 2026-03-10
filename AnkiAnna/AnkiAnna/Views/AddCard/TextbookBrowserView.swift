import SwiftUI
import SwiftData

/// Three-level textbook browser: Grade → Lessons → Characters
/// Embedded in AddCardView as "课本字库" entry
struct TextbookBrowserView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        List {
            ForEach(TextbookDataProvider.Grade.allCases, id: \.rawValue) { grade in
                Section(grade.displayName) {
                    ForEach(TextbookDataProvider.Semester.allCases, id: \.rawValue) { semester in
                        NavigationLink {
                            LessonListView(grade: grade, semester: semester)
                        } label: {
                            Label(
                                "\(grade.displayName)\(semester.displayName)",
                                systemImage: "book"
                            )
                        }
                    }
                }
            }
        }
        .navigationTitle("课本字库")
    }
}

// MARK: - Lesson List

struct LessonListView: View {
    let grade: TextbookDataProvider.Grade
    let semester: TextbookDataProvider.Semester
    @Environment(\.modelContext) private var modelContext

    private var lessons: [TextbookDataProvider.TextbookLesson] {
        TextbookDataProvider.loadLessons(grade: grade, semester: semester)
    }

    var body: some View {
        List {
            ForEach(lessons, id: \.lesson) { lesson in
                NavigationLink {
                    LessonCharactersView(
                        grade: grade, semester: semester, lesson: lesson
                    )
                } label: {
                    HStack {
                        Text(lesson.displayLabel)
                        Spacer()
                        Text("\(lesson.characters.count) 字")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("\(grade.displayName)\(semester.displayName)")
    }
}

// MARK: - Lesson Characters

struct LessonCharactersView: View {
    let grade: TextbookDataProvider.Grade
    let semester: TextbookDataProvider.Semester
    let lesson: TextbookDataProvider.TextbookLesson
    @Environment(\.modelContext) private var modelContext
    @Query private var existingCards: [Card]
    @State private var addedChars: Set<String> = []

    init(grade: TextbookDataProvider.Grade,
         semester: TextbookDataProvider.Semester,
         lesson: TextbookDataProvider.TextbookLesson) {
        self.grade = grade
        self.semester = semester
        self.lesson = lesson
        self._existingCards = Query(sort: \Card.createdAt)
    }

    private var existingAnswers: Set<String> {
        Set(existingCards.map(\.answer))
    }

    var body: some View {
        List {
            Section {
                Button {
                    addAllCharacters()
                } label: {
                    Label("全部加入卡片库", systemImage: "plus.circle.fill")
                }
                .disabled(allAdded)
                .accessibilityIdentifier("addAllButton")
            }

            Section("生字") {
                ForEach(lesson.characters, id: \.char) { char in
                    HStack {
                        Text(char.char)
                            .font(.title)
                        VStack(alignment: .leading) {
                            Text(char.words.joined(separator: "、"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if isAdded(char.char) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .accessibilityIdentifier("added-\(char.char)")
                        } else {
                            Button {
                                addCharacter(char)
                            } label: {
                                Image(systemName: "plus.circle")
                                    .foregroundStyle(.blue)
                            }
                            .accessibilityIdentifier("add-\(char.char)")
                        }
                    }
                }
            }
        }
        .navigationTitle(lesson.displayLabel)
    }

    private var allAdded: Bool {
        lesson.characters.allSatisfy { isAdded($0.char) }
    }

    private func isAdded(_ char: String) -> Bool {
        existingAnswers.contains(char) || addedChars.contains(char)
    }

    private func addCharacter(_ char: TextbookDataProvider.TextbookCharacter) {
        let added = TextbookSeeder.addCharacterToLibrary(
            char, grade: grade, semester: semester,
            lesson: lesson.lesson, lessonTitle: lesson.title,
            modelContext: modelContext
        )
        if added {
            addedChars.insert(char.char)
        }
    }

    private func addAllCharacters() {
        for char in lesson.characters where !isAdded(char.char) {
            addCharacter(char)
        }
    }
}
