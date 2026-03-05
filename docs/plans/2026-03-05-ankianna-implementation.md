# AnkiAnna Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a SwiftUI iPad app for Anna (8yo) to practice Chinese character writing and English spelling via dictation with spaced repetition.

**Architecture:** SwiftUI + SwiftData for local persistence. PencilKit for Apple Pencil input, Vision framework for handwriting recognition, AVSpeechSynthesizer for TTS. LLM API for card generation. SM-2 algorithm for review scheduling.

**Tech Stack:** Swift, SwiftUI, SwiftData, PencilKit, Vision, AVFoundation, XCTest

**Design doc:** `docs/plans/2026-03-05-ankianna-design.md`

---

## Task 1: Create Xcode Project Skeleton

**Files:**
- Create: `AnkiAnna/AnkiAnnaApp.swift`
- Create: `AnkiAnna/ContentView.swift`
- Create: `AnkiAnna.xcodeproj` (via xcodebuild or Xcode template)

**Step 1: Create the Xcode project**

Use Swift Package Manager with Xcode project generation. From `~/Projects/ankianna/`:

```bash
mkdir -p AnkiAnna/AnkiAnna
```

Create `AnkiAnna/AnkiAnna/AnkiAnnaApp.swift`:
```swift
import SwiftUI
import SwiftData

@main
struct AnkiAnnaApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Card.self, ReviewRecord.self, DailySession.self, UserProfile.self])
    }
}
```

Create `AnkiAnna/AnkiAnna/ContentView.swift`:
```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Text("学习")
                .tabItem {
                    Label("学习", systemImage: "pencil.line")
                }
            Text("卡片库")
                .tabItem {
                    Label("卡片库", systemImage: "rectangle.stack")
                }
            Text("添加")
                .tabItem {
                    Label("添加", systemImage: "plus.circle")
                }
            Text("统计")
                .tabItem {
                    Label("统计", systemImage: "chart.bar")
                }
        }
    }
}
```

**Step 2: Create the Xcode project file**

```bash
# Generate Xcode project using swift package init, or manually create .xcodeproj
# Preferred: Create project from Xcode command line tools
cd ~/Projects/ankianna/AnkiAnna
# If Xcode is available, create project interactively or use tuist/XcodeGen
```

Note: Xcode project creation is best done via `xcodegen` or manual Xcode. Install XcodeGen if not available:
```bash
brew install xcodegen
```

Create `AnkiAnna/project.yml` for XcodeGen:
```yaml
name: AnkiAnna
options:
  bundleIdPrefix: com.ming.ankianna
  deploymentTarget:
    iOS: "17.0"
  xcodeVersion: "16.0"
settings:
  base:
    TARGETED_DEVICE_FAMILY: "2"  # iPad only
    SUPPORTS_XR_DESIGNED_FOR: "NO"
targets:
  AnkiAnna:
    type: application
    platform: iOS
    sources:
      - AnkiAnna
    settings:
      base:
        INFOPLIST_KEY_UILaunchScreen_Generation: true
        INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad: "UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight"
  AnkiAnnaTests:
    type: bundle.unit-test
    platform: iOS
    sources:
      - AnkiAnnaTests
    dependencies:
      - target: AnkiAnna
```

```bash
cd ~/Projects/ankianna/AnkiAnna && xcodegen generate
```

**Step 3: Verify build**

```bash
cd ~/Projects/ankianna/AnkiAnna
xcodebuild -project AnkiAnna.xcodeproj -scheme AnkiAnna -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

**Step 4: Commit**

```bash
cd ~/Projects/ankianna
git add AnkiAnna/
git commit -m "feat: 创建 Xcode 项目骨架（iPad, iOS 17+, SwiftData）"
```

---

## Task 2: SwiftData Models

**Files:**
- Create: `AnkiAnna/AnkiAnna/Models/Card.swift`
- Create: `AnkiAnna/AnkiAnna/Models/CardContext.swift`
- Create: `AnkiAnna/AnkiAnna/Models/ReviewRecord.swift`
- Create: `AnkiAnna/AnkiAnna/Models/DailySession.swift`
- Create: `AnkiAnna/AnkiAnna/Models/UserProfile.swift`
- Create: `AnkiAnna/AnkiAnnaTests/ModelTests.swift`

**Step 1: Write model test**

Create `AnkiAnna/AnkiAnnaTests/ModelTests.swift`:
```swift
import XCTest
import SwiftData
@testable import AnkiAnna

final class ModelTests: XCTestCase {

    var container: ModelContainer!

    override func setUp() {
        super.setUp()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try! ModelContainer(
            for: Card.self, ReviewRecord.self, DailySession.self, UserProfile.self,
            configurations: config
        )
    }

    func testCreateChineseCard() throws {
        let context = container.mainContext
        let card = Card(
            type: .chineseWriting,
            answer: "龙",
            audioText: "龙"
        )
        let ctx1 = CardContext(type: .phrase, text: "___飞凤舞", fullText: "龙飞凤舞")
        let ctx2 = CardContext(type: .phrase, text: "恐___", fullText: "恐龙")
        card.contexts = [ctx1, ctx2]
        card.tags = ["二年级", "动物"]

        context.insert(card)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Card>())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched[0].answer, "龙")
        XCTAssertEqual(fetched[0].type, .chineseWriting)
        XCTAssertEqual(fetched[0].contexts.count, 2)
    }

    func testCreateEnglishCard() throws {
        let context = container.mainContext
        let card = Card(
            type: .englishSpelling,
            answer: "dragon",
            audioText: "dragon"
        )
        let ctx = CardContext(type: .sentence, text: "The ___ flies in the sky.", fullText: "The dragon flies in the sky.")
        card.contexts = [ctx]

        context.insert(card)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Card>())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched[0].answer, "dragon")
        XCTAssertEqual(fetched[0].type, .englishSpelling)
    }

    func testReviewRecord() throws {
        let context = container.mainContext
        let card = Card(type: .chineseWriting, answer: "龙", audioText: "龙")
        context.insert(card)

        let record = ReviewRecord(
            card: card,
            result: .correct,
            ease: 2.5,
            interval: 1,
            nextReviewDate: Date().addingTimeInterval(86400)
        )
        context.insert(record)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<ReviewRecord>())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched[0].result, .correct)
    }

    func testDailySession() throws {
        let context = container.mainContext
        let session = DailySession(date: Date(), targetCount: 15)
        context.insert(session)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<DailySession>())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched[0].targetCount, 15)
        XCTAssertEqual(fetched[0].completedCount, 0)
    }

    func testUserProfile() throws {
        let context = container.mainContext
        let profile = UserProfile(name: "Anna", dailyGoal: 15)
        context.insert(profile)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<UserProfile>())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched[0].name, "Anna")
        XCTAssertEqual(fetched[0].totalPoints, 0)
    }
}
```

**Step 2: Run test to verify it fails**

```bash
cd ~/Projects/ankianna/AnkiAnna
xcodebuild test -project AnkiAnna.xcodeproj -scheme AnkiAnnaTests -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' 2>&1 | tail -10
```

Expected: FAIL — `Card`, `CardContext`, etc. not defined.

**Step 3: Implement models**

Create `AnkiAnna/AnkiAnna/Models/Card.swift`:
```swift
import Foundation
import SwiftData

