import SwiftUI

struct HomeView: View {
    @Environment(SessionStore.self) private var session
    @State private var path: [AppModule] = []

    private var modules: [AppModule] {
        AppModule.launcher(for: session.user)
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    LazyVGrid(
                        columns: [GridItem(.flexible()), GridItem(.flexible())],
                        spacing: 12
                    ) {
                        ForEach(modules) { module in
                            Button {
                                path.append(module)
                            } label: {
                                moduleTile(module)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Inicio")
            .navigationDestination(for: AppModule.self) { module in
                ModuleDestinationView(module: module)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(AppConfig.brandName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(greeting)
                .font(.title2.bold())
            Text(session.user?.companyName.isEmpty == false
                 ? "Empresa: \(session.user!.companyName)"
                 : "Seleccione un módulo para trabajar.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 4)
    }

    private var greeting: String {
        let name = session.user?.firstName ?? ""
        return name.isEmpty ? "Buenas" : "Hola, \(name)"
    }

    private func moduleTile(_ module: AppModule) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: module.systemImage)
                .font(.title2)
                .foregroundStyle(module.isNativeReady ? Color.accentColor : Color.secondary)
            Text(module.title)
                .font(.headline)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
            Text(module.isNativeReady ? "Listo" : "Próximamente")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct ModuleDestinationView: View {
    let module: AppModule

    var body: some View {
        switch module {
        case .assistant:
            AssistantChatView()
        case .journal:
            JournalView()
        case .operations:
            OperationsView()
        case .financePersonal:
            PersonalFinanceView()
        case .time, .tasks:
            PersonalTasksView()
        case .calendarPersonal:
            PersonalCalendarView()
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
            Text("Este módulo ya existe en la web. La versión nativa se está construyendo sobre los mismos endpoints de vos-api.")
        }
        .navigationTitle(module.title)
    }
}
