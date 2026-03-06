import XCTest
@testable import AnkiAnna

/// Tests for subtask 2: Expand TextbookDataProvider to support grades 1-5
final class TextbookGradeTests: XCTestCase {

    // MARK: - Grade enum

    func testGradeEnumAllCases() {
        let grades = TextbookDataProvider.Grade.allCases
        XCTAssertEqual(grades.count, 5)
        XCTAssertEqual(grades.first?.rawValue, 1)
        XCTAssertEqual(grades.last?.rawValue, 5)
    }

    func testGradeDisplayName() {
        XCTAssertEqual(TextbookDataProvider.Grade.grade1.displayName, "一年级")
        XCTAssertEqual(TextbookDataProvider.Grade.grade2.displayName, "二年级")
        XCTAssertEqual(TextbookDataProvider.Grade.grade3.displayName, "三年级")
        XCTAssertEqual(TextbookDataProvider.Grade.grade4.displayName, "四年级")
        XCTAssertEqual(TextbookDataProvider.Grade.grade5.displayName, "五年级")
    }

    // MARK: - Resource naming

    func testResourceName() {
        XCTAssertEqual(
            TextbookDataProvider.resourceName(grade: .grade1, semester: .upper),
            "textbook_grade1_upper"
        )
        XCTAssertEqual(
            TextbookDataProvider.resourceName(grade: .grade3, semester: .lower),
            "textbook_grade3_lower"
        )
    }

    // MARK: - Loading with grade parameter

    func testLoadLessonsWithGrade() {
        // Grade 2 upper should still work (existing data)
        let lessons = TextbookDataProvider.loadLessons(grade: .grade2, semester: .upper)
        XCTAssertFalse(lessons.isEmpty)
        XCTAssertEqual(lessons.first?.unit, 1)
    }

    func testLoadLessonsGrade2LowerStillWorks() {
        let lessons = TextbookDataProvider.loadLessons(grade: .grade2, semester: .lower)
        XCTAssertFalse(lessons.isEmpty)
    }

    // MARK: - Semester display name with grade

    func testSemesterDisplayNameWithGrade() {
        XCTAssertEqual(
            TextbookDataProvider.semesterDisplayName(grade: .grade1, semester: .upper),
            "一年级上册"
        )
        XCTAssertEqual(
            TextbookDataProvider.semesterDisplayName(grade: .grade3, semester: .lower),
            "三年级下册"
        )
    }

    // MARK: - All characters across grades

    func testAllCharactersIncludesMultipleGrades() {
        let chars = TextbookDataProvider.allCharacters()
        // Should have characters from grade 2 at minimum
        XCTAssertFalse(chars.isEmpty)
    }

    // MARK: - Context for words with grade

    func testContextForWordsWithGrade() {
        let context = TextbookDataProvider.contextForWords(["两"], grade: .grade2, semester: .upper)
        XCTAssertFalse(context.isEmpty)
        XCTAssertTrue(context.contains("两"))
    }
}
