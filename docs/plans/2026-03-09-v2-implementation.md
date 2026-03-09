# AnkiAnna V2 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Upgrade AnkiAnna from basic flashcards to a gamified learning platform with pre-installed character library, 4 game modes, smart SM-2 scheduling, and detailed reports.

**Architecture:** Card + CharacterStats dual model. CharacterStats tracks per-character mastery and SM-2 state. Cards remain the learning unit, auto-generated from textbook JSON. DailySession tracks daily practice for reports/streaks.

**Tech Stack:** Swift/SwiftUI, SwiftData, SM-2 algorithm, PencilKit, Google ML Kit, AVSpeechSynthesizer, XCTest

---

## Phase 1: Foundation — Data Models + Technical Debt Fix

### Task 1: Add CharacterStats Model

**Files:**
- Create: `AnkiAnna/AnkiAnna/Models/CharacterStats.swift`
- Modify: `AnkiAnna/AnkiAnna/AnkiAnnaApp.swift` (add to ModelContainer schema)
- Test: `AnkiAnna/AnkiAnnaTests/CharacterStatsTests.swift`

**Step 1: Write the failing test**

```swift
// CharacterStatsTests.swift
import XCTest
@testable import AnkiAnna

final class CharacterStatsTests: XCTestCase {
    func testMasteryLevelNew() {
        XCTAssertEqual(MasteryLevel.new.rawValue, "new")
    }

    func testMasteryLevelLearning() {
        XCTAssertEqual(MasteryLevel.learning.rawValue, "learning")
    }

    func testMasteryLevelMastered() {
        XCTAssertEqual(MasteryLevel.mastered.rawValue, "mastered")
    }

    func testComputedErrorRate() {
        // CharacterStats should compute errorRate from practiceCount and errorCount
        // errorRate = practiceCount > 0 ? Double(errorCount) / Double(practiceCount) : 0
    }

    func testComputedIsDifficult() {
        // isDifficult = practiceCount >= 3 && errorRate > 0.4
    }

    func testUpdateMasteryLevel() {
        // .new when practiceCount == 0
        // .learning when repetition < 3
        // .mastered when repetition >= 3 && interval >= 21
    }
}
```

**Step 2: Run test to verify it fails**

Run: `cd AnkiAnna && xcodebuild test -workspace AnkiAnna.xcworkspace -scheme AnkiAnna -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' -only-testing:AnkiAnnaTests/CharacterStatsTests 2>&1 | tail -20`
Expected: FAIL — cannot find `MasteryLevel` or `CharacterStats`

**Step 3: Write implementation**

```swift
// CharacterStats.swift
import Foundation
import SwiftData

enum MasteryLevel: String, Codable {
    case new
    case learning
    case mastered
}

@Model final class CharacterStats {
    var id: UUID
    var character: String
    var grade: Int
    var semester: String
    var lesson: Int
    var lessonTitle: String
    var words: [String]

    var masteryLevel: MasteryLevel
    var practiceCount: Int
    var correctCount: Int
    var errorCount: Int
    var lastPracticed: Date?
    var isManuallyReset: Bool

    var ease: Double
    var interval: Int
    var repetition: Int
    var nextReviewDate: Date?

    var errorRate: Double {
        practiceCount > 0 ? Double(errorCount) / Double(practiceCount) : 0
    }

    var isDifficult: Bool {
        practiceCount >= 3 && errorRate > 0.4
    }

    init(character: String, grade: Int, semester: String, lesson: Int,
         lessonTitle: String, words: [String]) {
        self.id = UUID()
        self.character = character
        self.grade = grade
        self.semester = semester
        self.lesson = lesson
        self.lessonTitle = lessonTitle
        self.words = words
        self.masteryLevel = .new
        self.practiceCount = 0
        self.correctCount = 0
        self.errorCount = 0
        self.lastPracticed = nil
        self.isManuallyReset = false
        self.ease = 2.5
        self.interval = 0
        self.repetition = 0
        self.nextReviewDate = nil
    }

    func updateMasteryLevel() {
        if practiceCount == 0 {
            masteryLevel = .new
        } else if repetition >= 3 && interval >= 21 {
            masteryLevel = .mastered
        } else {
            masteryLevel = .learning
        }
        if isManuallyReset {
            masteryLevel = .learning
        }
    }

    func recordReview(correct: Bool, reviewOutput: SM2Engine.ReviewOutput) {
        practiceCount += 1
        if correct {
            correctCount += 1
        } else {
            errorCount += 1
        }
        lastPracticed = Date()
        ease = reviewOutput.ease
        interval = reviewOutput.interval
        repetition = reviewOutput.repetition
        nextReviewDate = reviewOutput.nextReviewDate
        updateMasteryLevel()
    }

    func resetMastery() {
        isManuallyReset = true
        masteryLevel = .learning
        ease = 2.5
        interval = 0
        repetition = 0
        nextReviewDate = nil
    }
}
```

**Step 4: Add to ModelContainer in AnkiAnnaApp.swift**

Modify line 13 — add `CharacterStats.self` to the schema:
```swift
ModelContainer(for: Card.self, ReviewRecord.self, DailySession.self, UserProfile.self, CharacterStats.self)
```

**Step 5: Run tests to verify they pass**

Run: `cd AnkiAnna && xcodebuild test -workspace AnkiAnna.xcworkspace -scheme AnkiAnna -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' -only-testing:AnkiAnnaTests/CharacterStatsTests 2>&1 | tail -20`
Expected: PASS

**Step 6: Commit**

```bash
git add AnkiAnna/AnkiAnna/Models/CharacterStats.swift AnkiAnna/AnkiAnnaTests/CharacterStatsTests.swift AnkiAnna/AnkiAnna/AnkiAnnaApp.swift
git commit -m "feat: add CharacterStats model with mastery tracking and SM-2 state"
```

---

### Task 2: Add `repetition` field to ReviewRecord + Fix DailySession

**Files:**
- Modify: `AnkiAnna/AnkiAnna/Models/ReviewRecord.swift` — add `repetition: Int` field
- Modify: `AnkiAnna/AnkiAnna/Models/DailySession.swift` — add `newMastered: Int`, `gameMode: String?`
- Modify: `AnkiAnna/AnkiAnnaTests/ModelTests.swift` — update tests

**Step 1: Write failing tests**

Add to `ModelTests.swift`:
```swift
func testReviewRecordHasRepetition() {
    // ReviewRecord should have repetition field
    let record = ReviewRecord(...)
    XCTAssertEqual(record.repetition, 0)
}

func testDailySessionHasNewMastered() {
    let session = DailySession(...)
    XCTAssertEqual(session.newMastered, 0)
}
```

