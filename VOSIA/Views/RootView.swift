import SwiftUI

struct RootView: View {
    @Environment(SessionStore.self) private var session

    var body: some View {
        Group {
            if session.isBootstrapping {
                ProgressView("Restaurando sesión…")
            } else if !session.isAuthenticated {
                LoginView()
            } else if session.isPlatformHome {
                PlatformHomeView()
            } else if session.user?.needsCompanySelection == true || session.companyId == nil {
                CompanyPickerView()
            } else {
                MainTabView()
            }
        }
        .task {
            await session.bootstrap()
        }
    }
}

struct MainTabView: View {
    @Environment(SessionStore.self) private var session

    private var isPersonal: Bool { AppModule.isPersonalCompany(session.user) }

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label(isPersonal ? "Main" : "Inicio", systemImage: "square.grid.2x2") }

            NavigationStack {
                if isPersonal {
                    VicenteChatView()
                } else {
                    AssistantChatView()
                }
            }
            .tabItem {
                Label(isPersonal ? "Vicente" : "Asistente",
                      systemImage: isPersonal ? "sparkles" : "bubble.left.and.bubble.right")
            }

            NavigationStack {
                if isPersonal {
                    JournalView()
                } else {
                    JournalView()
                }
            }
            .tabItem { Label(isPersonal ? "Notas" : "Diario", systemImage: "book.pages") }

            NavigationStack {
                if isPersonal {
                    PersonalFinanceView()
                } else {
                    OperationsView()
                }
            }
            .tabItem {
                Label(isPersonal ? "Finanzas" : "Operación",
                      systemImage: isPersonal ? "banknote" : "chart.bar")
            }

            NavigationStack {
                AccountView()
            }
            .tabItem { Label("Cuenta", systemImage: "person.crop.circle") }
        }
        .overlay(alignment: .top) {
            if let name = session.user?.companyName, !name.isEmpty {
                Text(name)
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .padding(.top, 4)
                    .allowsHitTesting(false)
            }
        }
    }
}
