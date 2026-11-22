import Foundation
import Observation

@MainActor
@Observable
final class SessionStore: TokenProviding {
    private let tokenKey = "access_token"
    private let companyKey = "company_id"

    private(set) var accessToken: String?
    private(set) var companyId: String?
    private(set) var user: AuthUser?
    private(set) var isBootstrapping = true
    private(set) var lastError: String?

    let api: APIClient
    let auth: AuthService
    let assistant: AssistantService
    let journal: JournalService
    let operations: OperationsService

    /// Historial del asistente en memoria de proceso (no en servidor).
    var assistantMessages: [ChatMessage] = []
    var didStartAssistantSession = false

    init() {
        let client = APIClient()
        self.api = client
        self.auth = AuthService(client: client)
        self.assistant = AssistantService(client: client)
        self.journal = JournalService(client: client)
        self.operations = OperationsService(client: client)
        client.tokens = self
    }

    var isAuthenticated: Bool { accessToken != nil && user != nil }

    func bootstrap() async {
        isBootstrapping = true
        defer { isBootstrapping = false }
        accessToken = KeychainStore.string(forKey: tokenKey)
        companyId = KeychainStore.string(forKey: companyKey)
        guard accessToken != nil else {
            user = nil
            return
        }
        do {
            let me = try await auth.me()
            apply(session: me, token: accessToken!)
        } catch {
            clearSession()
            lastError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func login(email: String, password: String) async throws {
        lastError = nil
        let preferredCompany = companyId
        let response = try await auth.login(
            email: email,
            password: password,
            companyId: preferredCompany
        )
        persistToken(response.accessToken)
        apply(session: response.user, token: response.accessToken)
    }

    func refreshProfile() async throws {
        let me = try await auth.me()
        apply(session: me, token: accessToken ?? "")
    }

    func selectCompany(_ company: CompanySummary) async throws {
        lastError = nil
        let response: LoginResponse
        if user?.isPlatformAdmin == true {
            response = try await auth.enterCompanyAsPlatformAdmin(companyId: company.id)
        } else {
            response = try await auth.switchCompany(companyId: company.id)
        }
        persistToken(response.accessToken)
        apply(session: response.user, token: response.accessToken)
        resetAssistantConversation()
    }

    func logout() {
        clearSession()
        resetAssistantConversation()
    }

    nonisolated func handleUnauthorized() {
        Task { @MainActor in
            clearSession()
            lastError = APIError.unauthorized.errorDescription
        }
    }

    private func apply(session: AuthUser, token: String) {
        user = session
        accessToken = token
        if let id = session.activeCompanyId {
            companyId = id
            try? KeychainStore.set(id, forKey: companyKey)
        } else if session.needsCompanySelection {
            companyId = nil
            KeychainStore.delete(forKey: companyKey)
        }
    }

    private func persistToken(_ token: String) {
        accessToken = token
        try? KeychainStore.set(token, forKey: tokenKey)
    }

    private func clearSession() {
        accessToken = nil
        companyId = nil
        user = nil
        KeychainStore.delete(forKey: tokenKey)
        KeychainStore.delete(forKey: companyKey)
    }

    func resetAssistantConversation() {
        assistantMessages = []
        didStartAssistantSession = false
    }
}
