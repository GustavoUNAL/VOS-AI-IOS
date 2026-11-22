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
                VStack(alignment: .center, spacing: 20) {
                    header
                    if isPersonal, let overview {
                        personalPulse(overview)
                    }
                    if isService, let projectSummary {
                        servicePulse(projectSummary)
                    }
                    modulesSection
                }
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
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
        VStack(alignment: .center, spacing: 8) {
            Text(isPersonal ? "VOS IA · Main" : (isService ? "Empresa de servicios" : AppConfig.brandName))
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(greeting)
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            Text(headerCopy)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 340)
        }
        .frame(maxWidth: .infinity)
    }

    private var headerCopy: String {
        if isPersonal {
            return "Tu día en orden: Aura, notas, pendientes y lo demás."
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

    @ViewBuilder
    private var modulesSection: some View {
        VStack(alignment: .center, spacing: 12) {
            Text(isPersonal ? "Secuencia del día" : "Módulos")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(1.2)

            if isPersonal {
                Text("01 Aura → 02 Notas → 03 Pendientes → 04 Agenda → 05 Proyectos → 06 Dinero")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }

            LazyVGrid(
                columns: isPersonal
                    ? [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12),
                    ]
                    : [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12),
                    ],
                spacing: 12
            ) {
                ForEach(Array(modules.enumerated()), id: \.element.id) { index, module in
                    Button { path.append(module) } label: {
                        moduleTile(module, step: isPersonal ? index + 1 : nil)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: isPersonal ? 420 : .infinity)
        }
        .frame(maxWidth: .infinity)
    }

    private func personalPulse(_ overview: PersonalOverview) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Hoy en Main")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .center)
            HStack {
                pulseCard("Balance", value: money(overview.money.balanceCOP))
                pulseCard("Tareas", value: "\(overview.pendingTasksToday)")
            }
            HStack {
                pulseCard("Notas", value: "\(overview.notesCount)")
                pulseCard("Ideas", value: "\(overview.ideasCount)")
            }
        }
        .frame(maxWidth: 420)
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

    private func moduleTile(_ module: AppModule, step: Int?) -> some View {
        VStack(spacing: 10) {
            if let step {
                Text(String(format: "%02d", step))
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(AppTheme.accentMuted)
                    .tracking(1)
            }
            Image(systemName: module.systemImage)
                .font(.title2)
                .foregroundStyle(AppTheme.accentMuted)
                .frame(width: 52, height: 52)
                .background(AppTheme.accentSoftFill)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            Text(module.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
            if !module.isNativeReady {
                Text("Web")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity, minHeight: 128)
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
        case .calendarPersonal, .booking:
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