enum CardType: String, Codable {
    case chineseWriting
    case englishSpelling
}

enum CardSource: String, Codable {
    case manual
    case aiGenerated
}

@Model
final class Card {
    var id: UUID
    var type: CardType
    var answer: String
    @Relationship(deleteRule: .cascade) var contexts: [CardContext]
    var audioText: String
    var hint: String?
    var tags: [String]
    var source: CardSource
    var createdAt: Date

    init(
        type: CardType,
        answer: String,
        audioText: String,
        hint: String? = nil,
        tags: [String] = [],
        source: CardSource = .manual
    ) {
        self.id = UUID()
        self.type = type
        self.answer = answer
        self.contexts = []
        self.audioText = audioText
        self.hint = hint
        self.tags = tags
        self.source = source
        self.createdAt = Date()
    }
}
```

Create `AnkiAnna/AnkiAnna/Models/CardContext.swift`:
```swift
import Foundation
import SwiftData

enum ContextType: String, Codable {
    case phrase
    case sentence
}

@Model
final class CardContext {
    var id: UUID
    var type: ContextType
    var text: String
    var fullText: String
    var source: CardSource

    init(type: ContextType, text: String, fullText: String, source: CardSource = .manual) {
        self.id = UUID()
        self.type = type
        self.text = text
        self.fullText = fullText
        self.source = source
    }
}
```

Create `AnkiAnna/AnkiAnna/Models/ReviewRecord.swift`:
```swift
import Foundation
import SwiftData

enum ReviewResult: String, Codable {
    case correct
    case wrong
}

@Model
final class ReviewRecord {
    var id: UUID
    var card: Card?
    var reviewedAt: Date
    var result: ReviewResult
    var ease: Double
    var interval: Int
    var nextReviewDate: Date
    var handwritingImage: Data?

    init(
        card: Card,
        result: ReviewResult,
        ease: Double,
        interval: Int,
        nextReviewDate: Date
    ) {
        self.id = UUID()
        self.card = card
        self.reviewedAt = Date()
        self.result = result
        self.ease = ease
        self.interval = interval
        self.nextReviewDate = nextReviewDate
    }
}
```

Create `AnkiAnna/AnkiAnna/Models/DailySession.swift`:
```swift
import Foundation
import SwiftData

@Model
final class DailySession {
    var id: UUID
    var date: Date
    var targetCount: Int
    var completedCount: Int
    var correctCount: Int
    var streak: Int

    init(date: Date, targetCount: Int) {
        self.id = UUID()
        self.date = date
        self.targetCount = targetCount
        self.completedCount = 0
        self.correctCount = 0
        self.streak = 0
    }
}
```

Create `AnkiAnna/AnkiAnna/Models/UserProfile.swift`:
```swift
import Foundation
import SwiftData

@Model
final class UserProfile {
    var id: UUID
    var name: String
    var dailyGoal: Int
    var totalPoints: Int
    var badges: [String]

    init(name: String, dailyGoal: Int = 15) {
        self.id = UUID()
        self.name = name
        self.dailyGoal = dailyGoal
        self.totalPoints = 0
        self.badges = []
    }
}
```

**Step 4: Run tests**

```bash
cd ~/Projects/ankianna/AnkiAnna
xcodebuild test -project AnkiAnna.xcodeproj -scheme AnkiAnnaTests -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' 2>&1 | grep -E '(Test Case|BUILD)'
```

Expected: All 5 tests PASS, BUILD SUCCEEDED.

**Step 5: Commit**

```bash
cd ~/Projects/ankianna
git add AnkiAnna/
git commit -m "feat: 实现 SwiftData 数据模型（Card, CardContext, ReviewRecord, DailySession, UserProfile）"
```

---

## Task 3: SM-2 Spaced Repetition Engine

**Files:**
- Create: `AnkiAnna/AnkiAnna/Services/SM2Engine.swift`
- Create: `AnkiAnna/AnkiAnnaTests/SM2EngineTests.swift`

**Step 1: Write SM-2 tests**

Create `AnkiAnna/AnkiAnnaTests/SM2EngineTests.swift`:
```swift
import XCTest
@testable import AnkiAnna

final class SM2EngineTests: XCTestCase {

    func testFirstCorrectReview() {
        // First review: correct answer
        let result = SM2Engine.calculateNext(
            quality: 5,  // perfect
            previousEase: 2.5,
            previousInterval: 0,
            repetition: 0
        )
        XCTAssertEqual(result.interval, 1)
        XCTAssertEqual(result.ease, 2.6, accuracy: 0.01)
        XCTAssertEqual(result.repetition, 1)
    }

    func testSecondCorrectReview() {
        let result = SM2Engine.calculateNext(
            quality: 4,  // correct with hesitation
            previousEase: 2.5,
            previousInterval: 1,
            repetition: 1
        )
        XCTAssertEqual(result.interval, 6)
        XCTAssertEqual(result.repetition, 2)
    }

    func testThirdCorrectReview() {
        let result = SM2Engine.calculateNext(
            quality: 4,
            previousEase: 2.5,
            previousInterval: 6,
            repetition: 2
        )
        // interval = round(6 * 2.5) = 15
        XCTAssertEqual(result.interval, 15)
        XCTAssertEqual(result.repetition, 3)
    }

    func testIncorrectReviewResetsInterval() {
        let result = SM2Engine.calculateNext(
            quality: 1,  // wrong
            previousEase: 2.5,
            previousInterval: 15,
            repetition: 3
        )
        XCTAssertEqual(result.interval, 1)
        XCTAssertEqual(result.repetition, 0)
        // ease should decrease but not below 1.3
        XCTAssertGreaterThanOrEqual(result.ease, 1.3)
    }

    func testEaseNeverBelowMinimum() {
        // Repeatedly wrong answers
        var ease = 2.5
        for _ in 0..<10 {
            let result = SM2Engine.calculateNext(
                quality: 0,
                previousEase: ease,
                previousInterval: 1,
                repetition: 0
            )
            ease = result.ease
        }
        XCTAssertGreaterThanOrEqual(ease, 1.3)
    }

    func testQualityToResult() {
        // quality >= 3 is correct
        XCTAssertTrue(SM2Engine.isCorrect(quality: 3))
        XCTAssertTrue(SM2Engine.isCorrect(quality: 4))
        XCTAssertTrue(SM2Engine.isCorrect(quality: 5))
        XCTAssertFalse(SM2Engine.isCorrect(quality: 2))
        XCTAssertFalse(SM2Engine.isCorrect(quality: 1))
        XCTAssertFalse(SM2Engine.isCorrect(quality: 0))
    }

