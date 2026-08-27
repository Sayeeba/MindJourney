import SwiftUI

struct EmergencyService: Codable, Identifiable {
    let name: String
    let number: String
    let description: String
    var id: String { name }
    var callURL: URL? { URL(string: "tel://\(number.filter { $0.isNumber || $0 == "+" })") }
}

struct EmergencyContact: Codable, Identifiable {
    let contact_id: Int
    let name: String
    let relationship: String
    let phone: String
    var id: Int { contact_id }
}

struct EmergencyResponse: Codable { let services: [EmergencyService]; let contacts: [EmergencyContact] }

struct EmergencyServicesView: View {
    @AppStorage("userId") private var userId = 0
    @State private var data: EmergencyResponse?
    @State private var name = ""
    @State private var relationship = ""
    @State private var phone = ""
    @State private var showForm = false

    var body: some View {
        NavigationStack {
            List {
                Section("Immediate help") {
                    Text("If someone is in immediate danger, call local emergency services now. MindJourney is not a replacement for professional emergency care.")
                        .foregroundStyle(.red)
                }
                Section("Emergency services") {
                    ForEach(data?.services ?? []) { service in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(service.name).font(.headline)
                                Spacer()
                                if let callURL = service.callURL { Link(service.number, destination: callURL) }
                            }
                            Text(service.description).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                Section("Trusted contacts") {
                    ForEach(data?.contacts ?? []) { contact in
                        VStack(alignment: .leading) {
                            Text(contact.name).font(.headline)
                            Text("\(contact.relationship) · \(contact.phone)").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    Button("Add trusted contact") { showForm = true }
                }
            }
            .navigationTitle("Emergency Services")
            .task { await load() }
            .refreshable { await load() }
            .sheet(isPresented: $showForm) { contactForm }
        }
    }

    private var contactForm: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                TextField("Relationship", text: $relationship)
                TextField("Phone", text: $phone).keyboardType(.phonePad)
            }
            .navigationTitle("Trusted Contact")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showForm = false } }
                ToolbarItem(placement: .confirmationAction) { Button("Save", action: save).disabled(name.isEmpty || relationship.isEmpty || phone.isEmpty) }
            }
        }
    }

    private func load() async {
        guard let url = URL(string: "http://127.0.0.1:5001/api/emergency/\(userId)") else { return }
        guard let (raw, _) = try? await URLSession.shared.data(from: url) else { return }
        data = try? JSONDecoder().decode(EmergencyResponse.self, from: raw)
    }

    private func save() {
        guard let url = URL(string: "http://127.0.0.1:5001/api/emergency/contacts") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["user_id": userId, "name": name, "relationship": relationship, "phone": phone])
        URLSession.shared.dataTask(with: request) { _, _, _ in
            DispatchQueue.main.async {
                showForm = false; name = ""; relationship = ""; phone = ""
                Task { await load() }
            }
        }.resume()
    }
}
