import SwiftUI

struct JournalView: View {
    @Environment(SessionStore.self) private var session
    @State private var model: JournalViewModel?

    private var isPersonal: Bool { AppModule.isPersonalCompany(session.user) }

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
            if isPersonal {
                Section {
                    VStack(alignment: .center, spacing: 6) {
                        Text("02 · Notas")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(AppTheme.accentMuted)
                            .tracking(1)
                        Text("Escribí lo que quieras recordar. Se guarda solo en tu espacio.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                }
            } else {
                Section {
                    ScreenIntro(text: "Notas con título y tags. Quedan guardadas y Aura puede retomarlas.")
                }
            }

            Section {
                if isPersonal {
                    Text("1 · Escribir")
                        .font(.subheadline.weight(.semibold))
                }
                if !isPersonal {
                    TextField("Título (opcional)", text: $model.titleDraft)
                    TextField("Tags (coma)", text: $model.tagsDraft)
                }
                TextEditor(text: $model.draft)
                    .frame(minHeight: isPersonal ? 180 : 140)
                    .onChange(of: model.draft) { _, _ in model.scheduleAutosave() }
                    .onChange(of: model.titleDraft) { _, _ in model.scheduleAutosave() }
                    .onChange(of: model.tagsDraft) { _, _ in model.scheduleAutosave() }
                HStack {
                    Text(model.errorMessage ?? model.status)
                        .font(.caption)
                        .foregroundStyle(model.errorMessage == nil ? Color.secondary : Color.red)
                    Spacer()
                    Button("Nueva") { model.startNew() }
                        .font(.caption.weight(.semibold))
                }
            } header: {
                if !isPersonal { Text("Escribir") }
            }

            Section {
                if isPersonal {
                    Text("2 · Anteriores")
                        .font(.subheadline.weight(.semibold))
                }
                if model.isLoading {
                    ProgressView()
                } else if model.entries.isEmpty {
                    ScreenEmptyText(message: "Todavía no hay notas anteriores.")
                } else {
                    ForEach(model.entries) { entry in
                        VStack(alignment: .leading, spacing: 6) {
                            Button {
                                model.open(entry)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    if !isPersonal {
                                        Text(entry.title?.isEmpty == false ? entry.title! : "Sin título")
                                            .font(.headline)
                                            .foregroundStyle(.primary)
                                    }
                                    Text(entry.body)
                                        .font(.body)
                                        .foregroundStyle(.primary)
                                        .lineLimit(4)
                                    if let tags = entry.tags, !tags.isEmpty, !isPersonal {
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
            } header: {
                if !isPersonal { Text("Notas guardadas") }
            }
        }
        .screenListChrome()
        .navigationTitle("Notas")
        .refreshable { await model.load() }
    }
}