    func testSelectDueCards() {
        // Cards with nextReviewDate <= now should be selected
        let now = Date()
        let dueCard = SM2Engine.CardSchedule(
            cardId: UUID(),
            nextReviewDate: now.addingTimeInterval(-3600), // 1 hour ago
            ease: 2.5,
            interval: 1,
            repetition: 1
        )
        let futureCard = SM2Engine.CardSchedule(
            cardId: UUID(),
            nextReviewDate: now.addingTimeInterval(86400), // tomorrow
            ease: 2.5,
            interval: 6,
            repetition: 2
        )
        let newCard = SM2Engine.CardSchedule(
            cardId: UUID(),
            nextReviewDate: nil, // never reviewed
            ease: 2.5,
            interval: 0,
            repetition: 0
        )

        let due = SM2Engine.selectDueCards(
            from: [dueCard, futureCard, newCard],
            limit: 15,
            now: now
        )

        // Due card and new card should be included, future card excluded
        XCTAssertEqual(due.count, 2)
        XCTAssertTrue(due.contains(where: { $0.cardId == dueCard.cardId }))
        XCTAssertTrue(due.contains(where: { $0.cardId == newCard.cardId }))
        XCTAssertFalse(due.contains(where: { $0.cardId == futureCard.cardId }))
    }
}
```

**Step 2: Run test to verify it fails**

```bash
cd ~/Projects/ankianna/AnkiAnna
xcodebuild test -project AnkiAnna.xcodeproj -scheme AnkiAnnaTests -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' -only-testing:AnkiAnnaTests/SM2EngineTests 2>&1 | tail -10
```

Expected: FAIL — `SM2Engine` not defined.

**Step 3: Implement SM-2 engine**

Create `AnkiAnna/AnkiAnna/Services/SM2Engine.swift`:
```swift
import Foundation

enum SM2Engine {

    struct ReviewOutput {
        let interval: Int
        let ease: Double
        let repetition: Int
        let nextReviewDate: Date
    }

    struct CardSchedule {
        let cardId: UUID
        let nextReviewDate: Date?
        let ease: Double
        let interval: Int
        let repetition: Int
    }

    /// SM-2 algorithm: calculate next review interval
    /// - quality: 0-5 (0=complete failure, 5=perfect)
    static func calculateNext(
        quality: Int,
        previousEase: Double,
        previousInterval: Int,
        repetition: Int,
        now: Date = Date()
    ) -> ReviewOutput {
        let q = Double(min(max(quality, 0), 5))

        // Update ease factor
        var newEase = previousEase + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))
        newEase = max(newEase, 1.3)

        let newInterval: Int
        let newRepetition: Int

        if quality >= 3 {
            // Correct response
            switch repetition {
            case 0:
                newInterval = 1
            case 1:
                newInterval = 6
            default:
                newInterval = Int(round(Double(previousInterval) * newEase))
            }
            newRepetition = repetition + 1
        } else {
            // Incorrect - reset
            newInterval = 1
            newRepetition = 0
        }

        let nextDate = Calendar.current.date(byAdding: .day, value: newInterval, to: now)!

        return ReviewOutput(
            interval: newInterval,
            ease: newEase,
            repetition: newRepetition,
            nextReviewDate: nextDate
        )
    }

    static func isCorrect(quality: Int) -> Bool {
        quality >= 3
    }

    /// Select cards due for review, sorted by priority (overdue first, then new)
    static func selectDueCards(
        from schedules: [CardSchedule],
        limit: Int,
        now: Date = Date()
    ) -> [CardSchedule] {
        let due = schedules.filter { schedule in
            guard let nextDate = schedule.nextReviewDate else {
                return true // Never reviewed = due
            }
            return nextDate <= now
        }

        // Sort: overdue cards first (by how overdue), then new cards
        let sorted = due.sorted { a, b in
            let aDate = a.nextReviewDate ?? Date.distantPast
            let bDate = b.nextReviewDate ?? Date.distantPast
            return aDate < bDate
        }

        return Array(sorted.prefix(limit))
    }
}
```

**Step 4: Run tests**

```bash
cd ~/Projects/ankianna/AnkiAnna
xcodebuild test -project AnkiAnna.xcodeproj -scheme AnkiAnnaTests -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' -only-testing:AnkiAnnaTests/SM2EngineTests 2>&1 | grep -E '(Test Case|BUILD)'
```

Expected: All 7 tests PASS.

**Step 5: Commit**

```bash
cd ~/Projects/ankianna
git add AnkiAnna/
git commit -m "feat: 实现 SM-2 间隔重复算法引擎 + 单元测试"
```

---

## Task 4: TTS Service

**Files:**
- Create: `AnkiAnna/AnkiAnna/Services/TTSService.swift`
- Create: `AnkiAnna/AnkiAnnaTests/TTSServiceTests.swift`

**Step 1: Write TTS test**

Create `AnkiAnna/AnkiAnnaTests/TTSServiceTests.swift`:
```swift
import XCTest
@testable import AnkiAnna

final class TTSServiceTests: XCTestCase {

    func testChineseLanguageCode() {
        let lang = TTSService.languageCode(for: .chineseWriting)
        XCTAssertEqual(lang, "zh-CN")
    }

    func testEnglishLanguageCode() {
        let lang = TTSService.languageCode(for: .englishSpelling)
        XCTAssertEqual(lang, "en-US")
    }

    func testCreateUtterance() {
        let utterance = TTSService.createUtterance(text: "龙飞凤舞", cardType: .chineseWriting)
        XCTAssertEqual(utterance.speechString, "龙飞凤舞")
        XCTAssertEqual(utterance.voice?.language, "zh-CN")
    }
}
```

**Step 2: Run test to verify it fails**

Expected: FAIL — `TTSService` not defined.

**Step 3: Implement TTS service**

Create `AnkiAnna/AnkiAnna/Services/TTSService.swift`:
```swift
import AVFoundation

enum TTSService {

    private static let synthesizer = AVSpeechSynthesizer()

    static func languageCode(for cardType: CardType) -> String {
        switch cardType {
        case .chineseWriting: return "zh-CN"
        case .englishSpelling: return "en-US"
        }
    }

    static func createUtterance(text: String, cardType: CardType) -> AVSpeechUtterance {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: languageCode(for: cardType))
        utterance.rate = 0.4 // Slow for children
        utterance.pitchMultiplier = 1.0
        return utterance
    }

    static func speak(text: String, cardType: CardType) {
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = createUtterance(text: text, cardType: cardType)
        synthesizer.speak(utterance)
    }

    static func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }
}
```

**Step 4: Run tests**

```bash
cd ~/Projects/ankianna/AnkiAnna
xcodebuild test -project AnkiAnna.xcodeproj -scheme AnkiAnnaTests -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' -only-testing:AnkiAnnaTests/TTSServiceTests 2>&1 | grep -E '(Test Case|BUILD)'
```

Expected: All 3 tests PASS.

**Step 5: Commit**

```bash
cd ~/Projects/ankianna
git add AnkiAnna/
git commit -m "feat: 实现 TTS 发音服务（中英文支持）"
```

---

## Task 5: Handwriting Recognition Service

**Files:**
- Create: `AnkiAnna/AnkiAnna/Services/HandwritingRecognizer.swift`
- Create: `AnkiAnna/AnkiAnnaTests/HandwritingRecognizerTests.swift`

**Step 1: Write test**

Create `AnkiAnna/AnkiAnnaTests/HandwritingRecognizerTests.swift`:
```swift
import XCTest
@testable import AnkiAnna

final class HandwritingRecognizerTests: XCTestCase {

    func testMatchExact() {
        XCTAssertTrue(HandwritingRecognizer.matches(recognized: "龙", expected: "龙"))
    }

    func testMatchCaseInsensitive() {
        XCTAssertTrue(HandwritingRecognizer.matches(recognized: "Dragon", expected: "dragon"))
    }

    func testMatchWithWhitespace() {
        XCTAssertTrue(HandwritingRecognizer.matches(recognized: " dragon ", expected: "dragon"))
    }

