import SwiftUI

struct PlatformHomeView: View {
    @Environment(SessionStore.self) private var session
    @State private var isLoading = false
    @State private var isEntering = false
    @State private var errorMessage: String?
    @State private var query = ""

    private var filtered: [PlatformCompany] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return session.platformCompanies }
        return session.platformCompanies.filter {
            $0.name.lowercased().contains(q) || $0.slug.lowercased().contains(q)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ScreenIntro(text: "Panel de plataforma. Elegí una empresa para operar con el mismo backend que la web.")
                }

                Section {
                    TextField("Buscar empresa", text: $query)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                Section("Empresas (\(filtered.count))") {
                    if isLoading && session.platformCompanies.isEmpty {
                        ProgressView()
                    } else if filtered.isEmpty {
                        ScreenEmptyText(message: "No hay empresas para mostrar.")
                    } else {
                        ForEach(filtered) { company in
                            Button {
                                Task { await enter(company) }
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(company.name)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Text(meta(company))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 2)
                            }
                            .disabled(isEntering)
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
            .navigationTitle("Plataforma")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await reload() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(isLoading || isEntering)
                }
            }
            .overlay {
                if isEntering { ProgressView("Entrando…") }
            }
            .task { await reload() }
            .refreshable { await reload() }
        }
    }

    private func meta(_ company: PlatformCompany) -> String {
        var parts: [String] = []
        if !company.slug.isEmpty { parts.append("e/\(company.slug)") }
        if let plan = company.plan, !plan.isEmpty { parts.append(plan) }
        if let members = company.membersCount { parts.append("\(members) miembros") }
        let moduleNames = company.modules.prefix(3).map(\.slug).joined(separator: ", ")
        if !moduleNames.isEmpty { parts.append(moduleNames) }
        return parts.joined(separator: " · ")
    }

    private func reload() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await session.refreshPlatformCompanies()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func enter(_ company: PlatformCompany) async {
        isEntering = true
        errorMessage = nil
        defer { isEntering = false }
        do {
            try await session.selectCompany(company.asCompanySummary)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}
