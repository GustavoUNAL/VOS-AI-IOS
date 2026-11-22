import Foundation

enum APIError: LocalizedError, Equatable {
    case invalidURL
    case unauthorized
    case forbidden(String)
    case badRequest(String)
    case server(Int, String)
    case decoding(String)
    case network(String)
    case noCompanySelected
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL del servidor inválida."
        case .unauthorized:
            return "Sesión expirada. Inicie sesión de nuevo."
        case .forbidden(let message):
            return message.isEmpty ? "Sin permiso para esta acción." : message
        case .badRequest(let message):
            return message.isEmpty ? "Solicitud inválida." : message
        case .server(let code, let message):
            return message.isEmpty ? "Error del servidor (\(code))." : message
        case .decoding(let detail):
            return "Respuesta inesperada del servidor: \(detail)"
        case .network(let detail):
            return "Sin conexión: \(detail)"
        case .noCompanySelected:
            return "Seleccione una empresa para continuar."
        case .emptyResponse:
            return "El servidor no devolvió datos."
        }
    }
}

struct APIErrorBody: Decodable {
    let message: StringOrArray?
    let hint: String?
    let code: String?

    var displayMessage: String {
        let base = message?.joined ?? ""
        if let hint, !hint.isEmpty {
            return base.isEmpty ? hint : "\(base)\n\n\(hint)"
        }
        return base
    }
}

enum StringOrArray: Decodable {
    case text(String)
    case list([String])

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let text = try? container.decode(String.self) {
            self = .text(text)
            return
        }
        if let list = try? container.decode([String].self) {
            self = .list(list)
            return
        }
        self = .text("")
    }

    var joined: String {
        switch self {
        case .text(let value): return value.trimmingCharacters(in: .whitespacesAndNewlines)
        case .list(let values): return values.joined(separator: "\n")
        }
    }
}
