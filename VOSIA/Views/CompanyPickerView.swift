import SwiftUI

struct CompanyPickerView: View {
    @Environment(SessionStore.self) private var session
    @State private var isBusy = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Seleccione la empresa con la que va a trabajar. El asistente y los módulos usarán ese contexto.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Section("Empresas") {
                    ForEach(session.user?.companies ?? []) { company in
                        Button {
                            Task { await select(company) }
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(company.name)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text("e/\(company.slug) · \(company.role)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                        .disabled(isBusy)
                    }
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage).foregroundStyle(.red)
                    }
                }

                Section {
                    Button("Cerrar sesión", role: .destructive) {
                        session.logout()
                    }
                }
            }
            .navigationTitle("Empresa")
            .overlay {
                if isBusy { ProgressView() }
            }
        }
    }

    private func select(_ company: CompanySummary) async {
        isBusy = true
        errorMessage = nil
        defer { isBusy = false }
        do {
            try await session.selectCompany(company)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}
