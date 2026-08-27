import SwiftUI

struct MoodLog: Decodable, Identifiable {
    let id: Int
    let mood: String
    let note: String
    let timestamp: String
}

struct MoodLogView: View {
    @AppStorage("userId") private var userId = 0
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMood = ""
    @State private var note = ""
    @State private var logs: [MoodLog] = []
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var notice = ""

    private let moods = [("😃", "Happy"), ("😌", "Calm"), ("😐", "Okay"), ("😔", "Sad"), ("😰", "Anxious")]

    var body: some View {
        NavigationStack {
            List {
                Section("Today's check-in") {
                    Text("Choose the feeling that fits best right now. You can add a private note if it helps.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 4) {
                        ForEach(moods, id: \.1) { mood in
                            Button {
                                selectedMood = mood.1
                            } label: {
                                VStack(spacing: 3) {
                                    Text(mood.0).font(.title2)
                                    Text(mood.1).font(.caption2)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                                .background(selectedMood == mood.1 ? Color("LavenderBG").opacity(0.7) : .clear)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(mood.1)
                        }
                    }

                    TextField("Optional note", text: $note, axis: .vertical)
                        .lineLimit(1...4)
                    Button(isSaving ? "Saving…" : "Save mood", action: save)
                        .disabled(selectedMood.isEmpty || isSaving)
                        .frame(maxWidth: .infinity)
                        .buttonStyle(.borderedProminent)
                        .tint(Color("DeepPurple"))
                }

                Section("Recent check-ins") {
                    if isLoading {
                        HStack { Spacer(); ProgressView(); Spacer() }
                    } else if logs.isEmpty {
                        Text("Your saved mood check-ins will appear here.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(logs) { log in
                            HStack(alignment: .top, spacing: 12) {
                                Text(emoji(for: log.mood)).font(.title2)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(log.mood).font(.headline)
                                    if !log.note.isEmpty { Text(log.note).font(.subheadline) }
                                    Text(formatted(log.timestamp)).font(.caption).foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
            .navigationTitle("Mood Logs")
            .toolbar { ToolbarItem(placement: .topBarLeading) { Button("Done") { dismiss() } } }
            .task { await load() }
            .refreshable { await load() }
            .alert("MindJourney", isPresented: Binding(get: { !notice.isEmpty }, set: { if !$0 { notice = "" } })) {
                Button("OK") { notice = "" }
            } message: { Text(notice) }
        }
    }

    private func load() async {
        guard userId > 0, let url = URL(string: "http://127.0.0.1:5001/api/mood/logs/\(userId)") else {
            isLoading = false
            return
        }
        defer { isLoading = false }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
            logs = try JSONDecoder().decode([MoodLog].self, from: data)
        } catch {
            notice = "Could not load your mood logs. Make sure the API is running."
        }
    }

    private func save() {
        guard userId > 0 else { notice = "Please sign in again before saving a mood."; return }
        isSaving = true
        var request = URLRequest(url: URL(string: "http://127.0.0.1:5001/api/mood/log")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["user_id": userId, "mood": selectedMood, "note": note])
        URLSession.shared.dataTask(with: request) { _, response, _ in
            DispatchQueue.main.async {
                isSaving = false
                guard let response = response as? HTTPURLResponse, (200...299).contains(response.statusCode) else {
                    notice = "Could not save your mood. Please try again."
                    return
                }
                notice = "Your \(selectedMood.lowercased()) mood was saved."
                selectedMood = ""
                note = ""
                Task { await load() }
            }
        }.resume()
    }

    private func emoji(for mood: String) -> String {
        moods.first(where: { $0.1 == mood })?.0 ?? "💭"
    }

    private func formatted(_ timestamp: String) -> String {
        String(timestamp.prefix(16)).replacingOccurrences(of: "T", with: " · ")
    }
}

#Preview {
    MoodLogView()
}
