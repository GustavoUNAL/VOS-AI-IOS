import SwiftUI

struct AuraChatView: View {
    @Environment(SessionStore.self) private var session
    @State private var draft = ""
    @State private var messages: [ChatMessage] = []
    @State private var isSending = false
    @State private var errorMessage: String?
    @State private var voice = AuraVoiceService()

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
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
                                Text("Aura está pensando…")
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
                TextField(voice.isListening ? "Escuchando…" : "Escribí o hablá con Aura…", text: $draft, axis: .vertical)
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
            messages = history.map {
                ChatMessage(
                    role: $0.role == "assistant" ? .assistant : .user,
                    text: $0.content
                )
            }
            if messages.isEmpty {
                await send(prompt: AppConfig.sessionStartMarker, showUser: false)
            } else if let last = messages.last, last.role == .assistant {
                // No releer todo el historial al abrir; solo silencio.
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
            let response = try await session.personal.askAura(question: text)
            messages.append(ChatMessage(role: .assistant, text: response.answer))
            if showUser || prompt == AppConfig.sessionStartMarker {
                voice.speak(response.answer)
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
            await send(prompt: AppConfig.sessionStartMarker, showUser: false)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}
