import SwiftUI

struct WellnessGraphView: View {
    @Environment(SessionStore.self) private var session
    @State private var response: WellnessListResponse?
    @State private var mood = 6
    @State private var health = 6
    @State private var love = 6
    @State private var friendships = 6
    @State private var family = 6
    @State private var note = ""
    @State private var errorMessage: String?
    @State private var isLoading = false

    var body: some View {
        List {
            Section {
                Text("Registrá cómo estás. El grafo muestra ánimo, salud, amor, amistades y familia, y cómo se relacionan en el tiempo.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Check-in de hoy") {
                slider("Ánimo", value: $mood)
                slider("Salud", value: $health)
                slider("Amor", value: $love)
                slider("Amistades", value: $friendships)
                slider("Familia", value: $family)
                TextField("Nota (opcional)", text: $note)
                Button("Guardar check-in") { Task { await save() } }
            }

            if let graph = response?.graph {
                Section("Grafo de vida") {
                    WellnessCanvas(graph: graph)
                        .frame(height: 260)
                    ForEach(Array(graph.edges.enumerated()), id: \.offset) { _, edge in
                        Text("\(label(edge.from)) ↔ \(label(edge.to)): \(edge.weight)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if let errorMessage {
                Section { Text(errorMessage).foregroundStyle(.red) }
            }

            Section("Historial") {
                if isLoading && response?.checkIns.isEmpty != false {
                    ProgressView()
                } else if let checkIns = response?.checkIns, !checkIns.isEmpty {
                    ForEach(checkIns.prefix(14)) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.checkedOn).font(.subheadline.weight(.semibold))
                            Text("Ánimo \(item.mood) · Salud \(item.health) · Amor \(item.love) · Amigos \(item.friendships) · Familia \(item.family)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if let note = item.note, !note.isEmpty {
                                Text(note).font(.footnote)
                            }
                        }
                    }
                } else {
                    Text("Todavía no hay check-ins.").foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Bienestar")
        .task { await load() }
        .refreshable { await load() }
    }

    private func slider(_ title: String, value: Binding<Int>) -> some View {
        VStack(alignment: .leading) {
            HStack {
                Text(title)
                Spacer()
                Text("\(value.wrappedValue)")
                    .foregroundStyle(.secondary)
            }
            Slider(
                value: Binding(
                    get: { Double(value.wrappedValue) },
                    set: { value.wrappedValue = Int($0.rounded()) }
                ),
                in: 1...10,
                step: 1
            )
        }
    }

    private func label(_ id: String) -> String {
        response?.graph.nodes.first(where: { $0.id == id })?.label ?? id
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            response = try await session.personal.listWellness()
            if let latest = response?.checkIns.first {
                mood = latest.mood
                health = latest.health
                love = latest.love
                friendships = latest.friendships
                family = latest.family
            }
            errorMessage = nil
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func save() async {
        do {
            _ = try await session.personal.upsertWellness(
                UpsertWellnessRequest(
                    mood: mood,
                    health: health,
                    love: love,
                    friendships: friendships,
                    family: family,
                    note: note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : note,
                    checkedOn: nil
                )
            )
            note = ""
            await load()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}

struct WellnessCanvas: View {
    let graph: WellnessGraph

    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = min(geo.size.width, geo.size.height) * 0.34
            let positions: [String: CGPoint] = Dictionary(uniqueKeysWithValues: graph.nodes.enumerated().map { index, node in
                let angle = (Double(index) / Double(max(graph.nodes.count, 1))) * 2 * .pi - .pi / 2
                return (node.id, CGPoint(
                    x: center.x + CGFloat(cos(angle)) * radius,
                    y: center.y + CGFloat(sin(angle)) * radius
                ))
            })

            ZStack {
                ForEach(Array(graph.edges.enumerated()), id: \.offset) { _, edge in
                    if let a = positions[edge.from], let b = positions[edge.to] {
                        Path { path in
                            path.move(to: a)
                            path.addLine(to: b)
                        }
                        .stroke(Color.accentColor.opacity(0.25 + abs(edge.weight) * 0.5), lineWidth: 1 + CGFloat(abs(edge.weight)) * 3)
                    }
                }
                ForEach(graph.nodes) { node in
                    if let point = positions[node.id] {
                        VStack(spacing: 2) {
                            Circle()
                                .fill(Color.accentColor.opacity(0.15 + Double(node.value) / 20))
                                .frame(width: 18 + CGFloat(node.value), height: 18 + CGFloat(node.value))
                            Text(node.label)
                                .font(.caption2.weight(.semibold))
                            Text("\(node.value)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .position(point)
                    }
                }
            }
        }
    }
}
