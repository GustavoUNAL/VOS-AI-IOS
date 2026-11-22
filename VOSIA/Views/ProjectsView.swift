import SwiftUI

struct ProjectsView: View {
    @Environment(SessionStore.self) private var session
    @State private var projects: [ServiceProject] = []
    @State private var summary: ServiceProjectsSummary?
    @State private var filter: ServiceProjectStatus? = nil
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var showForm = false
    @State private var editing: ServiceProject?
    @State private var formName = ""
    @State private var formAddress = ""
    @State private var formDescription = ""
    @State private var formAmount = ""
    @State private var formStatus: ServiceProjectStatus = .IN_PROGRESS
    @State private var formNotes = ""

    var body: some View {
        List {
            Section {
                Text("Obras y servicios: historial, estado y cobro. Es el núcleo operativo de El electricista.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if let summary {
                Section("Resumen") {
                    LabeledContent("Proyectos", value: "\(summary.total)")
                    LabeledContent("En ejecución", value: "\(summary.inProgress)")
                    LabeledContent("Cobrados", value: "\(summary.completed)")
                    LabeledContent("Total cobrado", value: money(summary.chargedTotal))
                }
            }

            Section("Filtro") {
                Picker("Estado", selection: $filter) {
                    Text("Todos").tag(Optional<ServiceProjectStatus>.none)
                    ForEach(ServiceProjectStatus.allCases) { status in
                        Text(status.label).tag(Optional(status))
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: filter) { _, _ in
                    Task { await load() }
                }
            }

            if let errorMessage {
                Section { Text(errorMessage).foregroundStyle(.red) }
            }

            Section("Historial") {
                if isLoading && projects.isEmpty {
                    ProgressView()
                } else if projects.isEmpty {
                    Text("Todavía no hay proyectos.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(projects) { project in
                        Button {
                            startEdit(project)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(project.name).font(.headline).foregroundStyle(.primary)
                                    Spacer()
                                    Text(project.status.label)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Text(project.address)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Text(money(project.chargedAmount))
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)
                                if let notes = project.notes, !notes.isEmpty {
                                    Text(notes).font(.caption).foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                        .swipeActions {
                            Button("Borrar", role: .destructive) {
                                Task { await remove(project) }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Proyectos")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    startCreate()
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showForm) {
            NavigationStack {
                Form {
                    Section("Obra / servicio") {
                        TextField("Nombre", text: $formName)
                        TextField("Dirección", text: $formAddress)
                        TextField("Descripción", text: $formDescription, axis: .vertical)
                        TextField("Valor cobrado (COP)", text: $formAmount)
                            .keyboardType(.decimalPad)
                        Picker("Estado", selection: $formStatus) {
                            ForEach(ServiceProjectStatus.allCases) { status in
                                Text(status.label).tag(status)
                            }
                        }
                        TextField("Notas", text: $formNotes, axis: .vertical)
                    }
                    if let errorMessage {
                        Section { Text(errorMessage).foregroundStyle(.red) }
                    }
                }
                .navigationTitle(editing == nil ? "Nuevo proyecto" : "Editar proyecto")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancelar") { showForm = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Guardar") {
                            Task { await save() }
                        }
                    }
                }
            }
        }
        .task { await load() }
        .refreshable { await load() }
    }

    private func money(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "COP"
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: value)) ?? "\(Int(value))"
    }

    private func startCreate() {
        editing = nil
        formName = ""
        formAddress = ""
        formDescription = ""
        formAmount = ""
        formStatus = .IN_PROGRESS
        formNotes = ""
        errorMessage = nil
        showForm = true
    }

    private func startEdit(_ project: ServiceProject) {
        editing = project
        formName = project.name
        formAddress = project.address
        formDescription = project.description
        formAmount = String(Int(project.chargedAmount))
        formStatus = project.status
        formNotes = project.notes ?? ""
        errorMessage = nil
        showForm = true
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let response = try await session.projects.list(status: filter)
            projects = response.projects
            summary = response.summary
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func save() async {
        let amount = Double(formAmount.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)) ?? -1
        guard !formName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !formAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              amount >= 0
        else {
            errorMessage = "Completá nombre, dirección y valor cobrado."
            return
        }
        let body = UpsertServiceProjectRequest(
            name: formName.trimmingCharacters(in: .whitespacesAndNewlines),
            address: formAddress.trimmingCharacters(in: .whitespacesAndNewlines),
            description: formDescription.trimmingCharacters(in: .whitespacesAndNewlines),
            chargedAmount: amount,
            status: formStatus.rawValue,
            notes: formNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? nil
                : formNotes.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        do {
            if let editing {
                _ = try await session.projects.update(id: editing.id, body)
            } else {
                _ = try await session.projects.create(body)
            }
            showForm = false
            await load()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func remove(_ project: ServiceProject) async {
        do {
            try await session.projects.delete(id: project.id)
            await load()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}
