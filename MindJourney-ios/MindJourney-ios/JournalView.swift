import SwiftUI

struct JournalEntryModel: Identifiable, Codable {
    var id: Int?
    var user_id: String?
    var title: String
    var content: String
    var created_at: String?
}

struct JournalView: View {
    @State private var entries: [JournalEntryModel] = []
    @State private var showingNewEntrySheet = false
    @State private var selectedEntryToEdit: JournalEntryModel? = nil
    @State private var isLoading = false
    @State private var userId = "user_123"

    var body: some View {
        NavigationStack {
            ZStack {
                Color("LavenderBG").opacity(0.15)
                    .ignoresSafeArea()

                if isLoading {
                    ProgressView("Loading entries...")
                        .tint(Color("DeepPurple"))
                } else if entries.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 50))
                            .foregroundColor(Color("DeepPurple").opacity(0.6))
                        Text("No Journal Entries Yet")
                            .font(.headline)
                            .foregroundColor(Color("DeepPurple"))
                        Text("Express your thoughts to keep track of your daily emotions.")
                            .font(.subheadline)
                            .foregroundColor(Color("MutedText"))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        
                        Button(action: { showingNewEntrySheet = true }) {
                            Text("Write Your First Entry")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 24)
                                .background(Color("DeepPurple"))
                                .cornerRadius(20)
                        }
                        .padding(.top, 8)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 14) {
                            ForEach(entries) { entry in
                                journalCard(entry: entry)
                                    .onTapGesture {
                                        selectedEntryToEdit = entry
                                    }
                            }
                        }
                        .padding(20)
                    }
                    .refreshable {
                        await fetchJournalEntries()
                    }
                }
            }
            .navigationTitle("My Journal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingNewEntrySheet = true }) {
                        Image(systemName: "square.and.pencil")
                            .foregroundColor(Color("DeepPurple"))
                    }
                }
            }
            .sheet(isPresented: $showingNewEntrySheet) {
                JournalEditorSheet(userId: userId) {
                    Task { await fetchJournalEntries() }
                }
            }
            .sheet(item: $selectedEntryToEdit) { entry in
                JournalEditorSheet(userId: userId, existingEntry: entry) {
                    Task { await fetchJournalEntries() }
                }
            }
            .task {
                await fetchJournalEntries()
            }
        }
    }

    @ViewBuilder
    private func journalCard(entry: JournalEntryModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(entry.title)
                    .font(.headline)
                    .foregroundColor(Color("DeepPurple"))
                Spacer()
                Text(formatDate(entry.created_at))
                    .font(.caption2)
                    .foregroundColor(Color("MutedText"))
            }

            Text(entry.content)
                .font(.subheadline)
                .foregroundColor(.primary.opacity(0.8))
                .lineLimit(3)
                .multilineTextAlignment(.leading)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color("DeepPurple").opacity(0.06), radius: 8, x: 0, y: 3)
    }

    private func formatDate(_ rawDate: String?) -> String {
        guard let rawDate = rawDate else { return "Just now" }
        return String(rawDate.prefix(10))
    }

    private func fetchJournalEntries() async {
        isLoading = true
        defer { isLoading = false }
        guard let url = URL(string: "http://127.0.0.1:5001/api/journals") else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let decoded = try? JSONDecoder().decode([JournalEntryModel].self, from: data) {
                DispatchQueue.main.async {
                    self.entries = decoded
                }
            }
        } catch {
            print("Error fetching journals: \(error)")
        }
    }
}

struct JournalEditorSheet: View {
    @Environment(\.dismiss) var dismiss
    var userId: String
    var existingEntry: JournalEntryModel? = nil
    var onSave: () -> Void

    @State private var title: String = ""
    @State private var content: String = ""
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                TextField("Title", text: $title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .padding(12)
                    .background(Color("LavenderBG").opacity(0.3))
                    .cornerRadius(12)

                TextEditor(text: $content)
                    .font(.body)
                    .padding(8)
                    .background(Color("LavenderBG").opacity(0.2))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                    )

                Spacer()
            }
            .padding(20)
            .navigationTitle(existingEntry == nil ? "New Entry" : "Edit Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: saveEntry) {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Save")
                                .fontWeight(.bold)
                                .foregroundColor(Color("DeepPurple"))
                        }
                    }
                    .disabled(title.isEmpty || content.isEmpty)
                }
            }
            .onAppear {
                if let entry = existingEntry {
                    title = entry.title
                    content = entry.content
                }
            }
        }
    }

    private func saveEntry() {
        guard let url = URL(string: "http://127.0.0.1:5001/api/journal") else { return }
        isSaving = true

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "user_id": userId,
            "title": title,
            "content": content
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { _, _, _ in
            DispatchQueue.main.async {
                isSaving = false
                onSave()
                dismiss()
            }
        }.resume()
    }
}
