import AuthenticationServices
import Foundation
import UIKit

@MainActor
final class GoogleAuthService: NSObject {
    enum Outcome {
        case accessToken(String)
        case signup(String)
        case error(String)
    }

    private var session: ASWebAuthenticationSession?

    func signIn(apiBaseURL: URL) async throws -> Outcome {
        var components = URLComponents(
            url: apiBaseURL.appending(path: "auth/google"),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [URLQueryItem(name: "mobile", value: "1")]
        guard let url = components?.url else {
            throw APIError.invalidURL
        }

        return try await withCheckedThrowingContinuation { continuation in
            let authSession = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: "vosia"
            ) { callbackURL, error in
                if let error {
                    if let authError = error as? ASWebAuthenticationSessionError,
                       authError.code == .canceledLogin {
                        continuation.resume(throwing: CancellationError())
                        return
                    }
                    continuation.resume(throwing: APIError.network(error.localizedDescription))
                    return
                }
                guard let callbackURL else {
                    continuation.resume(throwing: APIError.emptyResponse)
                    return
                }
                do {
                    continuation.resume(returning: try Self.parse(callbackURL))
                } catch {
                    continuation.resume(throwing: error)
                }
            }
            authSession.prefersEphemeralWebBrowserSession = true
            authSession.presentationContextProvider = self
            self.session = authSession
            if !authSession.start() {
                continuation.resume(throwing: APIError.network("No se pudo abrir Google."))
            }
        }
    }

    private static func parse(_ url: URL) throws -> Outcome {
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        var map: [String: String] = [:]
        for item in items {
            if let value = item.value, !value.isEmpty {
                map[item.name] = value
            }
        }
        if let token = map["access_token"] {
            return .accessToken(token)
        }
        if let signup = map["google_signup"] {
            return .signup(signup)
        }
        if let error = map["google_error"] {
            return .error(error)
        }
        throw APIError.badRequest("Respuesta de Google incompleta.")
    }
}

extension GoogleAuthService: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        if let window = scenes.flatMap(\.windows).first(where: \.isKeyWindow) {
            return window
        }
        return scenes.flatMap(\.windows).first ?? ASPresentationAnchor()
    }
}