**Step 2: Run to verify failure**

**Step 3: Implementation**

In `ReviewRecord.swift`, add field:
```swift
var repetition: Int  // SM-2 repetition count after this review
```
Update the initializer to include `repetition` parameter.

In `DailySession.swift`, add fields:
```swift
var newMastered: Int     // characters newly mastered today
var gameMode: String?    // game mode used
```
Update the initializer.

**Step 4: Run all tests**

Run: `cd AnkiAnna && xcodebuild test -workspace AnkiAnna.xcworkspace -scheme AnkiAnna -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' -only-testing:AnkiAnnaTests 2>&1 | tail -30`
Expected: ALL PASS (fix any init call site breakages)

**Step 5: Commit**

```bash
git commit -am "feat: add repetition to ReviewRecord, newMastered to DailySession"
```

---

### Task 3: Textbook Seeder Service

**Files:**
- Create: `AnkiAnna/AnkiAnna/Services/TextbookSeeder.swift`
- Test: `AnkiAnna/AnkiAnnaTests/TextbookSeederTests.swift`

**Step 1: Write failing test**

```swift
// TextbookSeederTests.swift
import XCTest
@testable import AnkiAnna

final class TextbookSeederTests: XCTestCase {
    func testGenerateCardsFromCharacter() {
        let char = TextbookDataProvider.TextbookCharacter(char: "春", words: ["春天", "春风", "春雨"])
        let card = TextbookSeeder.createCard(from: char, type: .chineseWriting, tags: ["一年级上册", "第1课 春夏秋冬"])
        XCTAssertEqual(card.answer, "春")
        XCTAssertEqual(card.type, .chineseWriting)
        XCTAssertEqual(card.source, .textbook)
        XCTAssertFalse(card.contexts.isEmpty)
        // contexts should be fill-in-the-blank from words
        XCTAssertTrue(card.contexts.contains(where: { $0.text.contains("___") }))
    }

    func testGenerateCharacterStats() {
        let char = TextbookDataProvider.TextbookCharacter(char: "春", words: ["春天", "春风", "春雨"])
        let stats = TextbookSeeder.createCharacterStats(
            from: char, grade: 1, semester: "upper", lesson: 1, lessonTitle: "春夏秋冬"
        )
        XCTAssertEqual(stats.character, "春")
        XCTAssertEqual(stats.grade, 1)
        XCTAssertEqual(stats.masteryLevel, .new)
        XCTAssertEqual(stats.practiceCount, 0)
    }

    func testCountAllTextbookCharacters() {
        let count = TextbookDataProvider().allCharacters().count
        XCTAssertGreaterThan(count, 100) // should have many characters
    }
}
```

**Step 2: Run to verify failure**

**Step 3: Implementation**

```swift
// TextbookSeeder.swift
import Foundation
import SwiftData

enum TextbookSeeder {
    static func createCard(from char: TextbookDataProvider.TextbookCharacter,
                          type: CardType, tags: [String]) -> Card {
        let phrases = TextbookDataProvider.phrasesFromTextbookWords(char: char.char, words: char.words)
        let contexts = phrases.map { phrase in
            CardContext(
                type: phrase.type == "phrase" ? .phrase : .sentence,
                text: phrase.text,
                fullText: phrase.fullText,
                source: .textbook
            )
        }
        return Card(
            type: type,
            answer: char.char,
            contexts: contexts,
            audioText: char.char,
            hint: char.words.joined(separator: "、"),
            tags: tags,
            source: .textbook
        )
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

    /// Seed all textbook data into SwiftData. Call once on first launch.
    @MainActor
    static func seedAllTextbooks(modelContext: ModelContext) {
        let provider = TextbookDataProvider()
        for grade in TextbookDataProvider.Grade.allCases {
            for semester in TextbookDataProvider.Semester.allCases {
                let lessons = provider.loadLessons(grade: grade, semester: semester)
                for lesson in lessons {
                    for char in lesson.characters {
                        let tags = ["\(grade.displayName)\(semester.displayName)",
                                    lesson.displayLabel]
                        let card = createCard(from: char, type: .chineseWriting, tags: tags)
                        modelContext.insert(card)

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
```

**Step 4: Run tests**

Expected: PASS

**Step 5: Commit**

```bash
git add AnkiAnna/AnkiAnna/Services/TextbookSeeder.swift AnkiAnna/AnkiAnnaTests/TextbookSeederTests.swift
git commit -m "feat: add TextbookSeeder for offline card and stats generation"
```

---

### Task 4: Fix SM-2 Integration in LearningViewModel

**Files:**
- Modify: `AnkiAnna/AnkiAnna/Views/Learning/LearningViewModel.swift`
- Modify: `AnkiAnna/AnkiAnnaTests/LearningViewModelTests.swift`

**Step 1: Write failing test**

Add to `LearningViewModelTests.swift`:
```swift
func testSubmitAnswerUsesCharacterStatsForSM2() {
    // After submitting correct answer, CharacterStats should be updated
    // with actual SM-2 values (not hardcoded defaults)
}

func testLoadDueCardsUsesSM2Scheduling() {
    // loadDueCards should prioritize cards whose CharacterStats.nextReviewDate <= now
}
```

**Step 2: Run to verify failure**

**Step 3: Implementation**

Modify `LearningViewModel`:

1. Change `loadDueCards` to accept `CharacterStats` and use SM-2:
```swift
func loadDueCards(allCards: [Card], characterStats: [CharacterStats], dailyGoal: Int) {
    // Build card schedules from CharacterStats
    let schedules = characterStats.map { stats in
        SM2Engine.CardSchedule(
            cardId: stats.id, // We'll match by character
            nextReviewDate: stats.nextReviewDate,
            ease: stats.ease,
            interval: stats.interval,
            repetition: stats.repetition
        )
    }
    let dueSchedules = SM2Engine.selectDueCards(from: schedules, limit: dailyGoal)
    let dueCharacters = Set(dueSchedules.compactMap { schedule in
        characterStats.first(where: { $0.id == schedule.cardId })?.character
    })

    // Select cards matching due characters
    dueCards = allCards.filter { dueCharacters.contains($0.answer) }
    if dueCards.count < dailyGoal {
        // Fill with random non-due cards
        let remaining = allCards.filter { !dueCharacters.contains($0.answer) }.shuffled()
        dueCards.append(contentsOf: remaining.prefix(dailyGoal - dueCards.count))
    }

    totalCount = dueCards.count
    currentIndex = 0
    completedCount = 0
    correctCount = 0
    combo = 0
    sessionComplete = false
    usedContextIds = []
    advanceToNext()
}
```

