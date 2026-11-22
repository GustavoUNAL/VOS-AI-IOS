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
    private(set) var platformCompanies: [PlatformCompany] = []

    let api: APIClient
    let auth: AuthService
    let assistant: AssistantService
    let journal: JournalService
    let operations: OperationsService
    let platform: PlatformService

    /// Historial del asistente en memoria de dispositivo (no en servidor).
    var assistantMessages: [ChatMessage] = []
    var didStartAssistantSession = false

    init() {
        let client = APIClient()
        self.api = client
        self.auth = AuthService(client: client)
        self.assistant = AssistantService(client: client)
        self.journal = JournalService(client: client)
        self.operations = OperationsService(client: client)
        self.platform = PlatformService(client: client)
        client.tokens = self
    }

    var isAuthenticated: Bool { accessToken != nil && user != nil }

    var isPlatformHome: Bool {
        guard let user else { return false }
        if user.isPlatformAdmin == true, user.platformView == true { return true }
        return user.isPlatformAdmin == true && companyId == nil
    }

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
            if isPlatformHome {
                try? await refreshPlatformCompanies()
            }
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
        if isPlatformHome {
            try await refreshPlatformCompanies()
        }
    }

    func completeGoogleSignIn(accessToken: String) async throws {
        lastError = nil
        persistToken(accessToken)
        let me = try await auth.me()
        apply(session: me, token: accessToken)
        if isPlatformHome {
            try await refreshPlatformCompanies()
        }
    }

    func refreshProfile() async throws {
        let me = try await auth.me()
        apply(session: me, token: accessToken ?? "")
    }

    func refreshPlatformCompanies() async throws {
        platformCompanies = try await platform.listCompanies()
            .filter { ($0.status ?? "ACTIVE").uppercased() == "ACTIVE" }
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

    func returnToPlatformHome() async throws {
        lastError = nil
        let response = try await auth.returnToPlatformHome()
        persistToken(response.accessToken)
        apply(session: response.user, token: response.accessToken)
        resetAssistantConversation()
        try await refreshPlatformCompanies()
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
        } else if session.needsCompanySelection || session.isPlatformAdmin == true {
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
        platformCompanies = []
        KeychainStore.delete(forKey: tokenKey)
        KeychainStore.delete(forKey: companyKey)
    }

    func resetAssistantConversation() {
        assistantMessages = []
        didStartAssistantSession = false
    }
}