    func testNoMatch() {
        XCTAssertFalse(HandwritingRecognizer.matches(recognized: "虎", expected: "龙"))
    }

    func testBestMatchFromCandidates() {
        let candidates = ["虎", "龙", "马"]
        let result = HandwritingRecognizer.bestMatch(candidates: candidates, expected: "龙")
        XCTAssertTrue(result)
    }

    func testBestMatchNoMatch() {
        let candidates = ["虎", "马", "牛"]
        let result = HandwritingRecognizer.bestMatch(candidates: candidates, expected: "龙")
        XCTAssertFalse(result)
    }
}
```

**Step 2: Run test to verify it fails**

Expected: FAIL — `HandwritingRecognizer` not defined.

**Step 3: Implement recognizer**

Create `AnkiAnna/AnkiAnna/Services/HandwritingRecognizer.swift`:
```swift
import Vision
import PencilKit
import UIKit

enum HandwritingRecognizer {

    /// Compare recognized text with expected answer
    static func matches(recognized: String, expected: String) -> Bool {
        let cleanRecognized = recognized.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let cleanExpected = expected.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return cleanRecognized == cleanExpected
    }

    /// Check if any candidate matches the expected answer
    static func bestMatch(candidates: [String], expected: String) -> Bool {
        candidates.contains { matches(recognized: $0, expected: expected) }
    }

    /// Recognize handwriting from PencilKit drawing
    /// Returns array of candidate strings (best match first)
    static func recognize(
        drawing: PKDrawing,
        language: String,
        completion: @escaping (Result<[String], Error>) -> Void
    ) {
        let image = drawing.image(from: drawing.bounds, scale: 2.0)
        guard let cgImage = image.cgImage else {
            completion(.failure(RecognitionError.invalidImage))
            return
        }

        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                completion(.success([]))
                return
            }
            let candidates = observations.compactMap { observation in
                observation.topCandidates(5).map(\.string)
            }.flatMap { $0 }
            completion(.success(candidates))
        }

        request.recognitionLanguages = [language]
        request.recognitionLevel = .accurate

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                completion(.failure(error))
            }
        }
    }

    enum RecognitionError: Error {
        case invalidImage
    }
}
```

**Step 4: Run tests**

```bash
cd ~/Projects/ankianna/AnkiAnna
xcodebuild test -project AnkiAnna.xcodeproj -scheme AnkiAnnaTests -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' -only-testing:AnkiAnnaTests/HandwritingRecognizerTests 2>&1 | grep -E '(Test Case|BUILD)'
```

Expected: All 6 tests PASS (string matching tests; actual Vision recognition needs real device).

**Step 5: Commit**

```bash
cd ~/Projects/ankianna
git add AnkiAnna/
git commit -m "feat: 实现手写识别服务（Vision 框架 + 字符串匹配）"
```

---

## Task 6: Learning View (Dictation UI)

**Files:**
- Create: `AnkiAnna/AnkiAnna/Views/Learning/LearningView.swift`
- Create: `AnkiAnna/AnkiAnna/Views/Learning/WritingCanvasView.swift`
- Create: `AnkiAnna/AnkiAnna/Views/Learning/CardPromptView.swift`
- Create: `AnkiAnna/AnkiAnna/Views/Learning/ResultFeedbackView.swift`
- Create: `AnkiAnna/AnkiAnna/Views/Learning/LearningViewModel.swift`
- Modify: `AnkiAnna/AnkiAnna/ContentView.swift` — replace placeholder

**Step 1: Create LearningViewModel**

Create `AnkiAnna/AnkiAnna/Views/Learning/LearningViewModel.swift`:
```swift
import SwiftUI
import SwiftData
import PencilKit

@Observable
final class LearningViewModel {
    var currentCard: Card?
    var currentContext: CardContext?
    var showResult: Bool = false
    var isCorrect: Bool = false
    var sessionComplete: Bool = false
    var completedCount: Int = 0
    var correctCount: Int = 0
    var totalCount: Int = 0

    private var dueCards: [Card] = []
    private var currentIndex: Int = 0
    private var usedContextIds: Set<UUID> = []

    func loadDueCards(from cards: [Card], dailyGoal: Int) {
        // Filter cards that are due (simplified: all cards for now)
        dueCards = Array(cards.prefix(dailyGoal))
        totalCount = dueCards.count
        currentIndex = 0
        completedCount = 0
        correctCount = 0
        sessionComplete = dueCards.isEmpty
        if !dueCards.isEmpty {
            advanceToNext()
        }
    }

    func advanceToNext() {
        guard currentIndex < dueCards.count else {
            sessionComplete = true
            return
        }
        currentCard = dueCards[currentIndex]
        currentContext = selectRandomContext(for: currentCard!)
        showResult = false
        isCorrect = false
    }

    func submitAnswer(recognized: String) {
        guard let card = currentCard else { return }
        isCorrect = HandwritingRecognizer.matches(recognized: recognized, expected: card.answer)
        showResult = true
        completedCount += 1
        if isCorrect { correctCount += 1 }
    }

    func next() {
        currentIndex += 1
        advanceToNext()
    }

    func retry() {
        showResult = false
        completedCount -= 1 // Don't double count
    }

    private func selectRandomContext(for card: Card) -> CardContext? {
        let available = card.contexts.filter { !usedContextIds.contains($0.id) }
        let selected = (available.isEmpty ? card.contexts : available).randomElement()
        if let selected { usedContextIds.insert(selected.id) }
        return selected
    }
}
```

**Step 2: Create WritingCanvasView (PencilKit wrapper)**

Create `AnkiAnna/AnkiAnna/Views/Learning/WritingCanvasView.swift`:
```swift
import SwiftUI
import PencilKit

struct WritingCanvasView: UIViewRepresentable {
    @Binding var drawing: PKDrawing

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.drawing = drawing
        canvas.tool = PKInkingTool(.pen, color: .black, width: 5)
        canvas.drawingPolicy = .pencilOnly
        canvas.backgroundColor = .clear
        canvas.delegate = context.coordinator
        return canvas
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(drawing: $drawing)
    }

    class Coordinator: NSObject, PKCanvasViewDelegate {
        @Binding var drawing: PKDrawing

        init(drawing: Binding<PKDrawing>) {
            _drawing = drawing
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            drawing = canvasView.drawing
        }
    }
}
```

**Step 3: Create CardPromptView**

Create `AnkiAnna/AnkiAnna/Views/Learning/CardPromptView.swift`:
```swift
import SwiftUI

struct CardPromptView: View {
    let context: CardContext?
    let cardType: CardType
    let onSpeak: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            if let context {
                Text(context.text)
                    .font(.system(size: 36, weight: .medium))
                    .multilineTextAlignment(.center)

                Text(context.type == .phrase ? "组词" : "造句")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button(action: onSpeak) {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.blue)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
        .padding()
    }
}
```

**Step 4: Create ResultFeedbackView**

Create `AnkiAnna/AnkiAnna/Views/Learning/ResultFeedbackView.swift`:
```swift
import SwiftUI