2. Change `submitAnswer`/`submitTypedAnswer` to read from CharacterStats:
```swift
// Find CharacterStats for current card's answer
// Use stats.ease, stats.interval, stats.repetition instead of defaults
// After SM2Engine.calculateNext, call stats.recordReview(correct:reviewOutput:)
```

**Step 4: Run all tests**

Fix any broken tests due to signature changes.

**Step 5: Commit**

```bash
git commit -am "fix: SM-2 now reads actual state from CharacterStats, not defaults"
```

---

### Task 5: Fix DailySession Creation + Badge Wiring + UserProfile Init

**Files:**
- Modify: `AnkiAnna/AnkiAnna/Views/Learning/LearningViewModel.swift` — create DailySession on session complete
- Modify: `AnkiAnna/AnkiAnna/Views/Learning/LearningView.swift` — call BadgeService
- Modify: `AnkiAnna/AnkiAnna/AnkiAnnaApp.swift` — create UserProfile on first launch
- Modify: `AnkiAnna/AnkiAnna/ContentView.swift` — use profile.dailyGoal

**Step 1: Write failing tests**

```swift
func testSessionCompleteCreatesDailySession() {
    // After all cards answered, a DailySession should be created for today
}

func testBadgeCheckOnSessionComplete() {
    // After session complete, BadgeService.checkNewBadges should find new badges
}
```

**Step 2: Implementation**

In `LearningViewModel`, add method:
```swift
func completeSession(modelContext: ModelContext, profile: UserProfile) {
    sessionComplete = true
    // Create/update DailySession
    let today = Calendar.current.startOfDay(for: Date())
    let descriptor = FetchDescriptor<DailySession>(
        predicate: #Predicate { $0.date == today }
    )
    let existing = try? modelContext.fetch(descriptor).first
    if let session = existing {
        session.completedCount += completedCount
        session.correctCount += correctCount
    } else {
        let streak = calculateStreak(modelContext: modelContext)
        let session = DailySession(date: today, targetCount: totalCount,
                                   completedCount: completedCount,
                                   correctCount: correctCount,
                                   newMastered: 0, streak: streak + 1)
        modelContext.insert(session)
    }
    // Award daily completion bonus
    profile.totalPoints += PointsService.dailyCompletionBonus
    // Check badges
    let stats = BadgeService.Stats(
        totalReviews: completedCount,
        correctReviews: correctCount,
        streak: 0, // calculate from DailySession
        totalPoints: profile.totalPoints
    )
    let newBadges = BadgeService.checkNewBadges(stats: stats, existingBadges: profile.badges)
    for badge in newBadges {
        profile.badges.append(badge.rawValue)
    }
}
```

In `AnkiAnnaApp.swift`, add UserProfile initialization:
```swift
// After creating modelContainer, ensure UserProfile exists
let descriptor = FetchDescriptor<UserProfile>()
if let context = try? modelContainer.mainContext,
   (try? context.fetch(descriptor))?.isEmpty == true {
    context.insert(UserProfile(name: "Anna", dailyGoal: 15, totalPoints: 0, badges: []))
}
```

In `ContentView.swift` / `LearningView.swift`, use `profile.dailyGoal` instead of hardcoded 15.

**Step 3: Run all tests**

**Step 4: Commit**

```bash
git commit -am "fix: wire up DailySession creation, BadgeService, UserProfile init, dailyGoal"
```

---

### Task 6: App Startup Textbook Seeding

**Files:**
- Modify: `AnkiAnna/AnkiAnna/AnkiAnnaApp.swift` — call TextbookSeeder on first launch
- Modify: `AnkiAnna/AnkiAnna/ContentView.swift` — add seed check

**Step 1: Implementation**

In `AnkiAnnaApp` or `ContentView.onAppear`:
```swift
@AppStorage("hasSeededTextbook") private var hasSeeded = false

// In onAppear or init:
if !hasSeeded {
    TextbookSeeder.seedAllTextbooks(modelContext: modelContext)
    hasSeeded = true
}
```

**Step 2: Run full test suite**

Ensure all existing 105 tests still pass.

**Step 3: Commit**

```bash
git commit -am "feat: seed textbook cards and CharacterStats on first launch"
```

---

## Phase 2: Character Library (字库浏览器)

### Task 7: CharacterLibraryView — Main List

**Files:**
- Create: `AnkiAnna/AnkiAnna/Views/CharacterLibrary/CharacterLibraryView.swift`
- Modify: `AnkiAnna/AnkiAnna/ContentView.swift` — replace CardLibraryView tab

**Step 1: Implementation**

```swift
// CharacterLibraryView.swift
import SwiftUI
import SwiftData

struct CharacterLibraryView: View {
    @Query(sort: \CharacterStats.grade) var allStats: [CharacterStats]
    @State private var searchText = ""
    @State private var selectedGrade: Int? = nil
    @State private var selectedSemester: String? = nil
    @State private var selectedMastery: MasteryLevel? = nil

    var filteredStats: [CharacterStats] {
        allStats.filter { stats in
            (searchText.isEmpty || stats.character.contains(searchText)) &&
            (selectedGrade == nil || stats.grade == selectedGrade) &&
            (selectedSemester == nil || stats.semester == selectedSemester) &&
            (selectedMastery == nil || stats.masteryLevel == selectedMastery)
        }
    }

    var masteredCount: Int { allStats.filter { $0.masteryLevel == .mastered }.count }
    var learningCount: Int { allStats.filter { $0.masteryLevel == .learning }.count }
    var difficultCount: Int { allStats.filter { $0.isDifficult }.count }

    var groupedByLesson: [(key: String, value: [CharacterStats])] {
        Dictionary(grouping: filteredStats) { stats in
            "\(stats.grade)-\(stats.semester)-\(stats.lesson)"
        }
        .sorted { $0.key < $1.key }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter bar
                filterBar
                // Summary stats
                summaryBar
                // Character list grouped by lesson
                List {
                    ForEach(groupedByLesson, id: \.key) { group in
                        Section(header: Text(group.value.first?.lessonTitle ?? "")) {
                            ForEach(group.value) { stats in
                                NavigationLink(destination: CharacterDetailView(stats: stats)) {
                                    CharacterRow(stats: stats)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("字库 (\(allStats.count))")
            .searchable(text: $searchText, prompt: "搜索汉字")
        }
    }
}
```

**Step 2: Update ContentView tab**

Replace `CardLibraryView()` with `CharacterLibraryView()`, change label to "字库", icon to "character.book.closed".

**Step 3: Run tests**

Fix UI tests that reference "卡片库" tab — update to "字库".

**Step 4: Commit**

