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
