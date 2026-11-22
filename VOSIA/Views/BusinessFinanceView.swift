import SwiftUI

/// Finanzas de empresa: para servicios/energía usa cobros de proyectos; para retail/café, analytics.
struct BusinessFinanceView: View {
    @Environment(SessionStore.self) private var session
    @State private var projectSummary: ServiceProjectsSummary?
    @State private var salesTotal: Double?
    @State private var purchasesTotal: Double?
    @State private var netTotal: Double?
    @State private var errorMessage: String?
    @State private var isLoading = false

    private var isService: Bool { AppModule.isServiceCompany(session.user) }

    var body: some View {
        List {
            Section {
                ScreenIntro(text: isService
                    ? "Dinero de la empresa a partir de obras y servicios cobrados."
                    : "Resumen financiero del periodo (ventas, compras y neto).")
            }

            if let errorMessage {
                Section { ScreenErrorText(message: errorMessage) }
            }

            if isLoading {
                Section { ProgressView() }
            } else if isService, let projectSummary {
                Section("Proyectos") {
                    LabeledContent("Total obras", value: "\(projectSummary.total)")
                    LabeledContent("En ejecución", value: "\(projectSummary.inProgress)")
                    LabeledContent("Cobrados", value: "\(projectSummary.completed)")
                    LabeledContent("Cobrado acumulado", value: AppTheme.money(projectSummary.chargedTotal))
                }
            } else {
                Section("Periodo") {
                    LabeledContent("Ventas", value: AppTheme.money(salesTotal ?? 0))
                    LabeledContent("Compras", value: AppTheme.money(purchasesTotal ?? 0))
                    LabeledContent("Neto aprox.", value: AppTheme.money(netTotal ?? 0))
                }
            }
        }
        .screenListChrome()
        .navigationTitle("Finanzas")
        .task { await load() }
        .refreshable { await load() }
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            if isService {
                let response = try await session.projects.list()
                projectSummary = response.summary
            } else {
                let raw: FinancialOverviewPayload = try await session.api.request(
                    "GET",
                    path: "analytics/financial",
                    authenticated: true,
                    requiresCompany: true
                )
                salesTotal = raw.sales?.totals?.totalCOP
                purchasesTotal = raw.purchases?.totals?.totalCOP
                let sales = salesTotal ?? 0
                let purchases = purchasesTotal ?? 0
                let staff = raw.staff?.totals?.totalPayCOP ?? 0
                let utilities = raw.utilities?.totals?.totalCOP ?? 0
                netTotal = sales - purchases - staff - utilities
            }
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}

private struct FinancialOverviewPayload: Decodable {
    struct Totals: Decodable {
        let totalCOP: Double?
        let totalPayCOP: Double?
    }
    struct Block: Decodable {
        let totals: Totals?
    }
    let sales: Block?
    let purchases: Block?
    let staff: Block?
    let utilities: Block?
}
