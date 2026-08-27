import SwiftUI

struct Activity: Codable, Identifiable { let id: String; let title: String; let detail: String; let description: String; let joined: Bool }
struct JoinPayload: Encodable { let user_id: Int }
struct BasicReply: Decodable { let message: String }

struct ActivityListView: View {
    let title: String; let icon: String; let endpoint: String
    @AppStorage("userId") private var userId = 0
    @State private var activities: [Activity] = []; @State private var loading = true; @State private var message = ""
    var body: some View { NavigationStack { Group { if loading { ProgressView("Loading...") } else if activities.isEmpty { ContentUnavailableView("Nothing planned yet", systemImage: "calendar") } else { List(activities) { activity in VStack(alignment: .leading, spacing: 8) { HStack { Text(activity.title).font(.headline).foregroundStyle(Color("DeepPurple")); Spacer(); Text(activity.detail).font(.caption).foregroundStyle(.secondary) }; Text(activity.description).font(.subheadline).foregroundStyle(.secondary); Button(activity.joined ? "Joined" : "Join") { join(activity) }.buttonStyle(activity.joined ? .bordered : .borderedProminent).tint(Color("DeepPurple")).disabled(activity.joined) }.padding(.vertical, 5) }.listStyle(.plain) } }.navigationTitle(title).toolbar { ToolbarItem(placement: .topBarTrailing) { Text(icon).font(.title2) } }.task { await load() }.alert("MindJourney", isPresented: Binding(get: { !message.isEmpty }, set: { if !$0 { message = "" } })) { Button("OK") { message = "" } } message: { Text(message) } } }
    private func load() async { guard let url = URL(string: "http://127.0.0.1:5001\(endpoint)/\(userId)") else { return }; do { let (data, _) = try await URLSession.shared.data(from: url); activities = try JSONDecoder().decode([Activity].self, from: data) } catch { message = "Could not load opportunities. Start the MindJourney API first." }; loading = false }
    private func join(_ activity: Activity) { guard let url = URL(string: "http://127.0.0.1:5001\(endpoint)/\(activity.id)/join") else { return }; var request = URLRequest(url: url); request.httpMethod = "POST"; request.setValue("application/json", forHTTPHeaderField: "Content-Type"); request.httpBody = try? JSONEncoder().encode(JoinPayload(user_id: userId)); URLSession.shared.dataTask(with: request) { _, response, _ in DispatchQueue.main.async { if (response as? HTTPURLResponse)?.statusCode == 200 { message = "You're signed up!"; Task { await load() } } else { message = "We could not save your sign-up." } } }.resume() }
}

struct GroupTripView: View { var body: some View { ActivityListView(title: "Mindful Group Trips", icon: "🏕️", endpoint: "/api/trips") } }
struct CommunityServiceView: View { var body: some View { ActivityListView(title: "Community Service", icon: "🌟", endpoint: "/api/community-service") } }

struct CommunityPost: Codable, Identifiable { let post_id: Int; let body: String; let created_at: String; let full_name: String; var id: Int { post_id } }
struct CommunityView: View {
    @AppStorage("userId") private var userId = 0
    @State private var posts: [CommunityPost] = []; @State private var text = ""; @State private var loading = true
    var body: some View { NavigationStack { VStack { HStack { TextField("Share an encouraging thought…", text: $text, axis: .vertical).lineLimit(1...3).textFieldStyle(.roundedBorder); Button("Post", action: post).disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty).buttonStyle(.borderedProminent).tint(Color("DeepPurple")) }.padding(); if loading { ProgressView() } else { List(posts) { post in VStack(alignment: .leading, spacing: 6) { Text(post.full_name).font(.headline).foregroundStyle(Color("DeepPurple")); Text(post.body); Text(String(post.created_at.prefix(16))).font(.caption2).foregroundStyle(.secondary) }.padding(.vertical, 4) }.listStyle(.plain) } }.navigationTitle("Community").task { await load() }.refreshable { await load() } } }
    private func load() async { guard let url = URL(string: "http://127.0.0.1:5001/api/community/posts") else { return }; do { let (data, _) = try await URLSession.shared.data(from: url); posts = try JSONDecoder().decode([CommunityPost].self, from: data) } catch {} ; loading = false }
    private func post() { let body = text.trimmingCharacters(in: .whitespacesAndNewlines); var request = URLRequest(url: URL(string: "http://127.0.0.1:5001/api/community/posts")!); request.httpMethod = "POST"; request.setValue("application/json", forHTTPHeaderField: "Content-Type"); request.httpBody = try? JSONSerialization.data(withJSONObject: ["user_id": userId, "body": body]); URLSession.shared.dataTask(with: request) { _, _, _ in DispatchQueue.main.async { text = ""; Task { await load() } } }.resume() }
}

