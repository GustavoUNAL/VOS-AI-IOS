import Foundation

final class PlatformService {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func listCompanies() async throws -> [PlatformCompany] {
        try await client.request(
            "GET",
            path: "platform/companies",
            authenticated: true
        )
    }
}