```bash
git add AnkiAnna/AnkiAnna/Views/CharacterLibrary/
git commit -am "feat: add CharacterLibraryView replacing CardLibrary tab"
```

---

### Task 8: CharacterDetailView + CharacterRow

**Files:**
- Create: `AnkiAnna/AnkiAnna/Views/CharacterLibrary/CharacterDetailView.swift`
- Create: `AnkiAnna/AnkiAnna/Views/CharacterLibrary/CharacterRow.swift`

**Step 1: Implementation**

`CharacterRow` — compact row showing: character, mastery icon (⬜/🔄/✅), practice count, accuracy %, ⚠️ if difficult.

`CharacterDetailView` — full page:
- Large character display
- Grade/lesson/words info
- Practice stats (count, accuracy, last practiced)
- SM-2 info (interval, next review date)
- "标记为未掌握" button → calls `stats.resetMastery()`
- "立即练习" button → navigate to learning with this character

**Step 2: Run build**

**Step 3: Commit**

```bash
git add AnkiAnna/AnkiAnna/Views/CharacterLibrary/
git commit -am "feat: add CharacterDetailView and CharacterRow components"
```

---

### Task 9: Character Library UI Tests

**Files:**
- Create: `AnkiAnna/AnkiAnnaUITests/CharacterLibraryTests.swift`
- Modify: `AnkiAnna/AnkiAnna/Testing/UITestSeeder.swift` — add seed for CharacterStats

**Step 1: Write UI tests**

```swift
final class CharacterLibraryTests: XCTestCase {
    func testCharacterLibraryShowsCharacters() {
        let app = LaunchHelper.launchApp(seedData: true)
        LaunchHelper.tapTab("字库", in: app)
        // Verify characters are displayed
    }

    func testSearchFiltersCharacters() {
        // Type in search bar, verify filtering
    }

    func testNavigateToCharacterDetail() {
        // Tap a character, verify detail view
    }

    func testResetMasteryButton() {
        // In detail view, tap "标记为未掌握"
    }
}
```

**Step 2: Run UI tests**

**Step 3: Commit**

```bash
git add AnkiAnna/AnkiAnnaUITests/CharacterLibraryTests.swift
git commit -am "test: add CharacterLibrary UI tests"
```

---

## Phase 3: Game Modes

### Task 10: Game Mode Selection View

**Files:**
- Create: `AnkiAnna/AnkiAnna/Views/Learning/GameModeSelectionView.swift`
- Modify: `AnkiAnna/AnkiAnna/ContentView.swift` — learning tab shows GameModeSelectionView

**Step 1: Implementation**

```swift
// GameModeSelectionView.swift
import SwiftUI

enum GameMode: String, CaseIterable {
    case quickLearn = "快速学习"
    case timeAttack = "限时挑战"
    case survival = "生存模式"
    case levels = "闯关模式"
    case match = "连连看"

    var icon: String {
        switch self {
        case .quickLearn: return "star.fill"
        case .timeAttack: return "timer"
        case .survival: return "heart.fill"
        case .levels: return "building.columns"
        case .match: return "link"
        }
    }

    var description: String {
        switch self {
        case .quickLearn: return "每日任务，SM-2 智能选卡"
        case .timeAttack: return "限时内尽可能多答对"
        case .survival: return "3条命，看能走多远"
        case .levels: return "按课文逐关解锁"
        case .match: return "字-词配对挑战"
        }
    }
}

struct GameModeSelectionView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(GameMode.allCases, id: \.self) { mode in
                        NavigationLink(destination: destinationView(for: mode)) {
                            GameModeCard(mode: mode)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("学习")
        }
    }

    @ViewBuilder
    func destinationView(for mode: GameMode) -> some View {
        switch mode {
        case .quickLearn: LearningView()
        case .timeAttack: TimeAttackView()
        case .survival: SurvivalView()
        case .levels: LevelsView()
        case .match: MatchView()
        }
    }
}
```

**Step 2: Update ContentView**

Replace `LearningView()` with `GameModeSelectionView()` in tab 1.

**Step 3: Commit**

```bash
git add AnkiAnna/AnkiAnna/Views/Learning/GameModeSelectionView.swift
git commit -am "feat: add GameModeSelectionView as learning tab entry point"
```

---

### Task 11: Quick Learn Mode (Refactored LearningView)

**Files:**
- Modify: `AnkiAnna/AnkiAnna/Views/Learning/LearningView.swift` — add settings for daily goal mode
- Modify: `AnkiAnna/AnkiAnna/Views/Learning/LearningViewModel.swift` — already fixed in Task 4
- Create: `AnkiAnna/AnkiAnna/Views/Learning/QuickLearnSettingsView.swift`

**Step 1: Add daily goal settings**

In `UserProfile`, add fields (or use @AppStorage):
```swift
var dailyGoalMode: String  // "practice" or "mastery"
var dailyGoalCount: Int    // 10/15/20/30
```

`QuickLearnSettingsView`:
```swift
struct QuickLearnSettingsView: View {
    @Bindable var profile: UserProfile

    var body: some View {
        Form {
            Picker("目标类型", selection: $profile.dailyGoalMode) {
                Text("练习数").tag("practice")
                Text("掌握数").tag("mastery")
            }
            Picker("每日目标", selection: $profile.dailyGoalCount) {
                Text("10").tag(10)
                Text("15").tag(15)
                Text("20").tag(20)
                Text("30").tag(30)
            }
        }
        .navigationTitle("快速学习设置")
    }
}
```

**Step 2: Modify LearningView to show progress bar and daily summary**

Add progress bar: `ProgressView(value: Double(completedCount), total: Double(totalCount))`

Add session complete summary:
- 今日练习: X
- 正确率: Y%
- 新掌握: Z
- 获得积分: W

**Step 3: Commit**

```bash
git commit -am "feat: add quick learn settings and daily summary"
```

---

### Task 12: Time Attack Mode

**Files:**
- Create: `AnkiAnna/AnkiAnna/Views/Learning/TimeAttack/TimeAttackView.swift`
- Create: `AnkiAnna/AnkiAnna/Views/Learning/TimeAttack/TimeAttackViewModel.swift`
- Test: `AnkiAnna/AnkiAnnaTests/TimeAttackViewModelTests.swift`

**Step 1: Write failing tests**

