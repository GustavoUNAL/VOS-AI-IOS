import SwiftUI

struct CompanyPickerView: View {
    @Environment(SessionStore.self) private var session
    @State private var isBusy = false
    @State private var errorMessage: String?

    private var companies: [CompanySummary] {
        if !(session.user?.companies.isEmpty ?? true) {
            return session.user?.companies ?? []
        }
        return session.platformCompanies.map(\.asCompanySummary)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ScreenIntro(text: "Elegí la empresa. El asistente y los módulos usan ese contexto.")
                }

                Section("Empresas") {
                    if companies.isEmpty {
                        ScreenEmptyText(message: "No hay empresas disponibles.")
                    } else {
                        ForEach(companies) { company in
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
                }

                if let errorMessage {
                    Section { ScreenErrorText(message: errorMessage) }
                }

                Section {
                    Button("Cerrar sesión", role: .destructive) {
                        session.logout()
                    }
                }
            }
            .screenListChrome()
            .navigationTitle("Empresa")
            .overlay {
                if isBusy { ProgressView() }
            }
            .task {
                if session.user?.isPlatformAdmin == true, session.user?.companies.isEmpty == true {
                    do {
                        try await session.refreshPlatformCompanies()
                    } catch {
                        errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                    }
                }
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
