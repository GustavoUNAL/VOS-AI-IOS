import SwiftUI

struct PersonalTasksView: View {
    @Environment(SessionStore.self) private var session
    @State private var day = Date()
    @State private var tasks: [TaskItem] = []
    @State private var title = ""
    @State private var errorMessage: String?
    @State private var isLoading = false

    private var isPersonal: Bool { AppModule.isPersonalCompany(session.user) }

    var body: some View {
        List {
            Section {
                ScreenIntro(text: isPersonal
                    ? "Pendientes del día. Aura también puede crearlos con “tarea: …”."
                    : "Pendientes del equipo y de la obra.")
            }

            Section("Día") {
                DatePicker("Fecha", selection: $day, displayedComponents: .date)
                    .onChange(of: day) { _, _ in
                        Task { await load() }
                    }
            }

            Section("Nueva tarea") {
                TextField("Qué tenés que hacer", text: $title)
                Button("Agregar") {
                    Task { await add() }
                }
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
            }

            if let errorMessage {
                Section { ScreenErrorText(message: errorMessage) }
            }

            Section("Pendientes") {
                if isLoading && tasks.isEmpty {
                    ProgressView()
                } else if tasks.isEmpty {
                    ScreenEmptyText(message: "Sin tareas para este día.")
                } else {
                    ForEach(tasks) { task in
                        HStack(alignment: .top) {
                            Button {
                                Task { await toggle(task) }
                            } label: {
                                Image(systemName: task.completed ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(task.completed ? AppTheme.accentMuted : Color.secondary)
                            }
                            .buttonStyle(.plain)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(task.title)
                                    .strikethrough(task.completed)
                                if let description = task.description, !description.isEmpty {
                                    Text(description)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .swipeActions {
                            Button("Borrar", role: .destructive) {
                                Task { await remove(task) }
                            }
                        }
                    }
                }
            }
        }
        .screenListChrome()
        .navigationTitle(isPersonal ? "Tiempo" : "Tareas")
        .task { await load() }
        .refreshable { await load() }
    }

    private var dayKey: String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = .current
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: day)
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            tasks = try await session.personal.listTasks(date: dayKey)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func add() async {
        let text = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            _ = try await session.personal.createTask(
                CreateTaskRequest(taskDate: dayKey, title: text, description: nil)
            )
            title = ""
            await load()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func toggle(_ task: TaskItem) async {
        do {
            _ = try await session.personal.updateTask(
                id: task.id,
                UpdateTaskRequest(title: nil, description: nil, completed: !task.completed)
            )
            await load()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func remove(_ task: TaskItem) async {
        do {
            try await session.personal.deleteTask(id: task.id)
            await load()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}
