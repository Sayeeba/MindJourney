import SwiftUI

// MARK: - Profile

struct ProfileResponse: Decodable {
    let user_id: Int
    let full_name: String
    let email: String
    let age: Int?
    let gender: String?
    let created_at: String
}

struct ProfileView: View {
    @AppStorage("userId") private var userId = 0
    @AppStorage("userName") private var userName = ""
    @AppStorage("userEmail") private var userEmail = ""
    @State private var profile: ProfileResponse?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    Image(systemName: "person.crop.circle.fill").font(.system(size: 90)).foregroundStyle(AppConfig.lavender)
                    Text(profile?.full_name ?? userName).font(.title2.bold()).foregroundStyle(AppConfig.deepPurple)
                    Text(profile?.email ?? userEmail).foregroundStyle(AppConfig.muted)
                    if let profile {
                        InfoRow(label: "Age", value: profile.age.map(String.init) ?? "—")
                        InfoRow(label: "Gender", value: profile.gender ?? "—")
                        InfoRow(label: "Member since", value: String(profile.created_at.prefix(10)))
                    }
                    Text("Your MindJourney data is associated with your account so your mood history, journal, and chat records stay separated from other users.")
                        .font(.footnote).foregroundStyle(AppConfig.muted).multilineTextAlignment(.center).padding()
                }.padding(24)
            }.navigationTitle("Profile")
            .task {
                if userId > 0 { profile = try? await APIClient.request("/api/profile/\(userId)") }
            }
        }
    }
}

struct InfoRow: View { let label: String; let value: String; var body: some View { HStack { Text(label).foregroundStyle(AppConfig.muted); Spacer(); Text(value).fontWeight(.semibold).foregroundStyle(AppConfig.deepPurple) }.padding(15).background(AppConfig.softLavender).clipShape(RoundedRectangle(cornerRadius: 12)) } }

// MARK: - Meditation

struct MeditationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var running = false
    @State private var seconds = 60
    @State private var breathScale: CGFloat = 1
    @State private var timer: Timer?

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                Text("One-minute reset").font(.title2.bold()).foregroundStyle(AppConfig.deepPurple)
                Text(seconds > 0 ? "Breathe in gently, pause, then breathe out slowly." : "Well done. Notice how you feel now.")
                    .multilineTextAlignment(.center).foregroundStyle(AppConfig.muted)
                ZStack {
                    Circle().fill(AppConfig.softLavender).frame(width: 230, height: 230)
                    Circle().fill(AppConfig.lavender.opacity(0.45)).frame(width: 150 * breathScale, height: 150 * breathScale)
                    Text(seconds > 0 ? "\(seconds)" : "✓").font(.system(size: 48, weight: .bold)).foregroundStyle(AppConfig.deepPurple)
                }
                HStack(spacing: 14) {
                    Button(running ? "Pause" : "Start") { running.toggle(); if running { startTimer() } else { timer?.invalidate() } }.buttonStyle(PrimaryButtonStyle())
                    Button("Reset") { reset() }.buttonStyle(.bordered)
                }
                Spacer()
            }.padding(30).navigationTitle("Meditation").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { timer?.invalidate(); dismiss() } } }
            .onDisappear { timer?.invalidate() }
        }
    }

    private func startTimer() {
        timer?.invalidate()
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) { breathScale = 1.18 }
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if seconds > 0 { seconds -= 1 } else { running = false; timer?.invalidate(); breathScale = 1 }
        }
    }
    private func reset() { timer?.invalidate(); running = false; seconds = 60; breathScale = 1 }
}

// MARK: - Community

struct CommunityPost: Decodable, Identifiable { let post_id: Int; let body: String; let created_at: String; let full_name: String; var id: Int { post_id } }
struct CommunityPostRequest: Encodable { let user_id: Int; let body: String }

struct CommunityView: View {
    @AppStorage("userId") private var userId = 0
    @State private var posts: [CommunityPost] = []
    @State private var newPost = ""
    @State private var loading = true
    @State private var posting = false

    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    TextField("Share an encouraging thought...", text: $newPost, axis: .vertical).lineLimit(1...4).appField()
                    Button { post() } label: { Image(systemName: "paperplane.fill").foregroundStyle(.white).padding(12).background(AppConfig.deepPurple).clipShape(Circle()) }.disabled(newPost.trimmed.isEmpty || posting)
                }.padding(.horizontal).padding(.top, 8)
                if loading { ProgressView("Loading community...").padding(.top, 30) }
                else {
                    List(posts) { post in
                        VStack(alignment: .leading, spacing: 7) {
                            Text(post.full_name).font(.headline).foregroundStyle(AppConfig.deepPurple)
                            Text(post.body).foregroundStyle(.primary)
                            Text(String(post.created_at.prefix(16))).font(.caption2).foregroundStyle(AppConfig.muted)
                        }.padding(.vertical, 5)
                    }.listStyle(.plain)
                }
            }.navigationTitle("Community")
            .task { await load() }
            .refreshable { await load() }
        }
    }

    private func load() async { do { posts = try await APIClient.request("/api/community/posts") } catch { } ; loading = false }
    private func post() {
        guard userId > 0 else { return }; posting = true
        Task { do { let _: SimpleResponse = try await APIClient.request("/api/community/posts", method: "POST", body: CommunityPostRequest(user_id: userId, body: newPost.trimmed)); newPost = ""; await load() } catch { } ; posting = false }
    }
}