struct ResultFeedbackView: View {
    let isCorrect: Bool
    let correctAnswer: String
    let onNext: () -> Void
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            if isCorrect {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.green)
                Text("太棒了！")
                    .font(.system(size: 32, weight: .bold))
            } else {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.red)
                Text("正确答案")
                    .font(.headline)
                Text(correctAnswer)
                    .font(.system(size: 48, weight: .bold))
            }

            HStack(spacing: 20) {
                if !isCorrect {
                    Button("再试一次", action: onRetry)
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                }
                Button(isCorrect ? "下一个" : "跳过", action: onNext)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
            }
        }
        .padding()
    }
}
```

**Step 5: Create LearningView (main dictation screen)**

Create `AnkiAnna/AnkiAnna/Views/Learning/LearningView.swift`:
```swift
import SwiftUI
import SwiftData
import PencilKit

struct LearningView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var cards: [Card]
    @State private var viewModel = LearningViewModel()
    @State private var drawing = PKDrawing()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.sessionComplete {
                    sessionCompleteView
                } else if let card = viewModel.currentCard {
                    learningContentView(card: card)
                } else {
                    emptyStateView
                }
            }
            .navigationTitle("学习")
            .onAppear {
                viewModel.loadDueCards(from: cards, dailyGoal: 15)
            }
        }
    }

    private func learningContentView(card: Card) -> some View {
        HStack(spacing: 0) {
            // Left: prompt + controls
            VStack {
                Spacer()
                CardPromptView(
                    context: viewModel.currentContext,
                    cardType: card.type,
                    onSpeak: {
                        if let ctx = viewModel.currentContext {
                            TTSService.speak(text: ctx.fullText, cardType: card.type)
                        }
                    }
                )
                Spacer()

                // Progress
                Text("\(viewModel.completedCount)/\(viewModel.totalCount)")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .padding(.bottom)
            }
            .frame(maxWidth: .infinity)

            // Right: writing area or result
            VStack {
                if viewModel.showResult {
                    ResultFeedbackView(
                        isCorrect: viewModel.isCorrect,
                        correctAnswer: card.answer,
                        onNext: {
                            drawing = PKDrawing()
                            viewModel.next()
                        },
                        onRetry: {
                            drawing = PKDrawing()
                            viewModel.retry()
                        }
                    )
                } else {
                    WritingCanvasView(drawing: $drawing)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.white)
                                .shadow(radius: 2)
                        )
                        .padding()

                    Button("提交") {
                        submitDrawing(card: card)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding(.bottom)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var sessionCompleteView: some View {
        VStack(spacing: 20) {
            Image(systemName: "star.fill")
                .font(.system(size: 80))
                .foregroundStyle(.yellow)
            Text("今天的学习完成了！")
                .font(.system(size: 28, weight: .bold))
            Text("正确 \(viewModel.correctCount)/\(viewModel.totalCount)")
                .font(.title2)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "rectangle.stack.badge.plus")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text("还没有卡片")
                .font(.title2)
            Text("去「添加」页面创建一些卡片吧")
                .foregroundStyle(.secondary)
        }
    }

    private func submitDrawing(card: Card) {
        let lang = TTSService.languageCode(for: card.type)
        HandwritingRecognizer.recognize(drawing: drawing, language: lang) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let candidates):
                    let matched = HandwritingRecognizer.bestMatch(candidates: candidates, expected: card.answer)
                    if matched {
                        viewModel.submitAnswer(recognized: card.answer)
                    } else {
                        viewModel.submitAnswer(recognized: candidates.first ?? "")
                    }
                case .failure:
                    viewModel.submitAnswer(recognized: "")
                }
            }
        }
    }
}
```

**Step 6: Update ContentView**

Modify `AnkiAnna/AnkiAnna/ContentView.swift`:
```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            LearningView()
                .tabItem {
                    Label("学习", systemImage: "pencil.line")
                }
            Text("卡片库")
                .tabItem {
                    Label("卡片库", systemImage: "rectangle.stack")
                }
            Text("添加")
                .tabItem {
                    Label("添加", systemImage: "plus.circle")
                }
            Text("统计")
                .tabItem {
                    Label("统计", systemImage: "chart.bar")
                }
        }
    }
}
```

**Step 7: Build and verify**

```bash
cd ~/Projects/ankianna/AnkiAnna
xcodebuild -project AnkiAnna.xcodeproj -scheme AnkiAnna -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' build 2>&1 | tail -5
```

Expected: BUILD SUCCEEDED.

**Step 8: Commit**

```bash
cd ~/Projects/ankianna
git add AnkiAnna/
git commit -m "feat: 实现听写主界面（PencilKit 书写 + 手写识别 + 结果反馈）"
```

---

## Task 7: Card Management (Add + Library)

**Files:**
- Create: `AnkiAnna/AnkiAnna/Views/AddCard/ManualAddCardView.swift`
- Create: `AnkiAnna/AnkiAnna/Views/AddCard/AddCardView.swift`
- Create: `AnkiAnna/AnkiAnna/Views/CardLibrary/CardLibraryView.swift`
- Create: `AnkiAnna/AnkiAnna/Views/CardLibrary/CardDetailView.swift`
- Modify: `AnkiAnna/AnkiAnna/ContentView.swift`

**Step 1: Create ManualAddCardView**

Create `AnkiAnna/AnkiAnna/Views/AddCard/ManualAddCardView.swift`:
```swift
import SwiftUI
import SwiftData

struct ManualAddCardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var cardType: CardType = .chineseWriting
    @State private var answer = ""
    @State private var contextText = ""
    @State private var contextFullText = ""
    @State private var contextType: ContextType = .phrase
    @State private var contexts: [(type: ContextType, text: String, fullText: String)] = []
    @State private var tags = ""

    var body: some View {
        Form {
            Section("卡片类型") {
                Picker("类型", selection: $cardType) {
                    Text("中文写字").tag(CardType.chineseWriting)
                    Text("英文拼写").tag(CardType.englishSpelling)
                }
                .pickerStyle(.segmented)
            }

            Section("目标字词") {
                TextField("如：龙、dragon", text: $answer)
                    .font(.title2)
            }

            Section("添加语境") {
                Picker("语境类型", selection: $contextType) {
                    Text("组词").tag(ContextType.phrase)
                    Text("造句").tag(ContextType.sentence)
                }
                .pickerStyle(.segmented)

                TextField("含空位的文本（如 ___飞凤舞）", text: $contextText)
                TextField("完整文本（如 龙飞凤舞）", text: $contextFullText)

                Button("添加语境") {
                    guard !contextText.isEmpty, !contextFullText.isEmpty else { return }
                    contexts.append((type: contextType, text: contextText, fullText: contextFullText))
                    contextText = ""
                    contextFullText = ""
                }
                .disabled(contextText.isEmpty || contextFullText.isEmpty)
            }

            if !contexts.isEmpty {
                Section("已添加的语境 (\(contexts.count))") {
                    ForEach(contexts.indices, id: \.self) { index in
                        VStack(alignment: .leading) {
                            Text(contexts[index].text).font(.headline)
                            Text(contexts[index].fullText).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .onDelete { contexts.remove(atOffsets: $0) }
                }
            }

            Section("标签") {
                TextField("逗号分隔（如：二年级,动物）", text: $tags)
            }

            Section {
                Button("保存卡片") {
                    saveCard()
                }
                .disabled(answer.isEmpty || contexts.isEmpty)
            }
        }
        .navigationTitle("手动添加")
    }

    private func saveCard() {
        let card = Card(
            type: cardType,
            answer: answer,
            audioText: answer,
            tags: tags.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
        )
        for ctx in contexts {
            let context = CardContext(type: ctx.type, text: ctx.text, fullText: ctx.fullText)
            card.contexts.append(context)
        }
        modelContext.insert(card)
        dismiss()
    }
}
```

**Step 2: Create AddCardView (entry point with manual/AI tabs)**

Create `AnkiAnna/AnkiAnna/Views/AddCard/AddCardView.swift`:
```swift
import SwiftUI

struct AddCardView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink {
                    ManualAddCardView()
                } label: {
                    Label("手动添加", systemImage: "square.and.pencil")
                }

                NavigationLink {
                    Text("AI 生成（待实现）")
                } label: {
                    Label("AI 自动生成", systemImage: "sparkles")
                }
            }
            .navigationTitle("添加卡片")
        }
    }
}
```

**Step 3: Create CardLibraryView**

Create `AnkiAnna/AnkiAnna/Views/CardLibrary/CardLibraryView.swift`:
```swift
import SwiftUI
import SwiftData

