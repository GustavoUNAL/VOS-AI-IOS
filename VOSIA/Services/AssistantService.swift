import Foundation

/// Cliente del motor de IA existente. No llama a OpenAI directamente.
final class AssistantService {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    /// Contrato idéntico a la web: question + history opcional → { answer }.
    func ask(question: String, history: [AssistantHistoryItem]?) async throws -> String {
        let trimmedHistory = history.map { items in
            Array(items.suffix(AppConfig.maxHistoryItems))
        }
        let response: AskAssistantResponse = try await client.request(
            "POST",
            path: "assistant/ask",
            body: AskAssistantRequest(question: question, history: trimmedHistory),
            authenticated: true,
            requiresCompany: true
        )
        return response.answer
    }
}