// MARK: - Professional Help

struct ProfessionalHelpView: View {
    private let options = [
        ("Campus counseling", "Start with your university counseling or student support service. They can assess your needs and guide you to appropriate care."),
        ("Licensed psychologist", "A psychologist can help with stress, anxiety, mood changes, relationships, and coping skills."),
        ("Psychiatrist", "A psychiatrist is a medical doctor who can evaluate mental-health conditions and discuss treatment options."),
        ("Trusted person", "If professional care feels difficult to arrange, tell a trusted friend, family member, teacher, or mentor how you are doing.")
    ]
    var body: some View {
        NavigationStack {
            List(options, id: \.0) { item in
                VStack(alignment: .leading, spacing: 7) { Text(item.0).font(.headline).foregroundStyle(AppConfig.deepPurple); Text(item.1).font(.subheadline).foregroundStyle(AppConfig.muted) }.padding(.vertical, 7)
            }.navigationTitle("Professional Help")
        }
    }
}

// MARK: - Helpline

struct HelplineView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ResourceBox(icon: "🚨", title: "Immediate danger", text: "If you or someone else may be in immediate danger, move to a safer place and contact your local emergency services now.")
                    ResourceBox(icon: "🧑‍🤝‍🧑", title: "Trusted person", text: "Call or sit with someone you trust. You do not need to explain everything perfectly—just tell them you need support.")
                    ResourceBox(icon: "🏫", title: "Campus support", text: "Use your university's counseling, student affairs, or medical service for local support and referrals.")
                    ResourceBox(icon: "🌍", title: "Crisis resources", text: "MindJourney does not replace emergency or professional care. Use a verified local crisis service for your country when urgent support is needed.")
                }.padding(20)
            }.navigationTitle("Safety & Helpline")
        }
    }
}
struct ResourceBox: View { let icon: String; let title: String; let text: String; var body: some View { VStack(alignment: .leading, spacing: 8) { Text("\(icon)  \(title)").font(.headline).foregroundStyle(AppConfig.deepPurple); Text(text).foregroundStyle(AppConfig.muted) }.padding(18).frame(maxWidth: .infinity, alignment: .leading).background(.white).clipShape(RoundedRectangle(cornerRadius: 18)) } }

// MARK: - Safe Haven

struct SafeHavenView: View {
    @State private var selected = "Quiet room"
    private let ideas = [
        ("Quiet room", "Dim the lights, silence notifications, and give yourself 10 minutes without demands."),
        ("Outdoor reset", "Sit somewhere safe with fresh air. Notice five things you can see, four you can touch, and three you can hear."),
        ("Comfort corner", "Keep water, a blanket, headphones, a book, and one calming activity in one place."),
        ("Digital break", "Put non-essential notifications on pause for 20–30 minutes while you rest or journal.")
    ]
    var body: some View {
        NavigationStack {
            List {
                Section("Choose a safe space idea") {
                    ForEach(ideas, id: \.0) { idea in
                        Button { selected = idea.0 } label: { HStack { Text(idea.0).foregroundStyle(AppConfig.deepPurple); Spacer(); if selected == idea.0 { Image(systemName: "checkmark.circle.fill") } } }
                    }
                }
                if let idea = ideas.first(where: { $0.0 == selected }) { Section("Your plan") { Text(idea.1).foregroundStyle(AppConfig.muted) } }
            }.navigationTitle("Safe Haven")
        }
    }
}

// MARK: - Group Trip

struct GroupTripView: View {
    private let trips = [
        ("Sunrise walk", "Easy • 45 min", "A low-pressure outdoor walk focused on fresh air and conversation."),
        ("Mindful picnic", "Relaxed • 1–2 hrs", "Bring water and food, leave phones away for a short period, and spend time with friends."),
        ("Nature afternoon", "Moderate • 2–3 hrs", "A small group outing with a simple plan, check-in time, and a safe return route.")
    ]
    var body: some View {
        NavigationStack {
            List(trips, id: \.0) { trip in
                VStack(alignment: .leading, spacing: 8) { HStack { Text(trip.0).font(.headline).foregroundStyle(AppConfig.deepPurple); Spacer(); Text(trip.1).font(.caption).foregroundStyle(AppConfig.muted) }; Text(trip.2).foregroundStyle(AppConfig.muted) }.padding(.vertical, 8)
            }.navigationTitle("Mindful Group Trips")
        }
    }
}

#Preview { ProfileView() }
