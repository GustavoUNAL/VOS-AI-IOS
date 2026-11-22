import SwiftUI

struct IdeasVaultView: View {
    @Environment(SessionStore.self) private var session
    @State private var ideas: [PersonalIdea] = []
    @State private var title = ""
    @State private var bodyText = ""
    @State private var tags = ""
    @State private var errorMessage: String?
    @State private var isLoading = false

    var body: some View {
        List {
            Section {
                Text("Vault de ideas. Se guardan en Neon y quedan después de cada deploy.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Section("Nueva idea") {
                TextField("Título", text: $title)
                TextField("Desarrollo", text: $bodyText, axis: .vertical)
                    .lineLimit(3...8)
                TextField("Tags (coma)", text: $tags)
                Button("Guardar idea") { Task { await save() } }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                              || bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            if let errorMessage {
                Section { Text(errorMessage).foregroundStyle(.red) }
            }
            Section("Vault (\(ideas.count))") {
                if isLoading && ideas.isEmpty {
                    ProgressView()
                } else if ideas.isEmpty {
                    Text("Todavía no hay ideas.").foregroundStyle(.secondary)
                } else {
                    ForEach(ideas) { idea in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(idea.title).font(.headline)
                                if idea.starred {
                                    Image(systemName: "star.fill").foregroundStyle(.yellow)
                                }
                            }
                            Text(idea.body).font(.body).lineLimit(5)
                            if !idea.tags.isEmpty {
                                Text(idea.tags.joined(separator: " · "))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 2)
                        .swipeActions {
                            Button("Borrar", role: .destructive) {
                                Task { await remove(idea) }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Ideas")
        .task { await load() }
        .refreshable { await load() }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            ideas = try await session.personal.listIdeas()
            errorMessage = nil
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func save() async {
        do {
            let parsedTags = tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces).lowercased() }.filter { !$0.isEmpty }
            _ = try await session.personal.createIdea(
                UpsertPersonalIdeaRequest(
                    title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                    body: bodyText.trimmingCharacters(in: .whitespacesAndNewlines),
                    tags: parsedTags,
                    starred: false
                )
            )
            title = ""
            bodyText = ""
            tags = ""
            await load()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func remove(_ idea: PersonalIdea) async {
        do {
            try await session.personal.deleteIdea(id: idea.id)
            await load()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}
