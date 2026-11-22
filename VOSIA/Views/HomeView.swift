import SwiftUI

struct HomeView: View {
    @Environment(SessionStore.self) private var session
    @State private var path: [AppModule] = []
    @State private var overview: PersonalOverview?
    @State private var projectSummary: ServiceProjectsSummary?

    private var isPersonal: Bool { AppModule.isPersonalCompany(session.user) }
    private var isService: Bool { AppModule.isServiceCompany(session.user) }
    private var modules: [AppModule] { AppModule.launcher(for: session.user) }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    if isPersonal, let overview {
                        personalPulse(overview)
                    }
                    if isService, let projectSummary {
                        servicePulse(projectSummary)
                    }
                    LazyVGrid(
                        columns: [GridItem(.flexible()), GridItem(.flexible())],
                        spacing: 12
                    ) {
                        ForEach(modules) { module in
                            Button { path.append(module) } label: {
                                moduleTile(module)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding()
            }
            .background(AppTheme.canvas.ignoresSafeArea())
            .tint(AppTheme.accentMuted)
            .navigationTitle(
                isPersonal
                    ? "Main"
                    : (session.user?.companyName.isEmpty == false
                        ? session.user!.companyName
                        : "Inicio")
            )
            .navigationDestination(for: AppModule.self) { module in
                ModuleDestinationView(module: module)
            }
            .task { await refreshPulse() }
            .refreshable { await refreshPulse() }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(isPersonal ? "Vida personal" : (isService ? "Empresa de servicios" : AppConfig.brandName))
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(greeting)
                .font(.title2.bold())
            Text(headerCopy)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var headerCopy: String {
        if isPersonal {
            return "Organizate con Aura: dinero, notas, ideas, tiempo y bienestar en un solo lugar."
        }
        if isService {
            return "Proyectos, tareas, cobros y operación para llevar la empresa con claridad."
        }
        if session.user?.companyName.isEmpty == false {
            return "Empresa: \(session.user!.companyName)"
        }
        return "Seleccione un módulo para trabajar."
    }

    private var greeting: String {
        let name = session.user?.firstName ?? ""
        return name.isEmpty ? "Buenas" : "Hola, \(name)"
    }

    private func personalPulse(_ overview: PersonalOverview) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Hoy en Main")
                .font(.headline)
            HStack {
                pulseCard("Balance", value: money(overview.money.balanceCOP))
                pulseCard("Tareas", value: "\(overview.pendingTasksToday)")
            }
            HStack {
                pulseCard("Notas", value: "\(overview.notesCount)")
                pulseCard("Ideas", value: "\(overview.ideasCount)")
            }
            if let wellness = overview.latestWellness {
                Text("Último bienestar · ánimo \(wellness.mood)/10 · salud \(wellness.health)/10")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func servicePulse(_ summary: ServiceProjectsSummary) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Pulso de la empresa")
                .font(.headline)
            HStack {
                pulseCard("Obras", value: "\(summary.total)")
                pulseCard("En curso", value: "\(summary.inProgress)")
            }
            HStack {
                pulseCard("Cobrados", value: "\(summary.completed)")
                pulseCard("Cobrado", value: money(summary.chargedTotal))
            }
        }
    }

    private func pulseCard(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.title3.bold())
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.cardBackground())
    }

    private func money(_ value: Double) -> String { AppTheme.money(value) }

    private func moduleTile(_ module: AppModule) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: module.systemImage)
                .font(.title2)
                .foregroundStyle(AppTheme.accentMuted)
            Text(module.title)
                .font(.headline)
                .foregroundStyle(.primary)
            if !module.subtitle.isEmpty {
                Text(module.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }
            if !module.isNativeReady {
                Text("Web")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
        .background(AppTheme.cardBackground())
    }

    private func refreshPulse() async {
        if isPersonal {
            overview = try? await session.personal.overview()
        }
        if isService {
            projectSummary = try? await session.projects.list().summary
        }
    }
}

struct ModuleDestinationView: View {
    let module: AppModule

    var body: some View {
        switch module {
        case .aura:
            AuraChatView()
        case .journal:
            JournalView()
        case .ideas:
            IdeasVaultView()
        case .operations:
            OperationsView()
        case .financePersonal:
            PersonalFinanceView()
        case .time, .tasks:
            PersonalTasksView()
        case .calendarPersonal:
            PersonalCalendarView()
        case .wellness:
            WellnessGraphView()
        case .projects:
            ProjectsView()
        case .analytics:
            BusinessFinanceView()
        case .account:
            AccountView()
        default:
            ComingSoonModuleView(module: module)
        }
    }
}

struct ComingSoonModuleView: View {
    let module: AppModule

    var body: some View {
        ContentUnavailableView {
            Label(module.title, systemImage: module.systemImage)
        } description: {
            Text("Disponible en la web. La versión nativa se construye sobre los mismos endpoints.")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.canvas.ignoresSafeArea())
        .tint(AppTheme.accentMuted)
        .navigationTitle(module.title)
    }
}
