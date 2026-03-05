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
