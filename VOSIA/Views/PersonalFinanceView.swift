import SwiftUI

struct PersonalFinanceView: View {
    @Environment(SessionStore.self) private var session
    @State private var entries: [PersonalMoneyEntry] = []
    @State private var summary: PersonalMoneySummary?
    @State private var kind: PersonalMoneyKind = .EXPENSE
    @State private var amount = ""
    @State private var category = "general"
    @State private var note = ""
    @State private var errorMessage: String?
    @State private var isLoading = false

    var body: some View {
        List {
            Section {
                Text("Control de dinero personal. Se guarda en la base de datos de VOS IA (Neon) y no se borra al desplegar.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if let summary {
                Section("Resumen") {
                    LabeledContent("Ingresos", value: money(summary.incomeCOP))
                    LabeledContent("Gastos", value: money(summary.expenseCOP))
                    LabeledContent("Balance", value: money(summary.balanceCOP))
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
                Button("Guardar") {
                    Task { await save() }
                }
                .disabled(isLoading)
            }

            if let errorMessage {
                Section { Text(errorMessage).foregroundStyle(.red) }
            }

            Section("Movimientos") {
                if isLoading && entries.isEmpty {
                    ProgressView()
                } else if entries.isEmpty {
                    Text("Todavía no hay movimientos.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(entries) { entry in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(entry.kind.label)
                                    .font(.subheadline.weight(.semibold))
                                Spacer()
                                Text(money(entry.amountCOP))
                                    .foregroundStyle(entry.kind == .INCOME ? .green : .primary)
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
                }
            }
        }
        .navigationTitle("Finanzas")
        .task { await load() }
        .refreshable { await load() }
    }

    private func money(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "COP"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "\(Int(value))"
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let response = try await session.personal.listMoney()
            entries = response.entries
            summary = response.summary
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func save() async {
        guard let amountCOP = Double(amount.replacingOccurrences(of: ",", with: ".")),
              amountCOP > 0 else {
            errorMessage = "Ingrese un monto válido."
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let day = ISO8601DateFormatter().string(from: Date()).prefix(10)
            _ = try await session.personal.createMoney(
                UpsertPersonalMoneyRequest(
                    kind: kind.rawValue,
                    amountCOP: amountCOP,
                    category: category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        ? "general"
                        : category,
                    note: note.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
                    occurredOn: String(day)
                )
            )
            amount = ""
            note = ""
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

private extension String {
    var nilIfEmpty: String? {
        let t = trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }
}
