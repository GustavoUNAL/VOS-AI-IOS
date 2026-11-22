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
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
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
                .background(Color.red.opacity(0.08))
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
                }
                .disabled(model.isSending || model.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
            .background(.bar)
        }
        .navigationTitle(AppConfig.brandName)
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
        HStack {
            if message.role == .user { Spacer(minLength: 40) }
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                if message.role == .assistant {
                    Text("Asistente · datos del backend")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    MarkdownText(text: message.text)
                } else {
                    Text(message.text)
                }
            }
            .padding(12)
            .background(message.role == .user ? Color.accentColor.opacity(0.18) : Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            if message.role == .assistant { Spacer(minLength: 40) }
        }
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