struct CardLibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Card.createdAt, order: .reverse) private var cards: [Card]

    var body: some View {
        NavigationStack {
            List {
                ForEach(cards) { card in
                    NavigationLink {
                        CardDetailView(card: card)
                    } label: {
                        HStack {
                            Text(card.answer)
                                .font(.title2)
                            Spacer()
                            Text(card.type == .chineseWriting ? "中文" : "英文")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(card.contexts.count) 个语境")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        modelContext.delete(cards[index])
                    }
                }
            }
            .navigationTitle("卡片库 (\(cards.count))")
            .overlay {
                if cards.isEmpty {
                    ContentUnavailableView("没有卡片", systemImage: "rectangle.stack", description: Text("去添加一些卡片吧"))
                }
            }
        }
    }
}
```

**Step 4: Create CardDetailView**

Create `AnkiAnna/AnkiAnna/Views/CardLibrary/CardDetailView.swift`:
```swift
import SwiftUI

struct CardDetailView: View {
    let card: Card

    var body: some View {
        List {
            Section("基本信息") {
                LabeledContent("目标字词", value: card.answer)
                LabeledContent("类型", value: card.type == .chineseWriting ? "中文写字" : "英文拼写")
                LabeledContent("来源", value: card.source == .manual ? "手动" : "AI 生成")
            }

            Section("语境 (\(card.contexts.count))") {
                ForEach(card.contexts) { ctx in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(ctx.text).font(.headline)
                        Text(ctx.fullText).font(.subheadline).foregroundStyle(.secondary)
                        Text(ctx.type == .phrase ? "组词" : "造句")
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(.blue.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
            }

            if !card.tags.isEmpty {
                Section("标签") {
                    FlowLayout(spacing: 8) {
                        ForEach(card.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(.gray.opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .navigationTitle(card.answer)
    }
}

// Simple flow layout for tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}
```

**Step 5: Update ContentView**

Replace `AnkiAnna/AnkiAnna/ContentView.swift`:
```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            LearningView()
                .tabItem {
                    Label("学习", systemImage: "pencil.line")
                }
            CardLibraryView()
                .tabItem {
                    Label("卡片库", systemImage: "rectangle.stack")
                }
            AddCardView()
                .tabItem {
                    Label("添加", systemImage: "plus.circle")
                }
            Text("统计（待实现）")
                .tabItem {
                    Label("统计", systemImage: "chart.bar")
                }
        }
    }
}
```

**Step 6: Build and verify**

```bash
cd ~/Projects/ankianna/AnkiAnna
xcodebuild -project AnkiAnna.xcodeproj -scheme AnkiAnna -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' build 2>&1 | tail -5
```

Expected: BUILD SUCCEEDED.

**Step 7: Commit**

```bash
cd ~/Projects/ankianna
git add AnkiAnna/
git commit -m "feat: 实现卡片管理（手动添加 + 卡片库浏览 + 详情查看）"
```

---

## Task 8: AI Card Generation

**Files:**
- Create: `AnkiAnna/AnkiAnna/Services/AIGenerator.swift`
- Create: `AnkiAnna/AnkiAnna/Views/AddCard/AIGenerateView.swift`
- Modify: `AnkiAnna/AnkiAnna/Views/AddCard/AddCardView.swift`

**Step 1: Create AIGenerator service**

Create `AnkiAnna/AnkiAnna/Services/AIGenerator.swift`:
```swift
import Foundation
import Security

enum AIGenerator {

    struct GeneratedCard {
        let answer: String
        let contexts: [(type: ContextType, text: String, fullText: String)]
    }

    static func generateCards(
        subject: CardType,
        grade: String,
        topic: String,
        apiKey: String
    ) async throws -> [GeneratedCard] {
        let subjectText = subject == .chineseWriting ? "中文汉字" : "英文单词"
        let prompt = """
        你是一个小学语文/英语教师。请为\(grade)\(topic)生成 8 个\(subjectText)听写卡片。

        每个卡片包含：
        1. 目标字/词
        2. 5 个语境（组词或造句），用 ___ 替代目标字/词

        请用 JSON 格式返回：
        [{"answer": "龙", "contexts": [{"type": "phrase", "text": "___飞凤舞", "fullText": "龙飞凤舞"}]}]
        """

        let body: [String: Any] = [
            "model": "claude-sonnet-4-20250514",
            "max_tokens": 2000,
            "messages": [["role": "user", "content": prompt]]
        ]

        var request = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)

        // Parse response - extract text content
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let textBlock = content.first(where: { $0["type"] as? String == "text" }),
              let text = textBlock["text"] as? String else {
            throw GeneratorError.parseError
        }

        // Extract JSON array from response text
        guard let jsonStart = text.firstIndex(of: "["),
              let jsonEnd = text.lastIndex(of: "]") else {
            throw GeneratorError.parseError
        }
        let jsonString = String(text[jsonStart...jsonEnd])
        let cardsData = try JSONSerialization.jsonObject(with: jsonString.data(using: .utf8)!) as? [[String: Any]] ?? []

        return cardsData.compactMap { cardDict -> GeneratedCard? in
            guard let answer = cardDict["answer"] as? String,
                  let contexts = cardDict["contexts"] as? [[String: Any]] else { return nil }
            let parsedContexts = contexts.compactMap { ctx -> (type: ContextType, text: String, fullText: String)? in
                guard let text = ctx["text"] as? String,
                      let fullText = ctx["fullText"] as? String else { return nil }
                let type: ContextType = (ctx["type"] as? String) == "sentence" ? .sentence : .phrase
                return (type: type, text: text, fullText: fullText)
            }
            return GeneratedCard(answer: answer, contexts: parsedContexts)
        }
    }

    // Keychain helpers for API key
    static func saveAPIKey(_ key: String) {
        let data = key.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "ankianna-api-key",
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    static func loadAPIKey() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "ankianna-api-key",
            kSecReturnData as String: true
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    enum GeneratorError: Error {
        case parseError
        case noAPIKey
    }
}
```

**Step 2: Create AIGenerateView**

Create `AnkiAnna/AnkiAnna/Views/AddCard/AIGenerateView.swift`:
```swift
import SwiftUI
import SwiftData

struct AIGenerateView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var cardType: CardType = .chineseWriting
    @State private var grade = "二年级"
    @State private var topic = ""
    @State private var apiKey = ""
    @State private var isLoading = false
    @State private var generatedCards: [AIGenerator.GeneratedCard] = []
    @State private var selectedIndices: Set<Int> = []
    @State private var errorMessage: String?

    let grades = ["一年级", "二年级", "三年级", "四年级", "五年级", "六年级"]

    var body: some View {
        Form {
            Section("生成设置") {
                Picker("类型", selection: $cardType) {
                    Text("中文写字").tag(CardType.chineseWriting)
                    Text("英文拼写").tag(CardType.englishSpelling)
                }
                .pickerStyle(.segmented)

                Picker("年级", selection: $grade) {
                    ForEach(grades, id: \.self) { Text($0) }
                }

                TextField("主题/单元（如：动物、第三课）", text: $topic)
            }

            if apiKey.isEmpty {
                Section("API Key") {
                    SecureField("Anthropic API Key", text: $apiKey)
                    Button("保存 Key") {
                        AIGenerator.saveAPIKey(apiKey)
                    }
                    .disabled(apiKey.isEmpty)
                }
            }

            Section {
                Button(isLoading ? "生成中..." : "生成卡片") {
                    Task { await generate() }
                }
                .disabled(topic.isEmpty || isLoading)
            }

            if let error = errorMessage {
                Section {
                    Text(error).foregroundStyle(.red)
                }
            }

            if !generatedCards.isEmpty {
                Section("预览 (\(generatedCards.count) 张)") {
                    ForEach(generatedCards.indices, id: \.self) { index in
                        let card = generatedCards[index]
                        HStack {
                            VStack(alignment: .leading) {
                                Text(card.answer).font(.headline)
                                Text("\(card.contexts.count) 个语境").font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: selectedIndices.contains(index) ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(selectedIndices.contains(index) ? .blue : .gray)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedIndices.contains(index) {
                                selectedIndices.remove(index)
                            } else {
                                selectedIndices.insert(index)
                            }
                        }
                    }
                }

                Section {
                    Button("导入选中的 \(selectedIndices.count) 张卡片") {
                        importSelected()
                    }
                    .disabled(selectedIndices.isEmpty)
                }
            }
        }
        .navigationTitle("AI 生成")
        .onAppear {
            apiKey = AIGenerator.loadAPIKey() ?? ""
        }
    }

    private func generate() async {
        isLoading = true
        errorMessage = nil
        do {
            let key = apiKey.isEmpty ? (AIGenerator.loadAPIKey() ?? "") : apiKey
            generatedCards = try await AIGenerator.generateCards(
                subject: cardType, grade: grade, topic: topic, apiKey: key
            )
            selectedIndices = Set(generatedCards.indices) // Select all by default
        } catch {
            errorMessage = "生成失败: \(error.localizedDescription)"
        }
        isLoading = false
    }

    private func importSelected() {
        for index in selectedIndices {
            let gen = generatedCards[index]
            let card = Card(
                type: cardType,
                answer: gen.answer,
                audioText: gen.answer,
                source: .aiGenerated
            )
            for ctx in gen.contexts {
                card.contexts.append(CardContext(type: ctx.type, text: ctx.text, fullText: ctx.fullText, source: .aiGenerated))
            }
            modelContext.insert(card)
        }
        dismiss()
    }
}
```

**Step 3: Update AddCardView**

Replace `AnkiAnna/AnkiAnna/Views/AddCard/AddCardView.swift`:
```swift
import SwiftUI

struct AddCardView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink {
                    ManualAddCardView()
                } label: {
                    Label("手动添加", systemImage: "square.and.pencil")
                }

                NavigationLink {
                    AIGenerateView()
                } label: {
                    Label("AI 自动生成", systemImage: "sparkles")
                }
            }
            .navigationTitle("添加卡片")
        }
    }
}
```

**Step 4: Build and verify**

```bash
cd ~/Projects/ankianna/AnkiAnna
xcodebuild -project AnkiAnna.xcodeproj -scheme AnkiAnna -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' build 2>&1 | tail -5
```

Expected: BUILD SUCCEEDED.

**Step 5: Commit**

```bash
cd ~/Projects/ankianna
git add AnkiAnna/
git commit -m "feat: 实现 AI 卡片生成（Claude API + 预览 + 批量导入）"
```

---

## Task 9: Stats View (Points, Badges, Calendar)

**Files:**
- Create: `AnkiAnna/AnkiAnna/Views/Stats/StatsView.swift`
- Create: `AnkiAnna/AnkiAnna/Views/Stats/StreakCalendarView.swift`
- Create: `AnkiAnna/AnkiAnna/Services/PointsService.swift`
- Modify: `AnkiAnna/AnkiAnna/ContentView.swift`

**Step 1: Write points test**

Add to `AnkiAnna/AnkiAnnaTests/SM2EngineTests.swift` (or create new file):
```swift
// In new file AnkiAnnaTests/PointsServiceTests.swift
import XCTest
@testable import AnkiAnna

final class PointsServiceTests: XCTestCase {
    func testCorrectAnswerPoints() {
        XCTAssertEqual(PointsService.pointsForAnswer(correct: true, combo: 0), 10)
    }

