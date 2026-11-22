import Foundation
import Observation

@MainActor
@Observable
final class OperationsViewModel {
    private let session: SessionStore

    var rows: [(key: String, value: String)] = []
    var isLoading = false
    var errorMessage: String?
    var disclaimer =
        "Estos datos vienen del endpoint /operations/day. No son una respuesta del chat de IA."

    init(session: SessionStore) {
        self.session = session
    }

    func load() async {
        guard session.companyId != nil else {
            errorMessage = APIError.noCompanySelected.errorDescription
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            let payload = try await session.operations.day()
            rows = flatten(payload)
            errorMessage = nil
        } catch {
            rows = []
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func flatten(_ object: [String: JSONValue], prefix: String = "") -> [(String, String)] {
        var result: [(String, String)] = []
        for key in object.keys.sorted() {
            let path = prefix.isEmpty ? key : "\(prefix).\(key)"
            switch object[key]! {
            case .object(let nested):
                result.append(contentsOf: flatten(nested, prefix: path))
            case .array(let values):
                result.append((path, "\(values.count) ítems"))
            default:
                result.append((path, object[key]!.display))
            }
        }
        return result
    }
}
