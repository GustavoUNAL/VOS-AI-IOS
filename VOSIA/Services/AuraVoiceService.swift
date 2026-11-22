import AVFoundation
import Foundation
import Observation
import Speech

/// Voz para Aura: dictado (mic) + lectura en voz alta (TTS).
@MainActor
@Observable
final class AuraVoiceService: NSObject, AVSpeechSynthesizerDelegate {
    private(set) var isListening = false
    private(set) var isSpeaking = false
    private(set) var liveTranscript = ""
    private(set) var permissionDenied = false
    var speakReplies = true

    private let synthesizer = AVSpeechSynthesizer()
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    override init() {
        super.init()
        synthesizer.delegate = self
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "es-CO"))
            ?? SFSpeechRecognizer(locale: Locale(identifier: "es-ES"))
            ?? SFSpeechRecognizer()
    }

    func requestPermissions() async -> Bool {
        let speech = await withCheckedContinuation { (cont: CheckedContinuation<Bool, Never>) in
            SFSpeechRecognizer.requestAuthorization { status in
                cont.resume(returning: status == .authorized)
            }
        }
        let mic = await withCheckedContinuation { (cont: CheckedContinuation<Bool, Never>) in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                cont.resume(returning: granted)
            }
        }
        permissionDenied = !(speech && mic)
        return speech && mic
    }

    func toggleListening() async {
        if isListening {
            stopListening()
            return
        }
        let ok = await requestPermissions()
        guard ok else { return }
        startListening()
    }

    func startListening() {
        stopSpeaking()
        stopListening()
        guard let speechRecognizer, speechRecognizer.isAvailable else { return }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            return
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true
        if speechRecognizer.supportsOnDeviceRecognition {
            recognitionRequest.requiresOnDeviceRecognition = false
        }

        let input = audioEngine.inputNode
        let format = input.outputFormat(forBus: 0)
        input.removeTap(onBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            Task { @MainActor in
                guard let self else { return }
                if let result {
                    self.liveTranscript = result.bestTranscription.formattedString
                }
                if error != nil || result?.isFinal == true {
                    self.stopListening(keepTranscript: true)
                }
            }
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
            isListening = true
            liveTranscript = ""
        } catch {
            stopListening()
        }
    }

    func stopListening(keepTranscript: Bool = true) {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        isListening = false
        if !keepTranscript {
            liveTranscript = ""
        }
    }

    func consumeTranscript() -> String {
        let text = liveTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
        liveTranscript = ""
        return text
    }

    func speak(_ text: String) {
        guard speakReplies else { return }
        let cleaned = Self.stripMarkdown(text)
        guard !cleaned.isEmpty else { return }
        stopSpeaking()
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {}

        let utterance = AVSpeechUtterance(string: cleaned)
        utterance.voice =
            AVSpeechSynthesisVoice(language: "es-CO")
            ?? AVSpeechSynthesisVoice(language: "es-MX")
            ?? AVSpeechSynthesisVoice(language: "es-ES")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 1.02
        utterance.pitchMultiplier = 1.05
        isSpeaking = true
        synthesizer.speak(utterance)
    }

    func stopSpeaking() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
        }
    }

    private static func stripMarkdown(_ text: String) -> String {
        var s = text
        s = s.replacingOccurrences(of: #"\*\*(.+?)\*\*"#, with: "$1", options: .regularExpression)
        s = s.replacingOccurrences(of: #"\*(.+?)\*"#, with: "$1", options: .regularExpression)
        s = s.replacingOccurrences(of: #"^[•\-\*]\s+"#, with: "", options: .regularExpression)
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