    func testComboBonus() {
        XCTAssertEqual(PointsService.pointsForAnswer(correct: true, combo: 3), 13)
        XCTAssertEqual(PointsService.pointsForAnswer(correct: true, combo: 10), 20) // capped
    }

    func testWrongAnswerNoPoints() {
        XCTAssertEqual(PointsService.pointsForAnswer(correct: false, combo: 5), 0)
    }

    func testDailyCompletionBonus() {
        XCTAssertEqual(PointsService.dailyCompletionBonus, 50)
    }
}
```

**Step 2: Implement PointsService**

Create `AnkiAnna/AnkiAnna/Services/PointsService.swift`:
```swift
import Foundation

enum PointsService {
    static let dailyCompletionBonus = 50

    static func pointsForAnswer(correct: Bool, combo: Int) -> Int {
        guard correct else { return 0 }
        let bonus = min(combo, 10) // Cap combo at 10
        return 10 + bonus
    }
}
```

**Step 3: Create StreakCalendarView**

Create `AnkiAnna/AnkiAnna/Views/Stats/StreakCalendarView.swift`:
```swift
import SwiftUI
import SwiftData

struct StreakCalendarView: View {
    let sessions: [DailySession]

    private var completedDates: Set<String> {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return Set(sessions.filter { $0.completedCount > 0 }.map { formatter.string(from: $0.date) })
    }

    var body: some View {
        let calendar = Calendar.current
        let today = Date()
        let days = (0..<30).reversed().map { calendar.date(byAdding: .day, value: -$0, to: today)! }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
            ForEach(days, id: \.self) { day in
                let key = formatter.string(from: day)
                let completed = completedDates.contains(key)
                VStack(spacing: 2) {
                    Text("\(calendar.component(.day, from: day))")
                        .font(.caption2)
                    Circle()
                        .fill(completed ? .green : .gray.opacity(0.2))
                        .frame(width: 24, height: 24)
                }
            }
        }
    }
}
```

**Step 4: Create StatsView**

Create `AnkiAnna/AnkiAnna/Views/Stats/StatsView.swift`:
```swift
import SwiftUI
import SwiftData

