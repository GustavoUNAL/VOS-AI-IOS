import SwiftUI

struct VicenteChatView: View {
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
                            bubble(message).id(message.id)
                        }
                        if isSending {
                            HStack(spacing: 8) {
                                ProgressView()
                                Text("Vicente está pensando…")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal)
                            .id("typing")
                        }
                    }
                    .padding()
                }
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
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
            }

            HStack(alignment: .bottom, spacing: 8) {
                TextField("Hablá con Vicente…", text: $draft, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...5)
                Button {
                    Task { await send() }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title)
                }
                .disabled(isSending || draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
        }
        .navigationTitle("Vicente")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Limpiar") {
                    Task { await clear() }
                }
            }
        }
        .task { await bootstrap() }
    }

    private func bubble(_ message: ChatMessage) -> some View {
        HStack {
            if message.role == .user { Spacer(minLength: 40) }
            VStack(alignment: .leading, spacing: 4) {
                Text(message.role == .assistant ? "Vicente" : "Vos")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                MarkdownText(text: message.text)
            }
            .padding(12)
            .background(
                message.role == .assistant
                    ? AppTheme.card
                    : AppTheme.accentSoftFill
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(AppTheme.hairline, lineWidth: 0.5)
            )
            if message.role == .assistant { Spacer(minLength: 40) }
        }
    }

    private func bootstrap() async {
        do {
            let history = try await session.personal.vicenteHistory()
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
            let response = try await session.personal.askVicente(question: text)
            messages.append(ChatMessage(role: .assistant, text: response.answer))
        } catch {
            if showUser, messages.last?.role == .user { messages.removeLast() }
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func clear() async {
        do {
            try await session.personal.clearVicente()
            messages = []
            await send(prompt: AppConfig.sessionStartMarker, showUser: false)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}
