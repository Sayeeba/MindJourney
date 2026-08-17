import SwiftUI

struct HomeView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @AppStorage("userId") private var userId = 0
    @AppStorage("userName") private var userName = ""
    @AppStorage("userEmail") private var userEmail = ""

    @State private var selectedMood = ""
    @State private var moodNote = ""
    @State private var showMoodNote = false
    @State private var insightTitle = "✨ Start your emotional journey"
    @State private var insightMessage = "Log a mood to receive personalized pattern insights."
    @State private var insightAction = "Log a mood"
    @State private var insightTarget = "mood"
    @State private var activeFeature: Feature?
    @State private var showLogout = false
    @State private var toast = ""

    enum Feature: String, Identifiable {
        case profile, dashboard, journal, chat, community, psychiatrist, helpline, safeHaven, meditation, groupTrip
        var id: String { rawValue }
    }

    private let moods = [("😃", "Happy"), ("😌", "Calm"), ("😐", "Okay"), ("😔", "Sad"), ("😰", "Anxious")]

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    header
                    welcomeCard
                    moodCard
                    insightCard
                    featureGrid
                    Button("Log out") { showLogout = true }
                        .foregroundStyle(.red)
                        .padding(.vertical, 10)
                    Spacer(minLength: 30)
                }
                .padding(.top, 10)
            }
            .background(AppConfig.softLavender.opacity(0.35).ignoresSafeArea())
            .sheet(item: $activeFeature) { feature in destination(for: feature) }
            .alert("Log out?", isPresented: $showLogout) {
                Button("Cancel", role: .cancel) { }
                Button("Log out", role: .destructive) {
                    isLoggedIn = false; userId = 0; userName = ""; userEmail = ""
                }
            }
            .alert("Mood saved", isPresented: Binding(get: { !toast.isEmpty }, set: { if !$0 { toast = "" } })) {
                Button("OK") { toast = "" }
            } message: { Text(toast) }
            .task { await loadInsight() }
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image("BrandIcon").resizable().scaledToFit().frame(width: 42, height: 42)
            Image("MindJourney").resizable().scaledToFit().frame(width: 125, height: 35)
            Spacer()
            Button { activeFeature = .profile } label: {
                Image(systemName: "person.crop.circle.fill").font(.system(size: 32)).foregroundStyle(AppConfig.deepPurple)
            }
        }.padding(.horizontal, 20)
    }

    private var welcomeCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Hello, \(userName.isEmpty ? "there" : userName.split(separator: " ").first.map(String.init) ?? "there") 👋")
                .font(.title2.bold()).foregroundStyle(AppConfig.deepPurple)
            Text("Take a moment to check in with yourself today.")
                .foregroundStyle(AppConfig.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20).background(.white).clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, 20)
    }

    private var moodCard: some View {
        VStack(spacing: 14) {
            Text("How are you feeling today?").font(.headline).foregroundStyle(AppConfig.deepPurple)
            HStack(spacing: 6) {
                ForEach(moods, id: \.1) { mood in
                    Button {
                        selectedMood = mood.1
                        showMoodNote = true
                    } label: {
                        VStack(spacing: 5) {
                            Text(mood.0).font(.system(size: 34))
                            Text(mood.1).font(.caption2).fontWeight(selectedMood == mood.1 ? .bold : .regular)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 8)
                        .background(selectedMood == mood.1 ? AppConfig.softLavender : .clear)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .foregroundStyle(AppConfig.deepPurple)
                }
            }
            if showMoodNote {
                TextField("Optional note: what is influencing your mood?", text: $moodNote)
                    .appField()
                Button("Save \(selectedMood) mood") { saveMood() }
                    .fontWeight(.bold).foregroundStyle(.white).frame(maxWidth: .infinity).padding()
                    .background(AppConfig.deepPurple).clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(20).background(.white).clipShape(RoundedRectangle(cornerRadius: 20)).padding(.horizontal, 20)
    }

    private var insightCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(insightTitle).font(.headline).foregroundStyle(AppConfig.deepPurple)
            Text(insightMessage).font(.subheadline).foregroundStyle(AppConfig.muted).fixedSize(horizontal: false, vertical: true)
            Button(insightAction) {
                if insightTarget == "meditation" { activeFeature = .meditation }
                else if insightTarget == "journal" { activeFeature = .journal }
                else { showMoodNote = true }
            }
            .fontWeight(.bold).foregroundStyle(AppConfig.deepPurple)
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(20).background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20)).padding(.horizontal, 20)
    }

    private var featureGrid: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Explore & Connect").font(.title3.bold()).foregroundStyle(AppConfig.deepPurple).padding(.horizontal, 20)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                FeatureCard(icon: "📔", title: "Journal", subtitle: "Write & reflect") { activeFeature = .journal }
                FeatureCard(icon: "🤖", title: "AI Assistant", subtitle: "Talk through a moment") { activeFeature = .chat }
                FeatureCard(icon: "📊", title: "Dashboard", subtitle: "See mood patterns") { activeFeature = .dashboard }
                FeatureCard(icon: "🧘", title: "Meditation", subtitle: "Guided breathing") { activeFeature = .meditation }
                FeatureCard(icon: "🤝", title: "Community", subtitle: "Supportive posts") { activeFeature = .community }
                FeatureCard(icon: "🩺", title: "Professional Help", subtitle: "Find support") { activeFeature = .psychiatrist }
                FeatureCard(icon: "📞", title: "Helpline", subtitle: "Safety resources") { activeFeature = .helpline }
                FeatureCard(icon: "🌿", title: "Safe Haven", subtitle: "Create a calm space") { activeFeature = .safeHaven }
                FeatureCard(icon: "🏕️", title: "Group Trip", subtitle: "Plan a mindful outing") { activeFeature = .groupTrip }
            }.padding(.horizontal, 20)
        }
    }

    @ViewBuilder
    private func destination(for feature: Feature) -> some View {
        switch feature {
        case .profile: ProfileView()
        case .dashboard: DashboardView()
        case .journal: JournalView()
        case .chat: ChatBotView()
        case .community: CommunityView()
        case .psychiatrist: ProfessionalHelpView()
        case .helpline: HelplineView()
        case .safeHaven: SafeHavenView()
        case .meditation: MeditationView()
        case .groupTrip: GroupTripView()
        }
    }

    private func saveMood() {
        guard userId > 0, !selectedMood.isEmpty else { return }
        Task {
            do {
                let _: SimpleResponse = try await APIClient.request("/api/mood/log", method: "POST", body: MoodRequest(user_id: userId, mood: selectedMood, note: moodNote))
                toast = "Your \(selectedMood) mood was saved."
                moodNote = ""; showMoodNote = false
                await loadInsight()
            } catch { toast = error.localizedDescription }
        }
    }

    private func loadInsight() async {
        guard userId > 0 else { return }
        do {
            let data: InsightResponse = try await APIClient.request("/api/home/insight/\(userId)")
            insightTitle = data.title; insightMessage = data.message; insightAction = data.action; insightTarget = data.target
        } catch { }
    }
}

struct MoodRequest: Encodable { let user_id: Int; let mood: String; let note: String }
struct InsightResponse: Decodable { let title: String; let message: String; let action: String; let target: String }

struct FeatureCard: View {
    let icon: String; let title: String; let subtitle: String; let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Text(icon).font(.system(size: 30))
                Text(title).font(.headline).foregroundStyle(AppConfig.deepPurple)
                Text(subtitle).font(.caption).foregroundStyle(AppConfig.muted).lineLimit(2)
            }
            .frame(maxWidth: .infinity, minHeight: 125, alignment: .topLeading).padding(16)
            .background(.white).clipShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }
}

#Preview { HomeView() }
