import SwiftUI

struct AssistantChatView: View {
    @Environment(SessionStore.self) private var session
    @State private var model: AssistantViewModel?
    @State private var scrollProxy: ScrollViewProxy?

    var body: some View {
        Group {
            if let model {
                chat(model)
            } else {
                ProgressView("Preparando asistente…")
            }
        }
        .task {
            if model == nil {
                model = AssistantViewModel(session: session)
            }
            await model?.ensureSessionStarted()
        }
    }

    @ViewBuilder
    private func chat(_ model: AssistantViewModel) -> some View {
        @Bindable var model = model
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(model.messages) { message in
                            bubble(message)
                                .id(message.id)
                        }
                        if model.isSending {
                            HStack(spacing: 8) {
                                ProgressView()
                                Text("Consultando el motor de IA…")
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
                .onChange(of: model.messages.count) { _, _ in
                    scrollToBottom(proxy)
                }
                .onChange(of: model.isSending) { _, sending in
                    if sending { scrollToBottom(proxy) }
                }
                .onAppear { scrollProxy = proxy }
            }

            if let error = model.errorMessage {
                VStack(alignment: .leading, spacing: 8) {
                    ScreenErrorText(message: error)
                    if model.lastFailedPrompt != nil {
                        Button("Reintentar") {
                            Task { await model.retryLast() }
                        }
                        .font(.footnote.weight(.semibold))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(AppTheme.danger.opacity(0.08))
            }

            HStack(alignment: .bottom, spacing: 10) {
                TextField("Pregunte sobre su negocio…", text: $model.draft, axis: .vertical)
                    .lineLimit(1...5)
                    .textFieldStyle(.roundedBorder)
                    .disabled(model.isSending)
                Button {
                    Task { await model.sendCurrentDraft() }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title)
                        .foregroundStyle(AppTheme.accentMuted)
                }
                .disabled(model.isSending || model.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
            .background(.bar)
        }
        .tint(AppTheme.accentMuted)
        .navigationTitle("Asistente")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Nueva") {
                    session.resetAssistantConversation()
                    Task { await model.ensureSessionStarted() }
                }
            }
        }
    }

    private func bubble(_ message: ChatMessage) -> some View {
        ChatBubble(
            isUser: message.role == .user,
            authorLabel: message.role == .assistant ? "Asistente" : "Vos",
            text: message.text,
            useMarkdown: message.role == .assistant
        )
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        DispatchQueue.main.async {
            withAnimation(.easeOut(duration: 0.2)) {
                if let last = model?.messages.last {
                    proxy.scrollTo(last.id, anchor: .bottom)
                } else {
                    proxy.scrollTo("typing", anchor: .bottom)
                }
            }
        }
    }
}