```swift
// TimeAttackViewModelTests.swift
final class TimeAttackViewModelTests: XCTestCase {
    func testInitialTimeIsSelected() {
        let vm = TimeAttackViewModel(duration: 60)
        XCTAssertEqual(vm.remainingTime, 60)
        XCTAssertFalse(vm.isRunning)
    }

    func testCorrectAnswerAddsTime() {
        let vm = TimeAttackViewModel(duration: 60)
        vm.remainingTime = 30
        vm.handleCorrectAnswer()
        XCTAssertEqual(vm.remainingTime, 33) // +3 seconds
        XCTAssertEqual(vm.score, 10) // base score
    }

    func testComboMultipliesScore() {
        let vm = TimeAttackViewModel(duration: 60)
        vm.combo = 5
        vm.handleCorrectAnswer()
        // score = (10 + min(combo, 10)) with combo multiplier
    }

    func testGameEndsWhenTimeExpires() {
        let vm = TimeAttackViewModel(duration: 60)
        vm.remainingTime = 0
        vm.tick()
        XCTAssertTrue(vm.isGameOver)
    }
}
```

**Step 2: Run to verify failure**

**Step 3: Implementation**

```swift
// TimeAttackViewModel.swift
import Foundation
import SwiftData

@Observable
class TimeAttackViewModel {
    var remainingTime: Int
    var isRunning = false
    var isGameOver = false
    var score: Int = 0
    var answeredCount: Int = 0
    var correctCount: Int = 0
    var combo: Int = 0
    var bestCombo: Int = 0
    var currentCard: Card?
    var currentContext: CardContext?
    var showResult = false
    var isCorrect = false

    private var cards: [Card] = []
    private var currentIndex = 0
    private let bonusTime = 3 // seconds added per correct

    init(duration: Int) {
        self.remainingTime = duration
    }

    func start(cards: [Card]) {
        self.cards = cards.shuffled()
        currentIndex = 0
        isRunning = true
        advanceToNext()
    }

    func tick() {
        if remainingTime > 0 {
            remainingTime -= 1
        }
        if remainingTime <= 0 {
            isRunning = false
            isGameOver = true
        }
    }

    func handleCorrectAnswer() {
        combo += 1
        bestCombo = max(bestCombo, combo)
        correctCount += 1
        answeredCount += 1
        score += PointsService.pointsForAnswer(correct: true, combo: combo)
        remainingTime += bonusTime
        isCorrect = true
        showResult = true
    }

    func handleWrongAnswer() {
        combo = 0
        answeredCount += 1
        isCorrect = false
        showResult = true
    }

    func next() {
        showResult = false
        currentIndex += 1
        if currentIndex >= cards.count {
            currentIndex = 0 // loop cards in time attack
            cards.shuffle()
        }
        advanceToNext()
    }

    private func advanceToNext() {
        guard currentIndex < cards.count else { return }
        currentCard = cards[currentIndex]
        currentContext = currentCard?.contexts.randomElement()
    }
}
```

```swift
// TimeAttackView.swift
import SwiftUI
import SwiftData

struct TimeAttackView: View {
    @Query var cards: [Card]
    @State private var viewModel: TimeAttackViewModel?
    @State private var selectedDuration: Int? = nil
    @State private var timer: Timer?

    var body: some View {
        if let vm = viewModel, vm.isRunning || vm.isGameOver {
            if vm.isGameOver {
                gameOverView(vm)
            } else {
                gameplayView(vm)
            }
        } else {
            durationPicker
        }
    }

    var durationPicker: some View {
        VStack(spacing: 20) {
            Text("选择时长").font(.title)
            ForEach([60, 90, 120], id: \.self) { seconds in
                Button("\(seconds) 秒") {
                    let vm = TimeAttackViewModel(duration: seconds)
                    vm.start(cards: cards)
                    viewModel = vm
                    startTimer()
                }
                .buttonStyle(.borderedProminent)
                .font(.title2)
            }
        }
    }

    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            viewModel?.tick()
            if viewModel?.isGameOver == true { timer?.invalidate() }
        }
    }
}
```

**Step 4: Run tests**

**Step 5: Commit**

```bash
git add AnkiAnna/AnkiAnna/Views/Learning/TimeAttack/
git add AnkiAnna/AnkiAnnaTests/TimeAttackViewModelTests.swift
git commit -m "feat: add Time Attack game mode with timer and combo scoring"
```

---

### Task 13: Survival Mode

**Files:**
- Create: `AnkiAnna/AnkiAnna/Views/Learning/Survival/SurvivalView.swift`
- Create: `AnkiAnna/AnkiAnna/Views/Learning/Survival/SurvivalViewModel.swift`
- Test: `AnkiAnna/AnkiAnnaTests/SurvivalViewModelTests.swift`

**Step 1: Write failing tests**

```swift
final class SurvivalViewModelTests: XCTestCase {
    func testStartsWith3Lives() {
        let vm = SurvivalViewModel()
        XCTAssertEqual(vm.lives, 3)
    }

    func testWrongAnswerLosesLife() {
        let vm = SurvivalViewModel()
        vm.handleWrongAnswer()
        XCTAssertEqual(vm.lives, 2)
    }

    func testGameOverAtZeroLives() {
        let vm = SurvivalViewModel()
        vm.handleWrongAnswer()
        vm.handleWrongAnswer()
        vm.handleWrongAnswer()
        XCTAssertTrue(vm.isGameOver)
    }

    func testConsecutive5CorrectRestoresLife() {
        let vm = SurvivalViewModel()
        vm.lives = 2
        for _ in 0..<5 { vm.handleCorrectAnswer() }
        XCTAssertEqual(vm.lives, 3)
    }

    func testLifeCapAt3() {
        let vm = SurvivalViewModel()
        for _ in 0..<10 { vm.handleCorrectAnswer() }
        XCTAssertEqual(vm.lives, 3)
    }

    func testDifficultyScalesWithSurvived() {
        let vm = SurvivalViewModel()
        XCTAssertEqual(vm.currentMaxGrade, 2) // starts at grade 1-2
        vm.survivedCount = 10
        XCTAssertEqual(vm.currentMaxGrade, 3) // scales up
        vm.survivedCount = 20
        XCTAssertEqual(vm.currentMaxGrade, 4)
    }
}
```

**Step 2: Implementation**

