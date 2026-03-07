import PencilKit
#if !targetEnvironment(simulator)
import MLKitDigitalInkRecognition
#endif

enum HandwritingRecognizer {

    #if !targetEnvironment(simulator)
    /// Strong reference to prevent ARC deallocation during async recognition
    private static var activeRecognizer: DigitalInkRecognizer?
    #endif

    private static func log(_ msg: String) {
        NSLog("[Recognizer] %@", msg)
        if let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let logFile = docs.appendingPathComponent("recognizer.log")
            let line = "\(Date()): \(msg)\n"
            if let data = line.data(using: .utf8) {
                if FileManager.default.fileExists(atPath: logFile.path) {
                    if let handle = try? FileHandle(forWritingTo: logFile) {
                        handle.seekToEndOfFile()
                        handle.write(data)
                        handle.closeFile()
                    }
                } else {
                    try? data.write(to: logFile)
                }
            }
        }
    }

    /// Compare recognized text with expected answer.
    static func matches(recognized: String, expected: String) -> Bool {
        let cleanRecognized = recognized.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let cleanExpected = expected.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return cleanRecognized == cleanExpected || cleanRecognized.contains(cleanExpected)
    }

    /// Check if any candidate matches the expected answer
    static func bestMatch(candidates: [String], expected: String) -> Bool {
        let result = candidates.contains { matches(recognized: $0, expected: expected) }
        log("bestMatch candidates=\(candidates) expected=\(expected) match=\(result)")
        return result
    }

    // MARK: - ML Kit Model Management

    #if !targetEnvironment(simulator)
    /// Map language code to ML Kit DigitalInkRecognitionModelIdentifier tag
    private static func mlKitTag(for language: String) -> String {
        switch language {
        case "zh-CN": return "zh-Hani-CN"
        case "zh-TW": return "zh-Hani-TW"
        case "en": return "en-US"
        default: return language
        }
    }
    #endif

    /// Download the ML Kit model for a given language (no-op if already downloaded)
    static func downloadModel(language: String, completion: @escaping (Bool) -> Void) {
        #if targetEnvironment(simulator)
        completion(false)
        #else
        let tag = mlKitTag(for: language)
        log("downloadModel: language=\(language) tag=\(tag)")
        guard let identifier = DigitalInkRecognitionModelIdentifier(forLanguageTag: tag) else {
            log("downloadModel: invalid language tag \(tag)")
            completion(false)
            return
        }
        let model = DigitalInkRecognitionModel(modelIdentifier: identifier)
        let manager = ModelManager.modelManager()
        if manager.isModelDownloaded(model) {
            log("downloadModel: \(tag) already downloaded")
            completion(true)
            return
        }
        log("downloadModel: downloading \(tag)...")
        manager.download(model, conditions: ModelDownloadConditions(allowsCellularAccess: true, allowsBackgroundDownloading: true))

        // Observe download completion
        var observers: [Any] = []
        let successObserver = NotificationCenter.default.addObserver(
            forName: .mlkitModelDownloadDidSucceed, object: nil, queue: .main
        ) { _ in
            log("downloadModel: \(tag) download succeeded")
            observers.forEach { NotificationCenter.default.removeObserver($0) }
            completion(true)
        }
        let failObserver = NotificationCenter.default.addObserver(
            forName: .mlkitModelDownloadDidFail, object: nil, queue: .main
        ) { notification in
            let error = (notification.userInfo?[ModelDownloadUserInfoKey.error.rawValue] as? Error)?.localizedDescription ?? "unknown"
            log("downloadModel: \(tag) download failed: \(error)")
            observers.forEach { NotificationCenter.default.removeObserver($0) }
            completion(false)
        }
        observers = [successObserver, failObserver]
        #endif
    }

    /// Check if model is ready for a given language
    static func isModelReady(language: String) -> Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        let tag = mlKitTag(for: language)
        guard let identifier = DigitalInkRecognitionModelIdentifier(forLanguageTag: tag) else { return false }
        let model = DigitalInkRecognitionModel(modelIdentifier: identifier)
        return ModelManager.modelManager().isModelDownloaded(model)
        #endif
    }

    // MARK: - Recognition

    /// Recognize handwriting from PencilKit drawing using ML Kit Digital Ink
    static func recognize(
        drawing: PKDrawing,
        language: String,
        completion: @escaping (Result<[String], Error>) -> Void
    ) {
        #if targetEnvironment(simulator)
        completion(.failure(RecognitionError.modelNotReady))
        #else
        let tag = mlKitTag(for: language)
        log("START lang=\(language) tag=\(tag) strokes=\(drawing.strokes.count)")

        guard let identifier = DigitalInkRecognitionModelIdentifier(forLanguageTag: tag) else {
            log("ERROR: invalid language tag \(tag)")
            completion(.failure(RecognitionError.invalidLanguage))
            return
        }

        let model = DigitalInkRecognitionModel(modelIdentifier: identifier)
        guard ModelManager.modelManager().isModelDownloaded(model) else {
            log("ERROR: model not downloaded for \(tag)")
            completion(.failure(RecognitionError.modelNotReady))
            return
        }

        // Convert PKDrawing strokes → ML Kit Ink
        var mlStrokes: [MLKitDigitalInkRecognition.Stroke] = []
        for pkStroke in drawing.strokes {
            var points: [StrokePoint] = []
            let path = pkStroke.path
            for i in 0..<path.count {
                let p = path[i]
                let tMs = Int(p.timeOffset * 1000)
                points.append(StrokePoint(x: Float(p.location.x), y: Float(p.location.y), t: tMs))
            }
            if !points.isEmpty {
                mlStrokes.append(MLKitDigitalInkRecognition.Stroke(points: points))
            }
        }

        guard !mlStrokes.isEmpty else {
            log("ERROR: no strokes to recognize")
            completion(.success([]))
            return
        }

        let ink = Ink(strokes: mlStrokes)
        log("ink: \(mlStrokes.count) strokes, total points=\(mlStrokes.reduce(0) { $0 + $1.points.count })")

        let options = DigitalInkRecognizerOptions(model: model)
        let recognizer = DigitalInkRecognizer.digitalInkRecognizer(options: options)
        activeRecognizer = recognizer

        recognizer.recognize(ink: ink) { result, error in
            activeRecognizer = nil
            if let error = error {
                log("ERROR: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            guard let result = result else {
                log("ERROR: nil result")
                completion(.success([]))
                return
            }
            let candidates = result.candidates.map { $0.text }
            log("RESULT: \(candidates)")
            completion(.success(candidates))
        }
        #endif
    }

    enum RecognitionError: Error {
        case invalidImage
        case invalidLanguage
        case modelNotReady
    }
}
