import Foundation

enum PersonalMoneyKind: String, Codable, CaseIterable, Identifiable {
    case INCOME
    case EXPENSE
    var id: String { rawValue }
    var label: String { self == .INCOME ? "Ingreso" : "Gasto" }
}

struct PersonalMoneyEntry: Codable, Identifiable, Hashable {
    let id: String
    let kind: PersonalMoneyKind
    let amountCOP: Double
    let category: String
    let note: String?
    let occurredOn: String
    let createdAt: String
    let updatedAt: String
    let authorId: String
    let authorName: String
}

struct PersonalMoneySummary: Codable, Hashable {
    let incomeCOP: Double
    let expenseCOP: Double
    let balanceCOP: Double
}

struct PersonalMoneyCategoryBreakdown: Codable, Hashable {
    let category: String
    let incomeCOP: Double
    let expenseCOP: Double
}

struct PersonalMoneyListResponse: Codable {
    let entries: [PersonalMoneyEntry]
    let summary: PersonalMoneySummary
    let byCategory: [PersonalMoneyCategoryBreakdown]?
}

struct UpsertPersonalMoneyRequest: Encodable {
    let kind: String
    let amountCOP: Double
    let category: String
    let note: String?
    let occurredOn: String
}

struct PersonalMoneyBudget: Codable, Identifiable, Hashable {
    let id: String
    let category: String
    let limitCOP: Double
    let spentCOP: Double?
    let remainingCOP: Double?
}

struct PersonalMoneyBudgetListResponse: Codable {
    let month: String
    let budgets: [PersonalMoneyBudget]
}

struct UpsertPersonalMoneyBudgetRequest: Encodable {
    let category: String
    let month: String
    let limitCOP: Double
}

struct PersonalCalendarEvent: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let notes: String?
    let startsAt: String
    let endsAt: String
    let allDay: Bool
    let createdAt: String
    let updatedAt: String
    let authorId: String
    let authorName: String
}

struct PersonalCalendarListResponse: Codable {
    let events: [PersonalCalendarEvent]
}

struct UpsertPersonalCalendarRequest: Encodable {
    let title: String
    let notes: String?
    let startsAt: String
    let endsAt: String
    let allDay: Bool
}

struct PersonalIdea: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let body: String
    let tags: [String]
    let starred: Bool
    let createdAt: String
    let updatedAt: String
    let authorId: String
    let authorName: String
}

struct PersonalIdeaListResponse: Codable {
    let ideas: [PersonalIdea]
}

struct UpsertPersonalIdeaRequest: Encodable {
    let title: String
    let body: String
    let tags: [String]
    let starred: Bool
}

struct WellnessCheckIn: Codable, Identifiable, Hashable {
    let id: String
    let mood: Int
    let health: Int
    let love: Int
    let friendships: Int
    let family: Int
    let note: String?
    let checkedOn: String
    let createdAt: String
}

struct WellnessGraphNode: Codable, Identifiable, Hashable {
    let id: String
    let label: String
    let value: Int
}

struct WellnessGraphEdge: Codable, Hashable {
    let from: String
    let to: String
    let weight: Double
}

struct WellnessGraph: Codable, Hashable {
    let nodes: [WellnessGraphNode]
    let edges: [WellnessGraphEdge]
}

struct WellnessListResponse: Codable {
    let checkIns: [WellnessCheckIn]
    let graph: WellnessGraph
}

struct UpsertWellnessRequest: Encodable {
    let mood: Int
    let health: Int
    let love: Int
    let friendships: Int
    let family: Int
    let note: String?
    let checkedOn: String?
}

struct PersonalOverview: Codable {
    let money: PersonalMoneySummary
    let ideasCount: Int
    let notesCount: Int
    let pendingTasksToday: Int
    let upcomingEvents: Int
    let latestWellness: WellnessCheckIn?
    let graph: WellnessGraph?
}

struct AuraMessage: Codable, Identifiable, Hashable {
    let id: String
    let role: String
    let content: String
    let createdAt: String
}

struct AuraHistoryResponse: Codable {
    let messages: [AuraMessage]
    let assistantName: String?
}

struct AuraAskResponse: Codable {
    let answer: String
    let assistantName: String?
    let engine: String?
}

typealias VicenteMessage = AuraMessage
typealias VicenteHistoryResponse = AuraHistoryResponse
typealias VicenteAskResponse = AuraAskResponse


struct TaskItem: Codable, Identifiable, Hashable {
    let id: String
    let taskDate: String
    let title: String
    let description: String?
    let completed: Bool
}

struct TaskListResponse: Codable {
    let taskDate: String?
    let tasks: [TaskItem]
}

struct CreateTaskRequest: Encodable {
    let taskDate: String
    let title: String
    let description: String?
}

struct UpdateTaskRequest: Encodable {
    let title: String?
    let description: String?
    let completed: Bool?
}