```swift
// SurvivalViewModel.swift
@Observable
class SurvivalViewModel {
    var lives: Int = 3
    var survivedCount: Int = 0
    var combo: Int = 0
    var isGameOver: Bool = false
    var currentCard: Card?
    var currentContext: CardContext?
    var showResult = false
    var isCorrect = false
    var bestRecord: Int = 0

    private var cards: [Card] = []
    private var characterStats: [CharacterStats] = []
    private var currentIndex = 0
    private var consecutiveCorrect = 0

    var currentMaxGrade: Int {
        min(5, 2 + survivedCount / 10)
    }

    func start(cards: [Card], stats: [CharacterStats]) {
        self.characterStats = stats
        // Filter by current difficulty
        self.cards = cards.shuffled()
        currentIndex = 0
        advanceToNext()
    }

    func handleCorrectAnswer() {
        combo += 1
        survivedCount += 1
        consecutiveCorrect += 1
        isCorrect = true
        showResult = true
        if consecutiveCorrect >= 5 && lives < 3 {
            lives += 1
            consecutiveCorrect = 0
        }
    }

    func handleWrongAnswer() {
        combo = 0
        consecutiveCorrect = 0
        lives -= 1
        isCorrect = false
        showResult = true
        if lives <= 0 {
            isGameOver = true
            bestRecord = max(bestRecord, survivedCount)
        }
    }

    func next() {
        showResult = false
        currentIndex += 1
        if currentIndex >= cards.count {
            currentIndex = 0
            cards.shuffle()
        }
        advanceToNext()
    }

    private func advanceToNext() {
        guard currentIndex < cards.count else { return }
        // Filter cards by current difficulty grade
        let gradeCards = cards.filter { card in
            if let stats = characterStats.first(where: { $0.character == card.answer }) {
                return stats.grade <= currentMaxGrade
            }
            return true
        }
        currentCard = gradeCards.isEmpty ? cards[currentIndex] : gradeCards.randomElement()
        currentContext = currentCard?.contexts.randomElement()
    }
}
```

**Step 3: Run tests**

**Step 4: Commit**

```bash
git add AnkiAnna/AnkiAnna/Views/Learning/Survival/
git add AnkiAnna/AnkiAnnaTests/SurvivalViewModelTests.swift
git commit -m "feat: add Survival game mode with lives system and difficulty scaling"
```

---

### Task 14: Levels Mode (闯关)

**Files:**
- Create: `AnkiAnna/AnkiAnna/Views/Learning/Levels/LevelsView.swift`
- Create: `AnkiAnna/AnkiAnna/Views/Learning/Levels/LevelsViewModel.swift`
- Create: `AnkiAnna/AnkiAnna/Models/LevelProgress.swift` — SwiftData model for level unlock/stars
- Test: `AnkiAnna/AnkiAnnaTests/LevelsViewModelTests.swift`

**Step 1: Write failing tests**

```swift
final class LevelsViewModelTests: XCTestCase {
    func testFirstLevelUnlocked() {
        let vm = LevelsViewModel()
        XCTAssertTrue(vm.isLevelUnlocked(grade: 1, semester: "upper", lesson: 1))
    }

    func testSecondLevelLockedByDefault() {
        let vm = LevelsViewModel()
        XCTAssertFalse(vm.isLevelUnlocked(grade: 1, semester: "upper", lesson: 2))
    }

    func testStarRating() {
        XCTAssertEqual(LevelsViewModel.starRating(errors: 0), 3)
        XCTAssertEqual(LevelsViewModel.starRating(errors: 1), 2)
        XCTAssertEqual(LevelsViewModel.starRating(errors: 2), 1)
        XCTAssertEqual(LevelsViewModel.starRating(errors: 5), 1)
    }

    func testCompletingLevelUnlocksNext() {
        // After completing level with 0 errors, next level should unlock
    }
}
```

**Step 2: Implementation**

```swift
// LevelProgress.swift
@Model final class LevelProgress {
    var id: UUID
    var grade: Int
    var semester: String
    var lesson: Int
    var isUnlocked: Bool
    var stars: Int          // 0-3
    var bestErrors: Int?    // best attempt error count

    init(grade: Int, semester: String, lesson: Int, isUnlocked: Bool = false) {
        self.id = UUID()
        self.grade = grade
        self.semester = semester
        self.lesson = lesson
        self.isUnlocked = isUnlocked
        self.stars = 0
        self.bestErrors = nil
    }
}
```

Add `LevelProgress.self` to `ModelContainer` schema.

`LevelsView` — shows a scrollable grid of levels grouped by grade/semester, each showing stars and lock status. Tapping unlocked level starts the level challenge (5-8 chars from that lesson).

**Step 3: Run tests**

**Step 4: Commit**

```bash
git add AnkiAnna/AnkiAnna/Views/Learning/Levels/ AnkiAnna/AnkiAnna/Models/LevelProgress.swift
git add AnkiAnna/AnkiAnnaTests/LevelsViewModelTests.swift
git commit -m "feat: add Levels game mode with star rating and progressive unlock"
```

---

### Task 15: Match Mode (连连看)

**Files:**
- Create: `AnkiAnna/AnkiAnna/Views/Learning/Match/MatchView.swift`
- Create: `AnkiAnna/AnkiAnna/Views/Learning/Match/MatchViewModel.swift`
- Test: `AnkiAnna/AnkiAnnaTests/MatchViewModelTests.swift`

**Step 1: Write failing tests**

```swift
final class MatchViewModelTests: XCTestCase {
    func testGridSizeIs4x3() {
        let vm = MatchViewModel(pairs: 6)
        XCTAssertEqual(vm.tiles.count, 12) // 6 chars + 6 words
    }

    func testCorrectMatchRemovesPair() {
        let vm = MatchViewModel(pairs: 6)
        // Select a character tile, then its matching word tile
        // Both should be marked as matched
    }

    func testWrongMatchDoesNotRemove() {
        // Select a character, then wrong word
        // Both should be deselected after brief delay
    }

    func testGameCompleteWhenAllMatched() {
        // All pairs matched → isComplete = true
    }
}
```

**Step 2: Implementation**

```swift
// MatchViewModel.swift
@Observable
class MatchViewModel {
    struct Tile: Identifiable {
        let id = UUID()
        let text: String
        let pairId: UUID // shared between char and word
        let isCharacter: Bool
        var isMatched = false
        var isSelected = false
    }

    var tiles: [Tile] = []
    var selectedTile: Tile? = nil
    var isComplete = false
    var elapsedTime: Int = 0
    var matchedPairs: Int = 0
    var totalPairs: Int

    init(pairs: Int) {
        totalPairs = pairs
    }

    func setup(characters: [(char: String, word: String)]) {
        tiles = []
        for pair in characters.prefix(totalPairs) {
            let pairId = UUID()
            tiles.append(Tile(text: pair.char, pairId: pairId, isCharacter: true))
            tiles.append(Tile(text: pair.word, pairId: pairId, isCharacter: false))
        }
        tiles.shuffle()
    }

    func selectTile(_ tile: Tile) {
        guard !tile.isMatched else { return }

        if let selected = selectedTile {
            // Second selection
            if selected.pairId == tile.pairId && selected.isCharacter != tile.isCharacter {
                // Correct match
                markMatched(pairId: tile.pairId)
                matchedPairs += 1
                if matchedPairs >= totalPairs { isComplete = true }
            }
            // Reset selection
            selectedTile = nil
            resetSelections()
        } else {
            // First selection
            selectedTile = tile
            if let idx = tiles.firstIndex(where: { $0.id == tile.id }) {
                tiles[idx].isSelected = true
            }
        }
    }

    private func markMatched(pairId: UUID) {
        for i in tiles.indices where tiles[i].pairId == pairId {
            tiles[i].isMatched = true
        }
    }

    private func resetSelections() {
        for i in tiles.indices { tiles[i].isSelected = false }
    }
}
```

