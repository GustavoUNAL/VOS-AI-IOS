import Foundation

enum PersonalMoneyKind: String, Codable, CaseIterable, Identifiable {
    case INCOME
    case EXPENSE

    var id: String { rawValue }

    var label: String {
        switch self {
        case .INCOME: return "Ingreso"
        case .EXPENSE: return "Gasto"
        }
    }
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

struct PersonalMoneyListResponse: Codable {
    let entries: [PersonalMoneyEntry]
    let summary: PersonalMoneySummary
}

struct UpsertPersonalMoneyRequest: Encodable {
    let kind: String
    let amountCOP: Double
    let category: String
    let note: String?
    let occurredOn: String
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
