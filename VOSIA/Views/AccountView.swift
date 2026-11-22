import SwiftUI

struct AccountView: View {
    @Environment(SessionStore.self) private var session
    @State private var errorMessage: String?
    @State private var isRefreshing = false
    @State private var isReturning = false

    var body: some View {
        List {
            if let user = session.user {
                Section("Sesión") {
                    LabeledContent("Nombre", value: user.name)
                    LabeledContent("Correo", value: user.email)
                    LabeledContent("Rol", value: user.role)
                    if user.isPlatformAdmin == true {
                        LabeledContent("Plataforma", value: "Administrador")
                    }
                }

                Section("Empresa activa") {
                    if let companyId = session.companyId {
                        LabeledContent("Nombre", value: user.companyName.isEmpty ? "—" : user.companyName)
                        LabeledContent("ID", value: companyId)
                        LabeledContent("Slug", value: user.companySlug.isEmpty ? "—" : user.companySlug)
                    } else {
                        Text("Sin empresa seleccionada")
                            .foregroundStyle(.secondary)
                    }
                }

                if user.isPlatformAdmin == true, session.companyId != nil {
                    Section {
                        Button {
                            Task { await goPlatformHome() }
                        } label: {
                            if isReturning {
                                ProgressView()
                            } else {
                                Label("Volver al panel de plataforma", systemImage: "building.2")
                            }
                        }
                        .disabled(isReturning)
                    }
                }

                if !user.companies.isEmpty {
                    Section("Cambiar empresa") {
                        ForEach(user.companies) { company in
                            Button {
                                Task {
                                    do {
                                        try await session.selectCompany(company)
                                    } catch {
                                        errorMessage = (error as? LocalizedError)?.errorDescription
                                            ?? error.localizedDescription
                                    }
                                }
                            } label: {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(company.name)
                                        Text(company.slug).font(.caption).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if company.id == session.companyId {
                                        Image(systemName: "checkmark.circle.fill")
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Section("API") {
                LabeledContent("Base", value: AppConfig.apiBaseURL.absoluteString)
                Text("OpenAI solo se invoca desde el backend. Esta app no contiene API keys.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Memoria del asistente") {
                Text("El historial vive en esta sesión de la app. Web e iOS no comparten hilo en servidor.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button("Borrar conversación local") {
                    session.resetAssistantConversation()
                }
            }

            if let errorMessage {
                Section {
                    Text(errorMessage).foregroundStyle(.red)
                }
            }

            Section {
                Button {
                    Task {
                        isRefreshing = true
                        defer { isRefreshing = false }
                        do { try await session.refreshProfile() }
                        catch {
                            errorMessage = (error as? LocalizedError)?.errorDescription
                                ?? error.localizedDescription
                        }
                    }
                } label: {
                    if isRefreshing { ProgressView() } else { Text("Actualizar perfil") }
                }
                Button("Cerrar sesión", role: .destructive) {
                    session.logout()
                }
            }
        }
        .navigationTitle("Cuenta")
    }

    private func goPlatformHome() async {
        isReturning = true
        errorMessage = nil
        defer { isReturning = false }
        do {
            try await session.returnToPlatformHome()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}
