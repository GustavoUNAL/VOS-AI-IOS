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
                ScreenIntro(text: "Notas con título y tags. Quedan guardadas y Aura puede retomarlas.")
            }

            Section("Escribir") {
                TextField("Título (opcional)", text: $model.titleDraft)
                TextField("Tags (coma)", text: $model.tagsDraft)
                TextEditor(text: $model.draft)
                    .frame(minHeight: 140)
                    .onChange(of: model.draft) { _, _ in model.scheduleAutosave() }
                    .onChange(of: model.titleDraft) { _, _ in model.scheduleAutosave() }
                    .onChange(of: model.tagsDraft) { _, _ in model.scheduleAutosave() }
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
                    ScreenEmptyText(message: "Todavía no hay notas.")
                } else {
                    ForEach(model.entries) { entry in
                        VStack(alignment: .leading, spacing: 6) {
                            Button {
                                model.open(entry)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(entry.title?.isEmpty == false ? entry.title! : "Sin título")
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Text(entry.body)
                                        .font(.body)
                                        .foregroundStyle(.primary)
                                        .lineLimit(4)
                                    if let tags = entry.tags, !tags.isEmpty {
                                        Text(tags.joined(separator: " · "))
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
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
        .screenListChrome()
        .navigationTitle("Notas")
        .refreshable { await model.load() }
    }
}
