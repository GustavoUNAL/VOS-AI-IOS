import Foundation

final class JournalService {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func list() async throws -> [JournalEntry] {
        let response: JournalListResponse = try await client.request(
            "GET",
            path: "journal",
            authenticated: true,
            requiresCompany: true
        )
        return response.entries
    }

    func create(body: String) async throws -> JournalEntry {
        try await client.request(
            "POST",
            path: "journal",
            body: UpsertJournalRequest(body: body),
            authenticated: true,
            requiresCompany: true
        )
    }

    func update(id: String, body: String) async throws -> JournalEntry {
        try await client.request(
            "PATCH",
            path: "journal/\(id)",
            body: UpsertJournalRequest(body: body),
            authenticated: true,
            requiresCompany: true
        )
    }

    func delete(id: String) async throws {
        try await client.requestVoid(
            "DELETE",
            path: "journal/\(id)",
            authenticated: true,
            requiresCompany: true
        )
    }
}
