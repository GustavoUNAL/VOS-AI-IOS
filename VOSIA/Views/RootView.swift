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
        .tint(AppTheme.accentMuted)
        .task {
            await session.bootstrap()
        }
    }
}

struct MainTabView: View {
    @Environment(SessionStore.self) private var session

    private var isPersonal: Bool { AppModule.isPersonalCompany(session.user) }
    private var isService: Bool { AppModule.isServiceCompany(session.user) }

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label(
                        isPersonal ? "Main" : (isService ? "Empresa" : "Inicio"),
                        systemImage: "square.grid.2x2"
                    )
                }

            if isPersonal {
                NavigationStack { AuraChatView() }
                    .tabItem { Label("Aura", systemImage: "sparkles") }

                NavigationStack { JournalView() }
                    .tabItem { Label("Notas", systemImage: "note.text") }

                NavigationStack { PersonalTasksView() }
                    .tabItem { Label("Pendientes", systemImage: "checklist") }

                NavigationStack { PersonalFinanceView() }
                    .tabItem { Label("Dinero", systemImage: "banknote") }
            } else if AppModule.isBookingLedCompany(session.user) {
                NavigationStack { WebModuleView(module: .booking) }
                    .tabItem { Label("Agenda", systemImage: "calendar.badge.clock") }

                NavigationStack { WebModuleView(module: .customers) }
                    .tabItem { Label("Clientes", systemImage: "person.crop.rectangle.stack") }

                NavigationStack { WebModuleView(module: .cashClose) }
                    .tabItem { Label("Cierre", systemImage: "moon.stars") }

                NavigationStack { BusinessFinanceView() }
                    .tabItem { Label("Finanzas", systemImage: "chart.xyaxis.line") }
            } else if isService {
                NavigationStack { ProjectsView() }
                    .tabItem { Label("Proyectos", systemImage: "folder") }

                NavigationStack { PersonalTasksView() }
                    .tabItem { Label("Tareas", systemImage: "checklist") }

                NavigationStack { BusinessFinanceView() }
                    .tabItem { Label("Finanzas", systemImage: "chart.xyaxis.line") }
            } else {
                NavigationStack { AssistantChatView() }
                    .tabItem { Label("Asistente", systemImage: "bubble.left.and.bubble.right") }

                NavigationStack { JournalView() }
                    .tabItem { Label("Diario", systemImage: "book.pages") }

                NavigationStack { OperationsView() }
                    .tabItem { Label("Operación", systemImage: "chart.bar") }

                NavigationStack { WebModuleView(module: .pos) }
                    .tabItem { Label("POS", systemImage: "storefront") }

                NavigationStack { WebModuleView(module: .sales) }
                    .tabItem { Label("Ventas", systemImage: "cart") }
            }

            NavigationStack {
                AccountView()
            }
            .tabItem { Label("Cuenta", systemImage: "person.crop.circle") }
        }
        .tint(AppTheme.accentMuted)
        .overlay(alignment: .top) {
            if let name = session.user?.companyName, !name.isEmpty {
                Text(name)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(AppTheme.hairline, lineWidth: 0.5))
                    .padding(.top, 4)
                    .allowsHitTesting(false)
            }
        }
    }
}
