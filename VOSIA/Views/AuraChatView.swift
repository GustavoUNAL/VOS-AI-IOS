import SwiftUI

struct AuraChatView: View {
    @Environment(SessionStore.self) private var session
    @State private var draft = ""
    @State private var messages: [ChatMessage] = []
    @State private var isSending = false
    @State private var errorMessage: String?

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

            if let errorMessage {
                ScreenErrorText(message: errorMessage)
                    .padding(.horizontal)
                    .padding(.vertical, 6)
            }

            HStack(alignment: .bottom, spacing: 8) {
                TextField("Hablá con Aura…", text: $draft, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...5)
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
                Button("Limpiar") {
                    Task { await clear() }
                }
            }
        }
        .task { await bootstrap() }
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
            }
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func send(prompt: String? = nil, showUser: Bool = true) async {
        let text = (prompt ?? draft).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        if prompt == nil { draft = "" }
        isSending = true
        errorMessage = nil
        defer { isSending = false }
        if showUser {
            messages.append(ChatMessage(role: .user, text: text))
        }
        do {
            let response = try await session.personal.askAura(question: text)
            messages.append(ChatMessage(role: .assistant, text: response.answer))
        } catch {
            if showUser, messages.last?.role == .user { messages.removeLast() }
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func clear() async {
        do {
            try await session.personal.clearAura()
            messages = []
            await send(prompt: AppConfig.sessionStartMarker, showUser: false)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}
