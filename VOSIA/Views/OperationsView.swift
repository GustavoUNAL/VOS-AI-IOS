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
                ScreenIntro(text: model.disclaimer)
            }

            if let error = model.errorMessage {
                Section { ScreenErrorText(message: error) }
            }

            Section("Operación del día") {
                if model.isLoading {
                    ProgressView()
                } else if model.rows.isEmpty {
                    ScreenEmptyText(message: "Sin datos para mostrar.")
                } else {
                    ForEach(model.rows, id: \.key) { row in
                        LabeledContent(row.key, value: row.value)
                    }
                }
            }
        }
        .screenListChrome()
        .navigationTitle("Operación")
        .refreshable { await model.load() }
    }
}
