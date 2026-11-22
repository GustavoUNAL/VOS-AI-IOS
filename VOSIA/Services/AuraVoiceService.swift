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
    /// true = tono de llamada (más grave, natural).
    var callTone = false
    var onSpeakFinished: (() -> Void)?

    private let synthesizer = AVSpeechSynthesizer()
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var silenceWatch: Task<Void, Never>?
    private var lastPartialAt = Date()

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

    func startListening(autoStopOnSilence: Bool = false) {
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

        lastPartialAt = Date()
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            Task { @MainActor in
                guard let self else { return }
                if let result {
                    self.liveTranscript = result.bestTranscription.formattedString
                    self.lastPartialAt = Date()
                    if result.isFinal {
                        self.stopListening(keepTranscript: true)
                    }
                }
                if error != nil {
                    self.stopListening(keepTranscript: true)
                }
            }
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
            isListening = true
            liveTranscript = ""
            if autoStopOnSilence {
                watchSilence()
            }
        } catch {
            stopListening()
        }
    }

    private func watchSilence() {
        silenceWatch?.cancel()
        silenceWatch = Task { @MainActor in
            while !Task.isCancelled && isListening {
                try? await Task.sleep(nanoseconds: 350_000_000)
                let spoken = liveTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
                if !spoken.isEmpty, Date().timeIntervalSince(lastPartialAt) > 1.35 {
                    stopListening(keepTranscript: true)
                    break
                }
            }
        }
    }

    func stopListening(keepTranscript: Bool = true) {
        silenceWatch?.cancel()
        silenceWatch = nil
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
        guard speakReplies else {
            onSpeakFinished?()
            return
        }
        let cleaned = Self.stripMarkdown(text)
        guard !cleaned.isEmpty else {
            onSpeakFinished?()
            return
        }
        stopSpeaking()
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {}

        let utterance = AVSpeechUtterance(string: cleaned)
        utterance.voice = Self.preferredVoice(callTone: callTone)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * (callTone ? 1.02 : 1.0)
        utterance.pitchMultiplier = callTone ? 0.88 : 1.0
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
            self.onSpeakFinished?()
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
        }
    }

    private static func preferredVoice(callTone: Bool) -> AVSpeechSynthesisVoice? {
        let voices = AVSpeechSynthesisVoice.speechVoices().filter {
            $0.language.lowercased().hasPrefix("es")
        }
        if callTone {
            let maleHints = ["jorge", "diego", "carlos", "miguel", "enrique", "pablo", "juan", "raul", "alvaro", "álvaro"]
            if let male = voices.first(where: { v in
                maleHints.contains { v.name.lowercased().contains($0) }
            }) {
                return male
            }
        }
        return AVSpeechSynthesisVoice(language: "es-CO")
            ?? AVSpeechSynthesisVoice(language: "es-MX")
            ?? AVSpeechSynthesisVoice(language: "es-ES")
            ?? voices.first
    }

    private static func stripMarkdown(_ text: String) -> String {
        var s = text
        s = s.replacingOccurrences(of: #"\*\*(.+?)\*\*"#, with: "$1", options: .regularExpression)
        s = s.replacingOccurrences(of: #"\*(.+?)\*"#, with: "$1", options: .regularExpression)
        s = s.replacingOccurrences(of: #"^[•\-\*]\s+"#, with: "", options: .regularExpression)
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