struct EmergencyService: Codable, Identifiable {
    let name: String
    let number: String
    let description: String

    var id: String { name }
    var callURL: URL? {
        let dialableNumber = number.filter { $0.isNumber || $0 == "+" }
        return URL(string: "tel://\(dialableNumber)")
    }
}
struct EmergencyContact: Codable, Identifiable { let contact_id: Int; let name: String; let relationship: String; let phone: String; var id: Int { contact_id } }
struct EmergencyResponse: Codable { let services: [EmergencyService]; let contacts: [EmergencyContact] }
struct EmergencyServicesView: View {
    @AppStorage("userId") private var userId = 0
    @State private var data: EmergencyResponse?; @State private var name = ""; @State private var relationship = ""; @State private var phone = ""; @State private var showForm = false
    var body: some View { NavigationStack { List { Section { Text("If someone is in immediate danger, call local emergency services now. MindJourney is not a replacement for professional emergency care.").foregroundStyle(.red) } header: { Text("Immediate help") }; Section("Emergency services") { ForEach(data?.services ?? []) { service in VStack(alignment: .leading, spacing: 6) { HStack { Text(service.name).font(.headline); Spacer(); if let callURL = service.callURL { Link(service.number, destination: callURL).font(.headline).foregroundStyle(Color("DeepPurple")) } else { Text(service.number).font(.headline).foregroundStyle(Color("DeepPurple")) } }; Text(service.description).font(.caption).foregroundStyle(.secondary); if let callURL = service.callURL { Link("Call \(service.number)", destination: callURL).buttonStyle(.borderedProminent).tint(Color("DeepPurple")) } } .padding(.vertical, 3) } }; Section("Trusted contacts") { ForEach(data?.contacts ?? []) { contact in VStack(alignment: .leading) { Text(contact.name).font(.headline); Text("\(contact.relationship) · \(contact.phone)").font(.caption).foregroundStyle(.secondary) } }; Button("Add trusted contact") { showForm = true } } }.navigationTitle("Emergency Services").task { await load() }.sheet(isPresented: $showForm) { contactForm }.refreshable { await load() } } }
    private var contactForm: some View { NavigationStack { Form { TextField("Name", text: $name); TextField("Relationship", text: $relationship); TextField("Phone", text: $phone).keyboardType(.phonePad) }.navigationTitle("Trusted Contact").toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showForm = false } }; ToolbarItem(placement: .confirmationAction) { Button("Save", action: save).disabled(name.isEmpty || relationship.isEmpty || phone.isEmpty) } } } }
    private func load() async { guard let url = URL(string: "http://127.0.0.1:5001/api/emergency/\(userId)") else { return }; do { let (raw, _) = try await URLSession.shared.data(from: url); data = try JSONDecoder().decode(EmergencyResponse.self, from: raw) } catch {} }
    private func save() { var request = URLRequest(url: URL(string: "http://127.0.0.1:5001/api/emergency/contacts")!); request.httpMethod = "POST"; request.setValue("application/json", forHTTPHeaderField: "Content-Type"); request.httpBody = try? JSONSerialization.data(withJSONObject: ["user_id": userId, "name": name, "relationship": relationship, "phone": phone]); URLSession.shared.dataTask(with: request) { _, _, _ in DispatchQueue.main.async { showForm = false; name = ""; relationship = ""; phone = ""; Task { await load() } } }.resume() }
}
