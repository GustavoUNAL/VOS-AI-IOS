import SwiftUI

struct RootView: View {
    @Environment(SessionStore.self) private var session

    var body: some View {
        Group {
            if session.isBootstrapping {
                ProgressView("Restaurando sesión…")
            } else if !session.isAuthenticated {
                LoginView()
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

    var body: some View {
        TabView {
            NavigationStack {
                AssistantChatView()
            }
            .tabItem { Label("Asistente", systemImage: "bubble.left.and.bubble.right") }

            NavigationStack {
                JournalView()
            }
            .tabItem { Label("Diario", systemImage: "book") }

            NavigationStack {
                OperationsView()
            }
            .tabItem { Label("Operación", systemImage: "chart.bar") }

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