`MatchView` — LazyVGrid with columns, each tile as a rounded rect button. Matched tiles fade out. Timer counts up. Completion screen shows time.

**Step 3: Run tests**

**Step 4: Commit**

```bash
git add AnkiAnna/AnkiAnna/Views/Learning/Match/
git add AnkiAnna/AnkiAnnaTests/MatchViewModelTests.swift
git commit -m "feat: add Match game mode with character-word pairing"
```

---

### Task 16: Game Modes UI Tests

**Files:**
- Create: `AnkiAnna/AnkiAnnaUITests/GameModeTests.swift`
- Modify: `AnkiAnna/AnkiAnnaUITests/Helpers/LaunchHelper.swift` — add seed for CharacterStats
- Modify: existing LearningFlow/SessionComplete UI tests — adapt to new mode selection flow

**Step 1: Write UI tests**

```swift
final class GameModeTests: XCTestCase {
    func testGameModeSelectionShowsAllModes() {
        let app = LaunchHelper.launchApp(seedData: true)
        LaunchHelper.tapTab("学习", in: app)
        XCTAssertTrue(app.staticTexts["快速学习"].exists)
        XCTAssertTrue(app.staticTexts["限时挑战"].exists)
        XCTAssertTrue(app.staticTexts["生存模式"].exists)
        XCTAssertTrue(app.staticTexts["闯关模式"].exists)
        XCTAssertTrue(app.staticTexts["连连看"].exists)
    }

    func testQuickLearnModeStartsLearning() {
        let app = LaunchHelper.launchApp(seedData: true)
        LaunchHelper.tapTab("学习", in: app)
        app.staticTexts["快速学习"].tap()
        // Should show learning interface
    }

    func testTimeAttackShowsDurationPicker() {
        let app = LaunchHelper.launchApp(seedData: true)
        LaunchHelper.tapTab("学习", in: app)
        app.staticTexts["限时挑战"].tap()
        XCTAssertTrue(app.buttons["60 秒"].exists)
    }
}
```

**Step 2: Update existing UI tests**

`LearningFlowTests` and `SessionCompleteTests` need to navigate through mode selection first (tap "快速学习" before testing the learning flow).

**Step 3: Run all UI tests**

**Step 4: Commit**

```bash
git add AnkiAnna/AnkiAnnaUITests/GameModeTests.swift
git commit -am "test: add game mode UI tests, update existing tests for mode selection"
```

---

## Phase 4: Reports System

### Task 17: Enhanced StatsView — Today Overview + Mastery Progress

**Files:**
- Modify: `AnkiAnna/AnkiAnna/Views/Stats/StatsView.swift` — restructure with new sections
- Create: `AnkiAnna/AnkiAnna/Views/Stats/MasteryProgressView.swift`
- Create: `AnkiAnna/AnkiAnna/Views/Stats/TodayOverviewView.swift`

**Step 1: Implementation**

```swift
// TodayOverviewView.swift
struct TodayOverviewView: View {
    let session: DailySession?
    let streak: Int

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 20) {
                StatBox(title: "今日练习", value: "\(session?.completedCount ?? 0)/\(session?.targetCount ?? 0)", icon: "pencil.line")
                StatBox(title: "正确率", value: session.map { "\(Int(Double($0.correctCount) / max(1, Double($0.completedCount)) * 100))%" } ?? "0%", icon: "checkmark.circle")
                StatBox(title: "新掌握", value: "\(session?.newMastered ?? 0)", icon: "star.fill")
                StatBox(title: "连续打卡", value: "\(streak)天 🔥", icon: "flame.fill")
            }
        }
    }
}

// MasteryProgressView.swift
struct MasteryProgressView: View {
    let stats: [CharacterStats]

    var masteredCount: Int { stats.filter { $0.masteryLevel == .mastered }.count }
    var learningCount: Int { stats.filter { $0.masteryLevel == .learning }.count }
    var newCount: Int { stats.filter { $0.masteryLevel == .new }.count }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Ring chart: mastered/learning/new proportions
            HStack {
                // Simplified progress ring or ProgressView
                CircularProgressView(mastered: masteredCount, learning: learningCount, total: stats.count)
                VStack(alignment: .leading) {
                    Text("已掌握 \(masteredCount)").foregroundColor(.green)
                    Text("学习中 \(learningCount)").foregroundColor(.orange)
                    Text("未学习 \(newCount)").foregroundColor(.gray)
                }
            }
            // Per-grade progress bars
            ForEach(1...5, id: \.self) { grade in
                let gradeStats = stats.filter { $0.grade == grade }
                let mastered = gradeStats.filter { $0.masteryLevel == .mastered }.count
                HStack {
                    Text("\(grade)年级")
                        .frame(width: 50, alignment: .leading)
                    ProgressView(value: Double(mastered), total: Double(max(1, gradeStats.count)))
                    Text("\(mastered)/\(gradeStats.count)")
                        .font(.caption)
                }
            }
        }
    }
}
```

**Step 2: Restructure StatsView**

Reorganize StatsView sections in this order:
1. TodayOverviewView
2. MasteryProgressView
3. DifficultCharactersView (Task 18)
4. TrendChartView (Task 19)
5. Level & Badges (existing)
6. StreakCalendarView (existing, now functional)

**Step 3: Commit**

```bash
git add AnkiAnna/AnkiAnna/Views/Stats/
git commit -am "feat: add today overview and mastery progress to StatsView"
```

---

### Task 18: Difficult Characters Ranking

**Files:**
- Create: `AnkiAnna/AnkiAnna/Views/Stats/DifficultCharactersView.swift`

**Step 1: Implementation**

```swift
struct DifficultCharactersView: View {
    let stats: [CharacterStats]

    var difficultChars: [CharacterStats] {
        stats.filter { $0.isDifficult }
            .sorted { $0.errorRate > $1.errorRate }
            .prefix(10)
            .map { $0 }
    }

    var body: some View {
        if difficultChars.isEmpty {
            Text("暂无易错字").foregroundColor(.secondary)
        } else {
            ForEach(difficultChars) { stats in
                HStack {
                    Text(stats.character).font(.title2)
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("练习 \(stats.practiceCount) 次")
                            .font(.caption)
                        Text("错误率 \(Int(stats.errorRate * 100))%")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
        }
    }
}
```

