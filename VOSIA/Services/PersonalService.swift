import Foundation

final class PersonalService {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func listMoney() async throws -> PersonalMoneyListResponse {
        try await client.request(
            "GET",
            path: "personal/money",
            authenticated: true,
            requiresCompany: true
        )
    }

    func createMoney(_ body: UpsertPersonalMoneyRequest) async throws -> PersonalMoneyEntry {
        try await client.request(
            "POST",
            path: "personal/money",
            body: body,
            authenticated: true,
            requiresCompany: true
        )
    }

    func deleteMoney(id: String) async throws {
        try await client.requestVoid(
            "DELETE",
            path: "personal/money/\(id)",
            authenticated: true,
            requiresCompany: true
        )
    }

    func listCalendar(from: String?, to: String?) async throws -> [PersonalCalendarEvent] {
        var path = "personal/calendar"
        var q: [String] = []
        if let from, !from.isEmpty { q.append("from=\(from)") }
        if let to, !to.isEmpty { q.append("to=\(to)") }
        if !q.isEmpty { path += "?\(q.joined(separator: "&"))" }
        let response: PersonalCalendarListResponse = try await client.request(
            "GET",
            path: path,
            authenticated: true,
            requiresCompany: true
        )
        return response.events
    }

    func createCalendar(_ body: UpsertPersonalCalendarRequest) async throws -> PersonalCalendarEvent {
        try await client.request(
            "POST",
            path: "personal/calendar",
            body: body,
            authenticated: true,
            requiresCompany: true
        )
    }

    func deleteCalendar(id: String) async throws {
        try await client.requestVoid(
            "DELETE",
            path: "personal/calendar/\(id)",
            authenticated: true,
            requiresCompany: true
        )
    }

    func listTasks(date: String) async throws -> [TaskItem] {
        let response: TaskListResponse = try await client.request(
            "GET",
            path: "tasks?date=\(date)",
            authenticated: true,
            requiresCompany: true
        )
        return response.tasks
    }

    func createTask(_ body: CreateTaskRequest) async throws -> TaskItem {
        try await client.request(
            "POST",
            path: "tasks",
            body: body,
            authenticated: true,
            requiresCompany: true
        )
    }

    func updateTask(id: String, _ body: UpdateTaskRequest) async throws -> TaskItem {
        try await client.request(
            "PATCH",
            path: "tasks/\(id)",
            body: body,
            authenticated: true,
            requiresCompany: true
        )
    }

    func deleteTask(id: String) async throws {
        try await client.requestVoid(
            "DELETE",
            path: "tasks/\(id)",
            authenticated: true,
            requiresCompany: true
        )
    }
}
