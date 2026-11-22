import Foundation
import Observation

@MainActor
@Observable
final class AssistantViewModel {
    private let session: SessionStore

    var draft = ""
    var isSending = false
    var errorMessage: String?
    var lastFailedPrompt: String?

    init(session: SessionStore) {
        self.session = session
    }

    var messages: [ChatMessage] { session.assistantMessages }

    func ensureSessionStarted() async {
        guard session.companyId != nil else { return }
        guard !session.didStartAssistantSession else { return }
        session.didStartAssistantSession = true
        await send(prompt: AppConfig.sessionStartMarker, showUserBubble: false)
    }

    func sendCurrentDraft() async {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        draft = ""
        await send(prompt: text, showUserBubble: true)
    }

    func retryLast() async {
        guard let prompt = lastFailedPrompt else { return }
        await send(prompt: prompt, showUserBubble: true)
    }

    private func send(prompt: String, showUserBubble: Bool) async {
        guard !isSending else { return }
        guard session.companyId != nil else {
            errorMessage = APIError.noCompanySelected.errorDescription
            return
        }

        isSending = true
        errorMessage = nil
        lastFailedPrompt = nil
        defer { isSending = false }

        if showUserBubble {
            session.assistantMessages.append(ChatMessage(role: .user, text: prompt))
        }

        let historyPayload = buildHistoryPayload(excludingPendingUser: showUserBubble)

        do {
            let answer = try await session.assistant.ask(
                question: prompt,
                history: historyPayload
            )
            session.assistantMessages.append(ChatMessage(role: .assistant, text: answer))
        } catch {
            if showUserBubble, let last = session.assistantMessages.last, last.role == .user {
                session.assistantMessages.removeLast()
            }
            if prompt == AppConfig.sessionStartMarker {
                session.didStartAssistantSession = false
            }
            lastFailedPrompt = showUserBubble ? prompt : nil
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    /// Misma forma que la web: turnos previos user/assistant, sin el marcador de sesión.
    private func buildHistoryPayload(excludingPendingUser: Bool) -> [AssistantHistoryItem] {
        var items: [AssistantHistoryItem] = []
        for message in session.assistantMessages {
            if message.text == AppConfig.sessionStartMarker { continue }
            switch message.role {
            case .user:
                items.append(.user(message.text))
            case .assistant:
                items.append(.assistant(message.text))
            }
        }
        if excludingPendingUser, items.last?.role == "user" {
            items.removeLast()
        }
        return Array(items.suffix(AppConfig.maxHistoryItems))
    }
}
