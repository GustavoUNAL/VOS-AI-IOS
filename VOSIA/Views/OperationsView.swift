import SwiftUI

struct OperationsView: View {
    @Environment(SessionStore.self) private var session
    @State private var model: OperationsViewModel?

    var body: some View {
        Group {
            if let model {
                content(model)
            } else {
                ProgressView()
            }
        }
        .task {
            if model == nil { model = OperationsViewModel(session: session) }
            await model?.load()
        }
    }

    @ViewBuilder
    private func content(_ model: OperationsViewModel) -> some View {
        List {
            Section {
                Text(model.disclaimer)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if let error = model.errorMessage {
                Section {
                    Text(error).foregroundStyle(.red)
                }
            }

            Section("Operación del día") {
                if model.isLoading {
                    ProgressView()
                } else if model.rows.isEmpty {
                    Text("Sin datos para mostrar.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(model.rows, id: \.key) { row in
                        LabeledContent(row.key, value: row.value)
                    }
                }
            }
        }
        .navigationTitle("Operación")
        .refreshable { await model.load() }
    }
}
