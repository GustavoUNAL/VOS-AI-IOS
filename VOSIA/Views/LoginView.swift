import SwiftUI

struct LoginView: View {
    @Environment(SessionStore.self) private var session
    @State private var email = ""
    @State private var password = ""
    @State private var isBusy = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(AppConfig.brandName)
                        .font(.largeTitle.bold())
                    Text("Inicie sesión con la misma cuenta de la plataforma web. El motor de IA vive en el backend.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .listRowBackground(Color.clear)

                Section("Cuenta") {
                    TextField("Usuario o correo", text: $email)
                        .textContentType(.username)
                        .keyboardType(.ASCIICapable)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    SecureField("Contraseña", text: $password)
                        .textContentType(.password)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    Button {
                        Task { await submit() }
                    } label: {
                        if isBusy {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Iniciar sesión")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(isBusy || email.trimmingCharacters(in: .whitespaces).isEmpty || password.isEmpty)
                }

                Section {
                    Text("API: \(AppConfig.apiBaseURL.absoluteString)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .navigationTitle("Acceso")
        }
    }

    private func submit() async {
        isBusy = true
        errorMessage = nil
        defer { isBusy = false }
        do {
            try await session.login(email: email, password: password)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}
