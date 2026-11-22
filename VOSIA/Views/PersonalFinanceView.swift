import SwiftUI

struct PersonalFinanceView: View {
    @Environment(SessionStore.self) private var session
    @State private var list: PersonalMoneyListResponse?
    @State private var budgets: PersonalMoneyBudgetListResponse?
    @State private var kind: PersonalMoneyKind = .EXPENSE
    @State private var amount = ""
    @State private var category = "comida"
    @State private var note = ""
    @State private var budgetCategory = "comida"
    @State private var budgetLimit = ""
    @State private var errorMessage: String?
    @State private var isLoading = false

    private var monthKey: String {
        String(ISO8601DateFormatter().string(from: Date()).prefix(7))
    }

    var body: some View {
        List {
            Section {
                ScreenIntro(text: "Movimientos, categorías y presupuestos. También podés pedirle a Aura que registre un gasto.")
            }

            if let summary = list?.summary {
                Section("Resumen") {
                    LabeledContent("Ingresos", value: AppTheme.money(summary.incomeCOP))
                    LabeledContent("Gastos", value: AppTheme.money(summary.expenseCOP))
                    LabeledContent("Balance", value: AppTheme.money(summary.balanceCOP))
                }
            }

            if let byCategory = list?.byCategory, !byCategory.isEmpty {
                Section("Por categoría") {
                    ForEach(byCategory, id: \.category) { row in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(row.category).font(.subheadline.weight(.semibold))
                            Text("In \(AppTheme.money(row.incomeCOP)) · Out \(AppTheme.money(row.expenseCOP))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("Presupuestos \(monthKey)") {
                TextField("Categoría", text: $budgetCategory)
                TextField("Tope COP", text: $budgetLimit)
                    .keyboardType(.decimalPad)
                Button("Guardar presupuesto") { Task { await saveBudget() } }
                if let budgets {
                    ForEach(budgets.budgets) { budget in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(budget.category).font(.subheadline.weight(.semibold))
                            Text("Gastado \(AppTheme.money(budget.spentCOP ?? 0)) / \(AppTheme.money(budget.limitCOP)) · Queda \(AppTheme.money(budget.remainingCOP ?? 0))")
                                .font(.caption)
                                .foregroundStyle((budget.remainingCOP ?? 0) < 0 ? AppTheme.danger : Color.secondary)
                        }
                    }
                }
            }

            Section("Nuevo movimiento") {
                Picker("Tipo", selection: $kind) {
                    ForEach(PersonalMoneyKind.allCases) { item in
                        Text(item.label).tag(item)
                    }
                }
                TextField("Monto COP", text: $amount)
                    .keyboardType(.decimalPad)
                TextField("Categoría", text: $category)
                TextField("Nota", text: $note)
                Button("Guardar") { Task { await save() } }
            }

            if let errorMessage {
                Section { ScreenErrorText(message: errorMessage) }
            }

            Section("Movimientos") {
                if isLoading && list?.entries.isEmpty != false {
                    ProgressView()
                } else if let entries = list?.entries, !entries.isEmpty {
                    ForEach(entries) { entry in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(entry.kind.label).font(.subheadline.weight(.semibold))
                                Spacer()
                                Text(AppTheme.money(entry.amountCOP))
                                    .foregroundStyle(entry.kind == .INCOME ? AppTheme.positive : Color.primary)
                            }
                            Text("\(entry.category) · \(entry.occurredOn)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if let note = entry.note, !note.isEmpty {
                                Text(note).font(.footnote)
                            }
                        }
                        .swipeActions {
                            Button("Borrar", role: .destructive) {
                                Task { await remove(entry) }
                            }
                        }
                    }
                } else {
                    ScreenEmptyText(message: "Todavía no hay movimientos.")
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
        defer { isLoading = false }
        do {
            async let money = session.personal.listMoney()
            async let budget = session.personal.listBudgets(month: monthKey)
            list = try await money
            budgets = try await budget
            errorMessage = nil
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func save() async {
        guard let amountCOP = Double(amount.replacingOccurrences(of: ",", with: ".")), amountCOP > 0 else {
            errorMessage = "Ingrese un monto válido."
            return
        }
        do {
            let day = String(ISO8601DateFormatter().string(from: Date()).prefix(10))
            _ = try await session.personal.createMoney(
                UpsertPersonalMoneyRequest(
                    kind: kind.rawValue,
                    amountCOP: amountCOP,
                    category: category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "general" : category.lowercased(),
                    note: note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : note,
                    occurredOn: day
                )
            )
            amount = ""
            note = ""
            await load()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func saveBudget() async {
        guard let limit = Double(budgetLimit.replacingOccurrences(of: ",", with: ".")), limit >= 0 else {
            errorMessage = "Tope inválido."
            return
        }
        do {
            _ = try await session.personal.upsertBudget(
                UpsertPersonalMoneyBudgetRequest(
                    category: budgetCategory.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
                    month: monthKey,
                    limitCOP: limit
                )
            )
            budgetLimit = ""
            await load()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func remove(_ entry: PersonalMoneyEntry) async {
        do {
            try await session.personal.deleteMoney(id: entry.id)
            await load()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}