struct StatsView: View {
    @Query(sort: \DailySession.date, order: .reverse) private var sessions: [DailySession]
    @Query private var profiles: [UserProfile]

    private var profile: UserProfile? { profiles.first }
    private var currentStreak: Int {
        var streak = 0
        let calendar = Calendar.current
        var checkDate = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        for session in sessions {
            let sessionKey = formatter.string(from: session.date)
            let checkKey = formatter.string(from: checkDate)
            if sessionKey == checkKey && session.completedCount > 0 {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else {
                break
            }
        }
        return streak
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        VStack {
                            Text("\(profile?.totalPoints ?? 0)")
                                .font(.system(size: 36, weight: .bold))
                            Text("积分")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)

                        VStack {
                            Text("\(currentStreak)")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundStyle(.orange)
                            Text("连续打卡")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.vertical)
                }

                Section("打卡日历（近30天）") {
                    StreakCalendarView(sessions: sessions)
                        .padding(.vertical)
                }

                Section("徽章") {
                    if let badges = profile?.badges, !badges.isEmpty {
                        ForEach(badges, id: \.self) { badge in
                            Text(badge)
                        }
                    } else {
                        Text("继续学习解锁徽章").foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("统计")
        }
    }
}
```

**Step 5: Update ContentView**

Replace the stats tab placeholder in `AnkiAnna/AnkiAnna/ContentView.swift`:
```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            LearningView()
                .tabItem {
                    Label("学习", systemImage: "pencil.line")
                }
            CardLibraryView()
                .tabItem {
                    Label("卡片库", systemImage: "rectangle.stack")
                }
            AddCardView()
                .tabItem {
                    Label("添加", systemImage: "plus.circle")
                }
            StatsView()
                .tabItem {
                    Label("统计", systemImage: "chart.bar")
                }
        }
    }
}
```

**Step 6: Run all tests + build**

```bash
cd ~/Projects/ankianna/AnkiAnna
xcodebuild test -project AnkiAnna.xcodeproj -scheme AnkiAnnaTests -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' 2>&1 | grep -E '(Test Case|BUILD|Executed)'
```

Expected: All tests PASS, BUILD SUCCEEDED.

**Step 7: Commit**

```bash
cd ~/Projects/ankianna
git add AnkiAnna/
git commit -m "feat: 实现统计页面（积分、打卡日历、徽章）+ PointsService"
```

---

## Task 10: Integration & Polish

**Files:**
- Modify: `AnkiAnna/AnkiAnna/Views/Learning/LearningViewModel.swift` — integrate SM-2 + points
- Modify: `AnkiAnna/AnkiAnna/AnkiAnnaApp.swift` — add first-launch setup
- Create: `AnkiAnna/AnkiAnnaTests/IntegrationTests.swift`

**Step 1: Write integration test**

Create `AnkiAnna/AnkiAnnaTests/IntegrationTests.swift`:
```swift
import XCTest
import SwiftData
@testable import AnkiAnna

final class IntegrationTests: XCTestCase {

    var container: ModelContainer!

    override func setUp() {
        super.setUp()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try! ModelContainer(
            for: Card.self, ReviewRecord.self, DailySession.self, UserProfile.self,
            configurations: config
        )
    }

    func testFullReviewCycle() throws {
        let context = container.mainContext

        // Create card
        let card = Card(type: .chineseWriting, answer: "龙", audioText: "龙")
        card.contexts = [CardContext(type: .phrase, text: "___飞凤舞", fullText: "龙飞凤舞")]
        context.insert(card)

        // Create profile
        let profile = UserProfile(name: "Anna", dailyGoal: 15)
        context.insert(profile)

        // Simulate correct answer
        let sm2Result = SM2Engine.calculateNext(quality: 5, previousEase: 2.5, previousInterval: 0, repetition: 0)
        let record = ReviewRecord(
            card: card,
            result: .correct,
            ease: sm2Result.ease,
            interval: sm2Result.interval,
            nextReviewDate: sm2Result.nextReviewDate
        )
        context.insert(record)

        // Award points
        let points = PointsService.pointsForAnswer(correct: true, combo: 0)
        profile.totalPoints += points

        try context.save()

        XCTAssertEqual(profile.totalPoints, 10)
        XCTAssertEqual(record.interval, 1)

        let records = try context.fetch(FetchDescriptor<ReviewRecord>())
        XCTAssertEqual(records.count, 1)
    }
}
```

**Step 2: Update LearningViewModel to integrate SM-2 + points + persistence**

Update `AnkiAnna/AnkiAnna/Views/Learning/LearningViewModel.swift` — add `modelContext` parameter and integrate SM-2 scoring + points + ReviewRecord creation on each answer submission. Update `submitAnswer` to:

```swift
func submitAnswer(recognized: String, modelContext: ModelContext, profile: UserProfile?) {
    guard let card = currentCard else { return }
    isCorrect = HandwritingRecognizer.matches(recognized: recognized, expected: card.answer)
    showResult = true
    completedCount += 1
    if isCorrect {
        correctCount += 1
        combo += 1
    } else {
        combo = 0
    }

    // SM-2
    let quality = isCorrect ? 4 : 1
    let sm2 = SM2Engine.calculateNext(
        quality: quality,
        previousEase: 2.5,
        previousInterval: 0,
        repetition: 0
    )
    let record = ReviewRecord(
        card: card,
        result: isCorrect ? .correct : .wrong,
        ease: sm2.ease,
        interval: sm2.interval,
        nextReviewDate: sm2.nextReviewDate
    )
    modelContext.insert(record)

    // Points
    if let profile {
        let points = PointsService.pointsForAnswer(correct: isCorrect, combo: combo)
        profile.totalPoints += points
    }
}
```

Add `@State private var combo: Int = 0` to ViewModel.

**Step 3: Run all tests**

```bash
cd ~/Projects/ankianna/AnkiAnna
xcodebuild test -project AnkiAnna.xcodeproj -scheme AnkiAnnaTests -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' 2>&1 | grep -E '(Test Case|BUILD|Executed)'
```

Expected: All tests PASS.

**Step 4: Commit**

```bash
cd ~/Projects/ankianna
git add AnkiAnna/
git commit -m "feat: 集成 SM-2 评分 + 积分系统到学习流程"
```

---

## Summary

| Task | 内容 | 预估 |
|------|------|------|
| 1 | Xcode 项目骨架 | 20min |
| 2 | SwiftData 数据模型 + 测试 | 30min |
| 3 | SM-2 间隔重复引擎 + 测试 | 30min |
| 4 | TTS 发音服务 + 测试 | 15min |
| 5 | 手写识别服务 + 测试 | 20min |
| 6 | 听写主界面 (LearningView) | 45min |
| 7 | 卡片管理（添加 + 卡片库） | 30min |
| 8 | AI 卡片生成 | 30min |
| 9 | 统计页面 | 25min |
| 10 | 集成 + 打磨 | 20min |

**依赖关系:** Task 1 → Task 2 → Task 3/4/5 (并行) → Task 6 → Task 7/8/9 (并行) → Task 10

**手动测试提醒:** Task 5（手写识别）和 Task 6（听写界面）完成后，需要在真机 iPad + Apple Pencil 上手动测试手写识别准确性。
