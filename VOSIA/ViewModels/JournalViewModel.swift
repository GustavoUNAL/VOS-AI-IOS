import Foundation
import Observation

@MainActor
@Observable
final class JournalViewModel {
    private let session: SessionStore

    var entries: [JournalEntry] = []
    var draft = ""
    var editingId: String?
    var status = "Listo para escribir"
    var errorMessage: String?
    var isLoading = false
    var isSaving = false

    private var saveTask: Task<Void, Never>?

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
            entries = try await session.journal.list()
            errorMessage = nil
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func scheduleAutosave() {
        saveTask?.cancel()
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        status = "Escribiendo…"
        saveTask = Task {
            try? await Task.sleep(nanoseconds: 900_000_000)
            guard !Task.isCancelled else { return }
            await persist(text)
        }
    }

    func startNew() {
        saveTask?.cancel()
        editingId = nil
        draft = ""
        status = "Nueva nota"
        errorMessage = nil
    }

    func open(_ entry: JournalEntry) {
        saveTask?.cancel()
        editingId = entry.id
        draft = entry.body
        status = "Nota de \(entry.authorName)"
        errorMessage = nil
    }

    func delete(_ entry: JournalEntry) async {
        do {
            try await session.journal.delete(id: entry.id)
            entries.removeAll { $0.id == entry.id }
            if editingId == entry.id { startNew() }
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func persist(_ text: String) async {
        isSaving = true
        status = "Guardando…"
        defer { isSaving = false }
        do {
            let saved: JournalEntry
            if let id = editingId {
                saved = try await session.journal.update(id: id, body: text)
            } else {
                saved = try await session.journal.create(body: text)
                editingId = saved.id
            }
            entries.removeAll { $0.id == saved.id }
            entries.insert(saved, at: 0)
            status = "Guardado en esta empresa"
            errorMessage = nil
        } catch {
            status = "Sin guardar"
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}
