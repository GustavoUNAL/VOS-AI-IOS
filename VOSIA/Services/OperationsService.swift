import Foundation

/// Resumen operativo del día — GET /operations/day (mismo endpoint que la web).
struct OperationsDayResponse: Codable {
    // Campos flexibles: el backend puede ampliar la forma.
    // Decodificamos lo esencial sin inventar cifras.
    let date: String?
    let salesCount: Int?
    let salesTotal: Double?
    let message: String?
}

final class OperationsService {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func day() async throws -> [String: JSONValue] {
        try await client.request(
            "GET",
            path: "operations/day",
            authenticated: true,
            requiresCompany: true
        )
    }
}

enum JSONValue: Codable, Hashable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case object([String: JSONValue])
    case array([JSONValue])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([String: JSONValue].self) {
            self = .object(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else {
            self = .null
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value): try container.encode(value)
        case .number(let value): try container.encode(value)
        case .bool(let value): try container.encode(value)
        case .object(let value): try container.encode(value)
        case .array(let value): try container.encode(value)
        case .null: try container.encodeNil()
        }
    }

    var display: String {
        switch self {
        case .string(let value): return value
        case .number(let value):
            if value.rounded() == value { return String(Int(value)) }
            return String(value)
        case .bool(let value): return value ? "sí" : "no"
        case .null: return "—"
        case .object, .array: return "…"
        }
    }
}
