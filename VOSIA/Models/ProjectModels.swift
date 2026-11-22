import Foundation

enum ServiceProjectStatus: String, Codable, CaseIterable, Identifiable {
    case IN_PROGRESS
    case COMPLETED
    case CANCELLED

    var id: String { rawValue }

    var label: String {
        switch self {
        case .IN_PROGRESS: return "En ejecución"
        case .COMPLETED: return "Cobrado"
        case .CANCELLED: return "Cancelado"
        }
    }
}

struct ServiceProject: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let address: String
    let description: String
    let chargedAmount: Double
    let status: ServiceProjectStatus
    let notes: String?
    let createdAt: String
    let updatedAt: String
}

struct ServiceProjectsSummary: Codable, Hashable {
    let total: Int
    let inProgress: Int
    let completed: Int
    let chargedTotal: Double
}

struct ServiceProjectsResponse: Codable {
    let projects: [ServiceProject]
    let summary: ServiceProjectsSummary
}

struct UpsertServiceProjectRequest: Encodable {
    let name: String
    let address: String
    let description: String?
    let chargedAmount: Double
    let status: String
    let notes: String?
}
