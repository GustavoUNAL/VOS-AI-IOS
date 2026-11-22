import SwiftUI

struct JournalView: View {
    @Environment(SessionStore.self) private var session
    @State private var model: JournalViewModel?

    var body: some View {
        Group {
            if let model {
                content(model)
            } else {
                ProgressView()
            }
        }
        .task {
            if model == nil { model = JournalViewModel(session: session) }
            await model?.load()
        }
    }

    @ViewBuilder
    private func content(_ model: JournalViewModel) -> some View {
        @Bindable var model = model
        List {
            Section {
                Text("Notas del diario en la base de datos (Neon). Un deploy no las borra: solo se pierden si se elimina la empresa o la nota a mano.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Escribir") {
                TextEditor(text: $model.draft)
                    .frame(minHeight: 120)
                    .onChange(of: model.draft) { _, _ in
                        model.scheduleAutosave()
                    }
                HStack {
                    Text(model.errorMessage ?? model.status)
                        .font(.caption)
                        .foregroundStyle(model.errorMessage == nil ? Color.secondary : Color.red)
                    Spacer()
                    Button("Nueva nota") { model.startNew() }
                        .font(.caption.weight(.semibold))
                }
            }

            Section("Notas guardadas") {
                if model.isLoading {
                    ProgressView()
                } else if model.entries.isEmpty {
                    Text("Todavía no hay notas en esta empresa.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(model.entries) { entry in
                        VStack(alignment: .leading, spacing: 6) {
                            Button {
                                model.open(entry)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(entry.authorName)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.primary)
                                    Text(entry.body)
                                        .font(.body)
                                        .foregroundStyle(.primary)
                                        .lineLimit(4)
                                    Text(entry.updatedAt)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Button("Borrar", role: .destructive) {
                                Task { await model.delete(entry) }
                            }
                            .font(.caption)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Diario")
        .refreshable { await model.load() }
    }
}
