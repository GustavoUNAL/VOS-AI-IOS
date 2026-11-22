import Foundation

struct AssistantHistoryItem: Codable, Hashable {
    let role: String
    let content: String

    static func user(_ text: String) -> AssistantHistoryItem {
        AssistantHistoryItem(role: "user", content: text)
    }

    static func assistant(_ text: String) -> AssistantHistoryItem {
        AssistantHistoryItem(role: "assistant", content: text)
    }
}

struct AskAssistantRequest: Encodable {
    let question: String
    let history: [AssistantHistoryItem]?
}

struct AskAssistantResponse: Codable {
    let answer: String
}

struct ChatMessage: Identifiable, Hashable {
    let id: UUID
    let role: Role
    let text: String
    let createdAt: Date

    enum Role: String, Hashable {
        case user
        case assistant
    }

    init(id: UUID = UUID(), role: Role, text: String, createdAt: Date = Date()) {
        self.id = id
        self.role = role
        self.text = text
        self.createdAt = createdAt
    }
}
