import SwiftUI

struct LoginView: View {
    @Environment(SessionStore.self) private var session
    @State private var email = ""
    @State private var password = ""
    @State private var isBusy = false
    @State private var errorMessage: String?
    @State private var googleAuth = GoogleAuthService()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(AppConfig.brandName)
                        .font(.largeTitle.bold())
                    ScreenIntro(text: "Misma cuenta que la web. El motor de IA vive en el backend.")
                }
                .listRowBackground(Color.clear)

                Section("Cuenta") {
                    TextField("Usuario o correo", text: $email)
                        .textContentType(.username)
                        .keyboardType(.asciiCapable)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    SecureField("Contraseña", text: $password)
                        .textContentType(.password)
                }

                if let errorMessage {
                    Section { ScreenErrorText(message: errorMessage) }
                }

                Section {
                    Button {
                        Task { await submitPassword() }
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

                    Button {
                        Task { await submitGoogle() }
                    } label: {
                        Text("Continuar con Google")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(isBusy)
                }

                Section {
                    Text("API: \(AppConfig.apiBaseURL.absoluteString)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .screenListChrome()
            .navigationTitle("Acceso")
        }
        .tint(AppTheme.accentMuted)
    }

    private func submitPassword() async {
        isBusy = true
        errorMessage = nil
        defer { isBusy = false }
        do {
            try await session.login(email: email, password: password)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func submitGoogle() async {
        isBusy = true
        errorMessage = nil
        defer { isBusy = false }
        do {
            let outcome = try await googleAuth.signIn(apiBaseURL: AppConfig.apiBaseURL)
            switch outcome {
            case .accessToken(let token):
                try await session.completeGoogleSignIn(accessToken: token)
            case .signup:
                errorMessage = "Esta cuenta de Google aún no tiene usuario en VOS IA. Completá el registro en la web."
            case .error(let code):
                errorMessage = googleErrorMessage(code)
            }
        } catch is CancellationError {
            // Usuario canceló el sheet de Google.
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func googleErrorMessage(_ code: String) -> String {
        switch code {
        case "no_account":
            return "No hay cuenta VOS IA asociada a ese Google."
        case "inactive":
            return "La cuenta está inactiva."
        case "no_company":
            return "La cuenta no tiene empresas activas."
        case "access_denied":
            return "Acceso denegado en Google."
        case "not_configured":
            return "Google OAuth no está configurado en el servidor."
        default:
            return "No se pudo completar el inicio con Google (\(code))."
        }
    }
}
