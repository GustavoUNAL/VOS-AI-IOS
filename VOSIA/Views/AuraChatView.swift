import SwiftUI

struct AuraChatView: View {
    @Environment(SessionStore.self) private var session
    @State private var draft = ""
    @State private var messages: [ChatMessage] = []
    @State private var isSending = false
    @State private var errorMessage: String?
    @State private var voice = AuraVoiceService()
    @State private var showCall = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        if messages.isEmpty && !isSending {
                            VStack(spacing: 6) {
                                Text("En silencio.")
                                    .font(.headline)
                                Text("Saludá o escribí cuando quieras. Sin sugerencias.")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 48)
                        }

                        ForEach(messages) { message in
                            ChatBubble(
                                isUser: message.role == .user,
                                authorLabel: message.role == .assistant ? "Aura" : "Vos",
                                text: message.text,
                                useMarkdown: message.role == .assistant
                            )
                            .id(message.id)
                        }
                        if isSending {
                            HStack(spacing: 8) {
                                ProgressView()
                                Text("Pensando…")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal)
                            .id("typing")
                        }
                    }
                    .padding()
                }
                .background(AppTheme.canvas)
                .onChange(of: messages.count) { _, _ in
                    withAnimation {
                        if isSending {
                            proxy.scrollTo("typing", anchor: .bottom)
                        } else if let id = messages.last?.id {
                            proxy.scrollTo(id, anchor: .bottom)
                        }
                    }
                }
            }

            if voice.isListening {
                Text(voice.liveTranscript.isEmpty ? "Te escucho… hablá nomás" : voice.liveTranscript)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 6)
            }

            if let errorMessage {
                ScreenErrorText(message: errorMessage)
                    .padding(.horizontal)
                    .padding(.vertical, 6)
            }

            if voice.permissionDenied {
                ScreenErrorText(message: "Necesito micrófono y reconocimiento de voz para hablarte.")
                    .padding(.horizontal)
                    .padding(.bottom, 4)
            }

            HStack(alignment: .bottom, spacing: 8) {
                TextField(voice.isListening ? "Escuchando…" : "Escribí cuando quieras…", text: $draft, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...5)
                    .disabled(voice.isListening)

                Button {
                    Task { await toggleMic() }
                } label: {
                    Image(systemName: voice.isListening ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.title)
                        .foregroundStyle(voice.isListening ? AppTheme.danger : AppTheme.accentMuted)
                }
                .disabled(isSending)
                .accessibilityLabel(voice.isListening ? "Dejar de escuchar" : "Hablar con Aura")

                Button {
                    Task { await send() }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title)
                        .foregroundStyle(AppTheme.accentMuted)
                }
                .disabled(isSending || draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
            .background(.bar)
        }
        .tint(AppTheme.accentMuted)
        .navigationTitle("Aura")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showCall = true
                } label: {
                    Label("Llamar", systemImage: "phone.fill")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    voice.speakReplies.toggle()
                    if !voice.speakReplies { voice.stopSpeaking() }
                } label: {
                    Image(systemName: voice.speakReplies ? "speaker.wave.2.fill" : "speaker.slash.fill")
                }
                .accessibilityLabel(voice.speakReplies ? "Silenciar Aura" : "Que Aura hable")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Limpiar") {
                    Task { await clear() }
                }
            }
        }
        .sheet(isPresented: $showCall) {
            AuraCallSheet(personal: session.personal)
        }
        .onDisappear {
            voice.stopListening()
            voice.stopSpeaking()
        }
        .task { await bootstrap() }
    }

    private func toggleMic() async {
        errorMessage = nil
        if voice.isListening {
            voice.stopListening(keepTranscript: true)
            let spoken = voice.consumeTranscript()
            if !spoken.isEmpty {
                draft = spoken
                await send()
            }
            return
        }
        voice.stopSpeaking()
        await voice.toggleListening()
        if voice.permissionDenied {
            errorMessage = "Activá micrófono y reconocimiento de voz en Ajustes."
        }
    }

    private func bootstrap() async {
        do {
            let history = try await session.personal.auraHistory()
            messages = history.compactMap { row in
                let text = row.content.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !text.isEmpty, text != AppConfig.sessionStartMarker else { return nil }
                return ChatMessage(
                    role: row.role == "assistant" ? .assistant : .user,
                    text: text
                )
            }
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func send(prompt: String? = nil, showUser: Bool = true) async {
        let text = (prompt ?? draft).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        if prompt == nil { draft = "" }
        voice.stopListening()
        voice.stopSpeaking()
        isSending = true
        errorMessage = nil
        defer { isSending = false }
        if showUser {
            messages.append(ChatMessage(role: .user, text: text))
        }
        do {
            let response = try await session.personal.askAura(question: text, mode: "chat")
            let answer = response.answer.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !answer.isEmpty else { return }
            messages.append(ChatMessage(role: .assistant, text: answer))
            if showUser {
                voice.speak(answer)
            }
        } catch {
            if showUser, messages.last?.role == .user { messages.removeLast() }
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func clear() async {
        voice.stopSpeaking()
        do {
            try await session.personal.clearAura()
            messages = []
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}

// MARK: - Llamada (API mode=call, igual que la web)

@MainActor
@Observable
private final class AuraCallController {
    enum Status: String {
        case idle, listening, thinking, speaking, error
        var label: String {
            switch self {
            case .idle: return "Listo"
            case .listening: return "Te escucho"
            case .thinking: return "Pensando…"
            case .speaking: return "Aura habla"
            case .error: return "Error"
            }
        }
    }

    private(set) var status: Status = .idle
    private(set) var caption = ""
    private(set) var userLine = ""
    private(set) var errorMessage: String?
    private(set) var elapsed = 0

    private let personal: PersonalService
    private let voice = AuraVoiceService()
    private var live = false
    private var handling = false
    private var timer: Timer?
    private var listenTask: Task<Void, Never>?

    init(personal: PersonalService) {
        self.personal = personal
        voice.callTone = true
        voice.speakReplies = true
        voice.onSpeakFinished = { [weak self] in
            self?.scheduleListen()
        }
    }

    func start() {
        live = true
        elapsed = 0
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.elapsed += 1 }
        }
        Task { await beginListening() }
    }

    func hangUp() {
        live = false
        handling = false
        listenTask?.cancel()
        listenTask = nil
        timer?.invalidate()
        timer = nil
        voice.onSpeakFinished = nil
        voice.stopListening(keepTranscript: false)
        voice.stopSpeaking()
        status = .idle
    }

    private func scheduleListen() {
        guard live, !handling else { return }
        Task { await beginListening() }
    }

    private func beginListening() async {
        guard live, !handling else { return }
        let ok = await voice.requestPermissions()
        guard ok else {
            status = .error
            errorMessage = "Activá micrófono y reconocimiento de voz en Ajustes."
            return
        }
        status = .listening
        caption = ""
        voice.startListening(autoStopOnSilence: true)

        listenTask?.cancel()
        listenTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled && self.live && self.voice.isListening {
                try? await Task.sleep(nanoseconds: 200_000_000)
            }
            guard self.live, !Task.isCancelled else { return }
            let spoken = self.voice.consumeTranscript()
            if spoken.isEmpty {
                await self.beginListening()
            } else {
                await self.handleSpeech(spoken)
            }
        }
    }

    private func handleSpeech(_ text: String) async {
        guard live, !handling else { return }
        handling = true
        defer { handling = false }
        userLine = text
        status = .thinking
        do {
            let response = try await personal.askAura(question: text, mode: "call")
            let answer = response.answer.trimmingCharacters(in: .whitespacesAndNewlines)
            guard live else { return }
            if answer.isEmpty {
                await beginListening()
                return
            }
            caption = answer
            status = .speaking
            voice.speak(answer)
        } catch {
            guard live else { return }
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            status = .error
        }
    }
}

private struct AuraCallSheet: View {
    let personal: PersonalService
    @Environment(\.dismiss) private var dismiss
    @State private var controller: AuraCallController?

    var body: some View {
        NavigationStack {
            Group {
                if let controller {
                    callBody(controller)
                } else {
                    ProgressView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppTheme.canvas.ignoresSafeArea())
            .navigationTitle("Llamada")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") {
                        controller?.hangUp()
                        dismiss()
                    }
                }
            }
            .onAppear {
                if controller == nil {
                    let c = AuraCallController(personal: personal)
                    controller = c
                    c.start()
                }
            }
            .onDisappear {
                controller?.hangUp()
            }
        }
    }

    @ViewBuilder
    private func callBody(_ controller: AuraCallController) -> some View {
        let pulsing = controller.status == .listening || controller.status == .speaking
        VStack(spacing: 24) {
            Spacer(minLength: 12)

            Text("Aura")
                .font(.largeTitle.bold())
            Text(timeLabel(controller.elapsed))
                .font(.title3.monospacedDigit())
                .foregroundStyle(.secondary)
            Text(controller.status.label)
                .font(.headline)
                .foregroundStyle(AppTheme.accentMuted)

            ZStack {
                Circle()
                    .fill(AppTheme.accentSoftFill)
                    .frame(width: 160, height: 160)
                    .scaleEffect(pulsing ? 1.08 : 1)
                    .animation(
                        pulsing
                            ? .easeInOut(duration: 0.9).repeatForever(autoreverses: true)
                            : .default,
                        value: pulsing
                    )
                Text("A")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.accentMuted)
            }

            if !controller.userLine.isEmpty {
                Text("Vos: \(controller.userLine)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            if !controller.caption.isEmpty {
                Text(controller.caption)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            if let errorMessage = controller.errorMessage {
                ScreenErrorText(message: errorMessage)
                    .padding(.horizontal)
            }

            Spacer()

            Button(role: .destructive) {
                controller.hangUp()
                dismiss()
            } label: {
                Label("Colgar", systemImage: "phone.down.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.danger)
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
    }

    private func timeLabel(_ elapsed: Int) -> String {
        String(format: "%02d:%02d", elapsed / 60, elapsed % 60)
    }
}
