import SwiftUI

struct HomeView: View {
    @Environment(SessionStore.self) private var session
    @State private var path: [AppModule] = []
    @State private var overview: PersonalOverview?

    private var isPersonal: Bool { AppModule.isPersonalCompany(session.user) }
    private var modules: [AppModule] { AppModule.launcher(for: session.user) }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    if isPersonal, let overview {
                        personalPulse(overview)
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
            .background(
                LinearGradient(
                    colors: [
                        Color(.systemGroupedBackground),
                        Color.accentColor.opacity(0.06),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationTitle(isPersonal ? "Main" : "Inicio")
            .navigationDestination(for: AppModule.self) { module in
                ModuleDestinationView(module: module)
            }
            .task {
                if isPersonal {
                    overview = try? await session.personal.overview()
                }
            }
            .refreshable {
                if isPersonal {
                    overview = try? await session.personal.overview()
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(isPersonal ? "Vida personal" : AppConfig.brandName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(greeting)
                .font(.title2.bold())
            Text(isPersonal
                 ? "Organizate con Vicente: dinero, notas, ideas, tiempo y bienestar en un solo lugar."
                 : (session.user?.companyName.isEmpty == false
                    ? "Empresa: \(session.user!.companyName)"
                    : "Seleccione un módulo para trabajar."))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var greeting: String {
        let name = session.user?.firstName ?? ""
        if isPersonal {
            return name.isEmpty ? "Buenas" : "Hola, \(name)"
        }
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

    private func pulseCard(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.title3.bold())
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func money(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "COP"
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: value)) ?? "\(Int(value))"
    }

    private func moduleTile(_ module: AppModule) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: module.systemImage)
                .font(.title2)
                .foregroundStyle(Color.accentColor)
            Text(module.title)
                .font(.headline)
                .foregroundStyle(.primary)
            if !module.subtitle.isEmpty {
                Text(module.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct ModuleDestinationView: View {
    let module: AppModule

    var body: some View {
        switch module {
        case .vicente:
            VicenteChatView()
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
            Text("Este módulo ya existe en la web. La versión nativa se está construyendo sobre los mismos endpoints.")
        }
        .navigationTitle(module.title)
    }
}
