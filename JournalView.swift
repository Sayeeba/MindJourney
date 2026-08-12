import SwiftUI

struct JournalEntryModel: Identifiable, Codable {
    let id: Int
    let user_id: Int
    var title: String
    var content: String
    let created_at: String
    let updated_at: String?
}

struct JournalPayload: Encodable {
    let user_id: Int
    let title: String
    let content: String
}

struct JournalView: View {
    @AppStorage("userId") private var userId = 0
    @State private var entries: [JournalEntryModel] = []
    @State private var showingEditor = false
    @State private var editingEntry: JournalEntryModel?
    @State private var isLoading = true
    @State private var error = ""
    @State private var showError = false

    var body: some View {
        NavigationStack {
            Group {
                if isLoading { ProgressView("Loading journal...") }
                else if entries.isEmpty { emptyState }
                else {
                    List {
                        ForEach(entries) { entry in
                            VStack(alignment: .leading, spacing: 7) {
                                HStack {
                                    Text(entry.title).font(.headline).foregroundStyle(AppConfig.deepPurple)
                                    Spacer(); Text(date(entry.created_at)).font(.caption2).foregroundStyle(AppConfig.muted)
                                }
                                Text(entry.content).font(.subheadline).lineLimit(4).foregroundStyle(.primary.opacity(0.8))
                            }
                            .padding(.vertical, 8)
                            .contentShape(Rectangle())
                            .onTapGesture { editingEntry = entry }
                            .swipeActions {
                                Button(role: .destructive) { delete(entry) } label: { Label("Delete", systemImage: "trash") }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .refreshable { await load() }
                }
            }
            .navigationTitle("My Journal")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button { editingEntry = nil; showingEditor = true } label: { Image(systemName: "square.and.pencil") } } }
            .sheet(isPresented: $showingEditor) { JournalEditorView(existing: nil) { Task { await load() } } }
            .sheet(item: $editingEntry) { entry in JournalEditorView(existing: entry) { Task { await load() } } }
            .alert("Journal", isPresented: $showError) { Button("OK", role: .cancel) { } } message: { Text(error) }
            .task { await load() }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "book.closed").font(.system(size: 48)).foregroundStyle(AppConfig.lavender)
            Text("Your journal is empty").font(.title3.bold()).foregroundStyle(AppConfig.deepPurple)
            Text("Write honestly. This space is for reflection, not perfection.").multilineTextAlignment(.center).foregroundStyle(AppConfig.muted)
            Button("Write your first entry") { showingEditor = true }.buttonStyle(PrimaryButtonStyle())
        }.padding(30)
    }

    private func load() async {
        guard userId > 0 else { return }
        isLoading = true; defer { isLoading = false }
        do { entries = try await APIClient.request("/api/journals/\(userId)") }
        catch { error = error.localizedDescription; showError = true }
    }

    private func delete(_ entry: JournalEntryModel) {
        Task {
            do {
                try await APIClient.requestNoContent("/api/journal/\(entry.id)?user_id=\(userId)")
                await load()
            } catch { error = error.localizedDescription; showError = true }
        }
    }

    private func date(_ raw: String) -> String { String(raw.prefix(10)) }
}

struct JournalEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("userId") private var userId = 0
    let existing: JournalEntryModel?
    let onSaved: () -> Void
    @State private var title = ""
    @State private var content = ""
    @State private var saving = false
    @State private var error = ""
    @State private var showError = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                TextField("Entry title", text: $title).font(.title3.bold()).appField()
                TextEditor(text: $content).padding(10).scrollContentBackground(.hidden).background(AppConfig.softLavender.opacity(0.5)).clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(20)
            .navigationTitle(existing == nil ? "New Entry" : "Edit Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button { save() } label: { if saving { ProgressView() } else { Text("Save").bold() } }.disabled(title.trimmed.isEmpty || content.trimmed.isEmpty || saving)
                }
            }
            .onAppear { if let existing { title = existing.title; content = existing.content } }
            .alert("Could not save", isPresented: $showError) { Button("OK", role: .cancel) { } } message: { Text(error) }
        }
    }

    private func save() {
        saving = true
        Task {
            do {
                let payload = JournalPayload(user_id: userId, title: title.trimmed, content: content.trimmed)
                if let existing {
                    let _: SimpleResponse = try await APIClient.request("/api/journal/\(existing.id)", method: "PUT", body: payload)
                } else {
                    let _: SimpleResponse = try await APIClient.request("/api/journal", method: "POST", body: payload)
                }
                onSaved(); dismiss()
            } catch { error = error.localizedDescription; showError = true }
            saving = false
        }
    }
}

extension String { var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) } }
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View { configuration.label.fontWeight(.bold).foregroundStyle(.white).padding(.horizontal, 20).padding(.vertical, 12).background(AppConfig.deepPurple.opacity(configuration.isPressed ? 0.7 : 1)).clipShape(Capsule()) }
}

#Preview { JournalView() }