**Step 2: Add to StatsView**

**Step 3: Commit**

```bash
git add AnkiAnna/AnkiAnna/Views/Stats/DifficultCharactersView.swift
git commit -am "feat: add difficult characters ranking to reports"
```

---

### Task 19: Learning Trends Chart

**Files:**
- Create: `AnkiAnna/AnkiAnna/Views/Stats/TrendChartView.swift`

**Step 1: Implementation**

Use SwiftUI Charts framework:

```swift
import Charts

struct TrendChartView: View {
    let sessions: [DailySession]
    @State private var period: TrendPeriod = .week

    enum TrendPeriod: String, CaseIterable {
        case week = "7天"
        case month = "30天"

        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            }
        }
    }

    var filteredSessions: [DailySession] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -period.days, to: Date())!
        return sessions.filter { $0.date >= cutoff }.sorted { $0.date < $1.date }
    }

    var body: some View {
        VStack(alignment: .leading) {
            Picker("时间范围", selection: $period) {
                ForEach(TrendPeriod.allCases, id: \.self) { Text($0.rawValue) }
            }
            .pickerStyle(.segmented)

            // Practice count bar chart
            Chart(filteredSessions) { session in
                BarMark(
                    x: .value("日期", session.date, unit: .day),
                    y: .value("练习数", session.completedCount)
                )
                .foregroundStyle(.blue)
            }
            .frame(height: 150)
            .chartXAxis { AxisMarks(values: .stride(by: .day)) { _ in AxisValueLabel(format: .dateTime.day()) } }

            // Accuracy line chart
            Chart(filteredSessions) { session in
                LineMark(
                    x: .value("日期", session.date, unit: .day),
                    y: .value("正确率", session.completedCount > 0 ? Double(session.correctCount) / Double(session.completedCount) * 100 : 0)
                )
                .foregroundStyle(.green)
            }
            .frame(height: 150)
        }
    }
}
```

**Step 2: Add to StatsView**

**Step 3: Commit**

```bash
git add AnkiAnna/AnkiAnna/Views/Stats/TrendChartView.swift
git commit -am "feat: add learning trends charts (practice count + accuracy)"
```

---

### Task 20: Stats & Reports UI Tests

**Files:**
- Modify: `AnkiAnna/AnkiAnnaUITests/StatsViewTests.swift` — add tests for new sections

**Step 1: Add UI tests**

```swift
func testTodayOverviewExists() {
    let app = LaunchHelper.launchApp(seedData: true)
    LaunchHelper.tapTab("统计", in: app)
    XCTAssertTrue(app.staticTexts["今日练习"].exists)
    XCTAssertTrue(app.staticTexts["正确率"].exists)
}

func testMasteryProgressExists() {
    let app = LaunchHelper.launchApp(seedData: true)
    LaunchHelper.tapTab("统计", in: app)
    XCTAssertTrue(app.staticTexts["已掌握"].exists || app.staticTexts["1年级"].exists)
}

func testDifficultCharsSection() {
    // Verify difficult chars section exists
}
```

**Step 2: Run all tests**

**Step 3: Commit**

```bash
git commit -am "test: add UI tests for enhanced stats and reports"
```

---

## Phase 5: Integration & Polish

### Task 21: Settings View

**Files:**
- Create: `AnkiAnna/AnkiAnna/Views/Settings/SettingsView.swift`
- Modify: `AnkiAnna/AnkiAnna/Views/Stats/StatsView.swift` — add settings gear icon

**Step 1: Implementation**

```swift
struct SettingsView: View {
    @Query var profiles: [UserProfile]
    var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            Form {
                Section("快速学习") {
                    // Daily goal mode picker
                    // Daily goal count picker
                }
                Section("AI 生成") {
                    // API endpoint, key, model (existing from AIGenerateView)
                }
                Section("关于") {
                    Text("AnkiAnna v2.0")
                }
            }
            .navigationTitle("设置")
        }
    }
}
```

Add `.toolbar { NavigationLink(destination: SettingsView()) { Image(systemName: "gear") } }` to StatsView.

**Step 2: Commit**

```bash
git add AnkiAnna/AnkiAnna/Views/Settings/
git commit -am "feat: add SettingsView with quick learn and AI configuration"
```

---

### Task 22: Run Full Test Suite + Fix Breakages

**Files:**
- All test files

**Step 1: Run full unit test suite**

```bash
cd AnkiAnna && xcodebuild test -workspace AnkiAnna.xcworkspace -scheme AnkiAnna \
  -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' \
  -only-testing:AnkiAnnaTests 2>&1 | tail -40
```

**Step 2: Fix any failures**

Common fixes needed:
- Card/ReviewRecord init calls may need new parameters
- UI tests referencing "卡片库" → "字库"
- LearningFlow tests need to navigate through mode selection
- ModelContainer schema needs all new models

**Step 3: Run full UI test suite**

```bash
cd AnkiAnna && xcodebuild test -workspace AnkiAnna.xcworkspace -scheme AnkiAnna \
  -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' \
  -only-testing:AnkiAnnaUITests 2>&1 | tail -40
```

**Step 4: Fix any failures**

**Step 5: Commit**

```bash
git commit -am "fix: resolve all test breakages from V2 refactoring"
```

---

### Task 23: Update CLAUDE.md + Project Docs

**Files:**
- Modify: `CLAUDE.md` — update code structure, models, tab structure
- Modify: `PROJECT.md` — add V2 tasks to task outline

**Step 1: Update CLAUDE.md**

Add new models (CharacterStats, LevelProgress), new views (CharacterLibrary, GameModes, Settings), updated tab structure.

**Step 2: Update PROJECT.md**

Add tasks 6-10 for V2 features.

**Step 3: Commit**

```bash
git commit -am "docs: update CLAUDE.md and PROJECT.md for V2 features"
```

---

## Summary

| Phase | Tasks | Key Deliverables |
|-------|-------|-----------------|
| 1. Foundation | 1-6 | CharacterStats model, SM-2 fix, DailySession fix, Badge wiring, textbook seeding |
| 2. Character Library | 7-9 | CharacterLibraryView, detail view, search/filter, UI tests |
| 3. Game Modes | 10-16 | Mode selector, Quick Learn, Time Attack, Survival, Levels, Match, UI tests |
| 4. Reports | 17-20 | Today overview, mastery progress, difficult chars, trend charts, UI tests |
| 5. Integration | 21-23 | Settings, full test pass, docs update |

**Total: 23 tasks**
