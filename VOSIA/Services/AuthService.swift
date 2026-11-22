import Foundation

final class AuthService {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func login(email: String, password: String, companyId: String?) async throws -> LoginResponse {
        let body = LoginRequest(
            email: email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
            password: password,
            companyId: companyId?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        )
        return try await client.request(
            "POST",
            path: "auth/login",
            body: body,
            authenticated: false
        )
    }

    func me() async throws -> AuthUser {
        try await client.request("GET", path: "auth/me", authenticated: true)
    }

    func switchCompany(companyId: String) async throws -> LoginResponse {
        try await client.request(
            "POST",
            path: "auth/switch-company",
            body: SwitchCompanyRequest(companyId: companyId),
            authenticated: true
        )
    }

    func enterCompanyAsPlatformAdmin(companyId: String) async throws -> LoginResponse {
        try await client.request(
            "POST",
            path: "auth/platform/enter-company",
            body: SwitchCompanyRequest(companyId: companyId),
            authenticated: true
        )
    }
}

private extension String {
    var nilIfEmpty: String? {
        let t = trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }
}
