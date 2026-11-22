import Foundation

final class PersonalService {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func overview() async throws -> PersonalOverview {
        try await client.request("GET", path: "personal/overview", authenticated: true, requiresCompany: true)
    }

    func listMoney() async throws -> PersonalMoneyListResponse {
        try await client.request("GET", path: "personal/money", authenticated: true, requiresCompany: true)
    }

    func createMoney(_ body: UpsertPersonalMoneyRequest) async throws -> PersonalMoneyEntry {
        try await client.request("POST", path: "personal/money", body: body, authenticated: true, requiresCompany: true)
    }

    func deleteMoney(id: String) async throws {
        try await client.requestVoid("DELETE", path: "personal/money/\(id)", authenticated: true, requiresCompany: true)
    }

    func listBudgets(month: String) async throws -> PersonalMoneyBudgetListResponse {
        try await client.request("GET", path: "personal/money/budgets?month=\(month)", authenticated: true, requiresCompany: true)
    }

    func upsertBudget(_ body: UpsertPersonalMoneyBudgetRequest) async throws -> PersonalMoneyBudget {
        try await client.request("PUT", path: "personal/money/budgets", body: body, authenticated: true, requiresCompany: true)
    }

    func listCalendar(from: String?, to: String?) async throws -> [PersonalCalendarEvent] {
        var path = "personal/calendar"
        var q: [String] = []
        if let from, !from.isEmpty { q.append("from=\(from)") }
        if let to, !to.isEmpty { q.append("to=\(to)") }
        if !q.isEmpty { path += "?\(q.joined(separator: "&"))" }
        let response: PersonalCalendarListResponse = try await client.request("GET", path: path, authenticated: true, requiresCompany: true)
        return response.events
    }

    func createCalendar(_ body: UpsertPersonalCalendarRequest) async throws -> PersonalCalendarEvent {
        try await client.request("POST", path: "personal/calendar", body: body, authenticated: true, requiresCompany: true)
    }

    func deleteCalendar(id: String) async throws {
        try await client.requestVoid("DELETE", path: "personal/calendar/\(id)", authenticated: true, requiresCompany: true)
    }

    func listIdeas() async throws -> [PersonalIdea] {
        let response: PersonalIdeaListResponse = try await client.request("GET", path: "personal/ideas", authenticated: true, requiresCompany: true)
        return response.ideas
    }

    func createIdea(_ body: UpsertPersonalIdeaRequest) async throws -> PersonalIdea {
        try await client.request("POST", path: "personal/ideas", body: body, authenticated: true, requiresCompany: true)
    }

    func deleteIdea(id: String) async throws {
        try await client.requestVoid("DELETE", path: "personal/ideas/\(id)", authenticated: true, requiresCompany: true)
    }

    func listWellness() async throws -> WellnessListResponse {
        try await client.request("GET", path: "personal/wellness", authenticated: true, requiresCompany: true)
    }

    func upsertWellness(_ body: UpsertWellnessRequest) async throws -> WellnessCheckIn {
        try await client.request("PUT", path: "personal/wellness", body: body, authenticated: true, requiresCompany: true)
    }

    func vicenteHistory() async throws -> [VicenteMessage] {
        let response: VicenteHistoryResponse = try await client.request("GET", path: "personal/vicente/history", authenticated: true, requiresCompany: true)
        return response.messages
    }

    func askVicente(question: String) async throws -> VicenteAskResponse {
        try await client.request(
            "POST",
            path: "personal/vicente/ask",
            body: VicenteAskRequest(question: question),
            authenticated: true,
            requiresCompany: true
        )
    }

    func clearVicente() async throws {
        try await client.requestVoid("DELETE", path: "personal/vicente/history", authenticated: true, requiresCompany: true)
    }

    func listTasks(date: String) async throws -> [TaskItem] {
        let response: TaskListResponse = try await client.request("GET", path: "tasks?date=\(date)", authenticated: true, requiresCompany: true)
        return response.tasks
    }

    func createTask(_ body: CreateTaskRequest) async throws -> TaskItem {
        try await client.request("POST", path: "tasks", body: body, authenticated: true, requiresCompany: true)
    }

    func updateTask(id: String, _ body: UpdateTaskRequest) async throws -> TaskItem {
        try await client.request("PATCH", path: "tasks/\(id)", body: body, authenticated: true, requiresCompany: true)
    }

    func deleteTask(id: String) async throws {
        try await client.requestVoid("DELETE", path: "tasks/\(id)", authenticated: true, requiresCompany: true)
    }
}

private struct VicenteAskRequest: Encodable {
    let question: String
}
