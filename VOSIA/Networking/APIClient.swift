import Foundation

protocol TokenProviding: AnyObject {
    var accessToken: String? { get }
    var companyId: String? { get }
    func handleUnauthorized()
}

final class APIClient: @unchecked Sendable {
    private let session: URLSession
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    weak var tokens: TokenProviding?

    init(session: URLSession = .shared) {
        self.session = session
    }

    func request<T: Decodable>(
        _ method: String,
        path: String,
        body: (any Encodable)? = nil,
        authenticated: Bool = true,
        requiresCompany: Bool = false
    ) async throws -> T {
        let data = try await rawRequest(
            method,
            path: path,
            body: body,
            authenticated: authenticated,
            requiresCompany: requiresCompany
        )
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decoding(error.localizedDescription)
        }
    }

    func requestVoid(
        _ method: String,
        path: String,
        body: (any Encodable)? = nil,
        authenticated: Bool = true,
        requiresCompany: Bool = false
    ) async throws {
        _ = try await rawRequest(
            method,
            path: path,
            body: body,
            authenticated: authenticated,
            requiresCompany: requiresCompany
        )
    }

    private func rawRequest(
        _ method: String,
        path: String,
        body: (any Encodable)?,
        authenticated: Bool,
        requiresCompany: Bool
    ) async throws -> Data {
        let cleaned = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let base = AppConfig.apiBaseURL.absoluteString.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let url = URL(string: "\(base)/\(cleaned)") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 60

        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            do {
                request.httpBody = try encoder.encode(AnyEncodable(body))
            } catch {
                throw APIError.badRequest("No se pudo serializar la solicitud.")
            }
        }

        if authenticated {
            guard let token = tokens?.accessToken, !token.isEmpty else {
                throw APIError.unauthorized
            }
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            if requiresCompany {
                guard let companyId = tokens?.companyId, !companyId.isEmpty else {
                    throw APIError.noCompanySelected
                }
                request.setValue(companyId, forHTTPHeaderField: "X-Company-Id")
            } else if let companyId = tokens?.companyId, !companyId.isEmpty {
                request.setValue(companyId, forHTTPHeaderField: "X-Company-Id")
            }
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.network(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.emptyResponse
        }

        if http.statusCode == 401 {
            await MainActor.run { tokens?.handleUnauthorized() }
            throw APIError.unauthorized
        }

        if (200..<300).contains(http.statusCode) {
            return data.isEmpty ? Data("{}".utf8) : data
        }

        let message = (try? decoder.decode(APIErrorBody.self, from: data))?.displayMessage ?? ""
        switch http.statusCode {
        case 400:
            throw APIError.badRequest(message)
        case 403:
            throw APIError.forbidden(message)
        default:
            throw APIError.server(http.statusCode, message)
        }
    }
}

private struct AnyEncodable: Encodable {
    private let encodeFunc: (Encoder) throws -> Void
    init(_ value: any Encodable) {
        encodeFunc = value.encode
    }
    func encode(to encoder: Encoder) throws {
        try encodeFunc(encoder)
    }
}
