import Foundation

final class ProjectsService {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func list(status: ServiceProjectStatus? = nil) async throws -> ServiceProjectsResponse {
        var path = "projects"
        if let status {
            path += "?status=\(status.rawValue)"
        }
        return try await client.request(
            "GET",
            path: path,
            authenticated: true,
            requiresCompany: true
        )
    }

    func create(_ body: UpsertServiceProjectRequest) async throws -> ServiceProject {
        try await client.request(
            "POST",
            path: "projects",
            body: body,
            authenticated: true,
            requiresCompany: true
        )
    }

    func update(id: String, _ body: UpsertServiceProjectRequest) async throws -> ServiceProject {
        try await client.request(
            "PATCH",
            path: "projects/\(id)",
            body: body,
            authenticated: true,
            requiresCompany: true
        )
    }

    func delete(id: String) async throws {
        try await client.requestVoid(
            "DELETE",
            path: "projects/\(id)",
            authenticated: true,
            requiresCompany: true
        )
    }
}
