import SwiftUI

struct PersonalCalendarView: View {
    @Environment(SessionStore.self) private var session
    @State private var events: [PersonalCalendarEvent] = []
    @State private var title = ""
    @State private var notes = ""
    @State private var startsAt = Date()
    @State private var endsAt = Date().addingTimeInterval(3600)
    @State private var errorMessage: String?
    @State private var statusMessage: String?
    @State private var isLoading = false
    @State private var deviceCalendar = DeviceCalendarService()

    var body: some View {
        List {
            Section {
                Text("Agenda personal en la base de datos. Podés exportar cada evento al Calendario del iPhone.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Nuevo evento") {
                TextField("Título", text: $title)
                TextField("Notas", text: $notes)
                DatePicker("Inicio", selection: $startsAt)
                DatePicker("Fin", selection: $endsAt)
                Button("Guardar en VOS IA") {
                    Task { await save() }
                }
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
            }

            if let errorMessage {
                Section { Text(errorMessage).foregroundStyle(.red) }
            }
            if let statusMessage {
                Section { Text(statusMessage).foregroundStyle(.secondary) }
            }

            Section("Próximos") {
                if isLoading && events.isEmpty {
                    ProgressView()
                } else if events.isEmpty {
                    Text("Sin eventos.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(events) { event in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(event.title).font(.headline)
                            Text("\(short(event.startsAt)) → \(short(event.endsAt))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if let notes = event.notes, !notes.isEmpty {
                                Text(notes).font(.footnote)
                            }
                            Button("Exportar al Calendario") {
                                Task { await export(event) }
                            }
                            .font(.caption.weight(.semibold))
                        }
                        .padding(.vertical, 2)
                        .swipeActions {
                            Button("Borrar", role: .destructive) {
                                Task { await remove(event) }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Calendario")
        .task { await load() }
        .refreshable { await load() }
    }

    private func short(_ iso: String) -> String {
        guard let date = ISO8601DateFormatter.vos.parse(iso) else { return iso }
        return date.formatted(date: .abbreviated, time: .shortened)
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            events = try await session.personal.listCalendar(from: nil, to: nil)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func save() async {
        isLoading = true
        errorMessage = nil
        statusMessage = nil
        defer { isLoading = false }
        do {
            let iso = ISO8601DateFormatter()
            iso.formatOptions = [.withInternetDateTime]
            _ = try await session.personal.createCalendar(
                UpsertPersonalCalendarRequest(
                    title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                    notes: notes.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
                    startsAt: iso.string(from: startsAt),
                    endsAt: iso.string(from: endsAt),
                    allDay: false
                )
            )
            title = ""
            notes = ""
            await load()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func export(_ event: PersonalCalendarEvent) async {
        do {
            try await deviceCalendar.export(event: event)
            statusMessage = "Evento copiado al Calendario del iPhone."
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func remove(_ event: PersonalCalendarEvent) async {
        do {
            try await session.personal.deleteCalendar(id: event.id)
            await load()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}

private extension String {
    var nilIfEmpty: String? {
        let t = trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }
}
