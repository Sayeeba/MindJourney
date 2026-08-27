import SwiftUI

struct HomeView: View {
    // MARK: - State Variables
    @AppStorage("userId") var userId: Int = 0
    @State private var selectedMood: Int = 0
    
    // Animation States
    @State private var happyBlink = false
    @State private var calmSparkle = false
    @State private var neutralLook = false
    @State private var sadTearFall = false
    @State private var anxiousSweat = false

    // Insight State
    @State private var insightTitle: String = "✨ Pattern Detected"
    @State private var insightMessage: String = "Loading your personalized insights..."
    @State private var insightButtonTitle: String = "Try a Meditation"
    @State private var insightTargetSheet: ActiveSheet = .meditation

    // Navigation Sheet State
    @State private var activeSheet: ActiveSheet? = nil

    enum ActiveSheet: Identifiable {
            case profile, dashboard, journal, chatBot, groupTrip, community, helpline, safeHaven, meditation
            var id: Int { hashValue }
        }

    var body: some View {
        ZStack {
            // 1. App Background
            Color(.white)
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    
                    // 2. Custom Brand Header
                    HStack {
                        Image("BrandIcon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 44, height: 44)
                            .cornerRadius(12)
                            .shadow(color: Color("DeepPurple").opacity(0.15), radius: 4, x: 0, y: 2)
                        
                        Image("MindJourney")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .frame(height: 30)
                        
                        Spacer()
                        
                        // Profile Button
                        Button(action: { activeSheet = .profile }) {
                            Circle()
                                .fill(Color("LavenderBG"))
                                .frame(width: 40, height: 40)
                                .overlay(Text("👤").font(.title3))
                                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    // 3. Mood Tracking & Animated Emoji Section
                    VStack(spacing: 12) {
                        Text("How are you feeling today?")
                            .font(.headline)
                            .foregroundColor(Color("DeepPurple"))
                        
                        HStack(spacing: 8) {
                            moodButton(emoji: "😃", label: "Happy", index: 0)
                            moodButton(emoji: "😌", label: "Calm", index: 1)
                            moodButton(emoji: "😐", label: "Okay", index: 2)
                            moodButton(emoji: "😔", label: "Sad", index: 3)
                            moodButton(emoji: "😰", label: "Anxious", index: 4)
                        }
                        .onAppear {
                            calmSparkle = true
                            neutralLook = true
                            sadTearFall = true
                            anxiousSweat = true
                        }
                        .task {
                            while !Task.isCancelled {
                                try? await Task.sleep(nanoseconds: 2_500_000_000)
                                happyBlink = true
                                try? await Task.sleep(nanoseconds: 150_000_000)
                                happyBlink = false
                            }
                        }
                    }
                    .padding(.vertical, 10)
                    
                    // 4. Emotional Pattern Detection Insight Card
                    insightCard()
                    
                    // 5. Feature Grid section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Explore & Connect")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(Color("DeepPurple"))
                            .padding(.horizontal, 24)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            featureCard(icon: "✍️", title: "Journal", subtitle: "Write down your thoughts", target: .journal)
                            featureCard(icon: "💬", title: "ChatBot", subtitle: "Hello. You are not alone. How can I help you through this moment?", target: .chatBot)
                            featureCard(icon: "📈", title: "Dashboard", subtitle: "See your data", target: .journal)
                            featureCard(icon: "🏕️", title: "Group Trip", subtitle: "Connect in nature", target: .groupTrip)
                            featureCard(icon: "🤝", title: "Community", subtitle: "Share & support", target: .community)
                            featureCard(icon: "📞", title: "Helpline", subtitle: "24/7 support", target: .helpline)
                            featureCard(icon: "🏨", title: "Safe Haven", subtitle: "Find a quiet hotel/resort", target: .safeHaven)
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer(minLength: 40)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .fullScreenCover(item: $activeSheet) { sheet in
            destinationView(for: sheet)
        }
        .task {
            await fetchUserInsight()
        }
    }
    
    // MARK: - Subviews & Helpers
    
    // 🧠 Emotional Pattern Card Builder
    @ViewBuilder
    private func insightCard() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(insightTitle)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(Color("DeepPurple"))
                Spacer()
            }
            
            Text(insightMessage)
                .font(.footnote)
                .foregroundColor(Color("MutedText"))
                .lineSpacing(4)
            
            Button(action: {
                activeSheet = insightTargetSheet
            }) {
                Text(insightButtonTitle)
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(Color("DeepPurple").opacity(0.1))
                    .foregroundColor(Color("DeepPurple"))
                    .cornerRadius(20)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color("DeepPurple").opacity(0.08), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 20)
    }
    
    // 🗂️ Reusable Feature Card Builder
    @ViewBuilder
    private func featureCard(icon: String, title: String, subtitle: String, target: ActiveSheet) -> some View {
        Button(action: { activeSheet = target }) {
            VStack(alignment: .leading, spacing: 10) {
                Text(icon)
                    .font(.system(size: 32))
                    .padding(12)
                    .background(Color("LavenderBG").opacity(0.5))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(Color("DeepPurple"))
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(Color("MutedText"))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
        }
    }

    // MARK: - Navigation Router (Connect your custom Views here)
    @ViewBuilder
    private func destinationView(for sheet: ActiveSheet) -> some View {
        NavigationStack {
            VStack {
                switch sheet {
                case .profi/Applications/XAMPP/binle:
                    ProfileView()
                case .journal:
                    JournalView()
                case .chatBot:
                    ChatBotView()
                case .dashboard:
                    DashboardView()
                case .groupTrip:
                    Text("Guided Meditation Session").font(.title2)
                case .community:
                    Text("Community").font(.title2)
                case .helpline:
                    Text("Helpline").font(.title2)
                case .safeHaven:
                    SafeHavenView()
                case .meditation:
                    Text("Guided Meditation Session").font(.title2)
                
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color("LavenderBG").opacity(0.2))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { activeSheet = nil }
                }
            }
        }
    }

    // MARK: - Backend Integration Methods
    
    // 1. Save Mood Log to Backend Database
    private func logMoodToBackend(mood: String) {
        guard let url = URL(string: "http://127.0.0.1:8000/api/mood/log") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "user_id": userId,
            "mood": mood,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { _, _, _ in
            // Log saved successfully in database
        }.resume()
    }
    
    // 2. Fetch User Insight Prompt
    private func fetchUserInsight() async {
        guard let url = URL(string: "http://127.0.0.1:8000/api/home/insight/\(userId)") else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let decoded = try? JSONDecoder().decode(BackendInsightResponse.self, from: data) {
                DispatchQueue.main.async {
                    self.insightTitle = decoded.title
                    self.insightMessage = decoded.message
                    self.insightButtonTitle = decoded.button_title
                    switch decoded.action_type {
                    case "journal": self.insightTargetSheet = .journal
                    case "meditation": self.insightTargetSheet = .meditation
                    case "community": self.insightTargetSheet = .community
                    default: self.insightTargetSheet = .journal
                    }
                }
            }
        } catch {
            // Default fallback if server is offline
            DispatchQueue.main.async {
                self.insightTitle = "✨ Pattern Detected"
                self.insightMessage = "Based on your recent journal entries, you've been feeling a bit overwhelmed in the evenings. Would you like to try a 5-minute guided meditation before bed?"
                self.insightButtonTitle = "Try a Meditation"
                self.insightTargetSheet = .meditation
            }
        }
    }
}

struct BackendInsightResponse: Decodable {
    let title: String
    let message: String
    let button_title: String
    let action_type: String
}

// MARK: - Mood Button Extension
extension HomeView {
    @ViewBuilder
    private func moodButton(emoji: String, label: String, index: Int) -> some View {
        Button(action: {
            selectedMood = index
            logMoodToBackend(mood: label) // Saves mood selection to database
        }) {
            VStack(spacing: 6) {
                ZStack {
                    switch index {
                    case 0:
                        Text(happyBlink ? "😄" : "😃")
                            .font(.system(size: 40))
                            .id("happyEmoji")

                    case 1:
                        ZStack {
                            Text("😌")
                                .font(.system(size: 40))

                            Text("✨")
                                .font(.system(size: 12))
                                .offset(x: 12, y: calmSparkle ? -20 : -10)
                                .opacity(calmSparkle ? 0.9 : 0.9)
                                .animation(
                                    .easeInOut(duration: 1.5)
                                    .repeatForever(autoreverses: true),
                                    value: calmSparkle
                                )
                        }

                    case 2:
                        Text("😐")
                            .font(.system(size: 40))
                            .offset(x: neutralLook ? 1.5 : -1.5)
                            .animation(
                                .easeInOut(duration: 1.4)
                                .repeatForever(autoreverses: true),
                                value: neutralLook
                            )

                    case 3:
                        ZStack {
                            Text("😔")
                                .font(.system(size: 40))

                            Text("💧")
                                .font(.system(size: 12))
                                .offset(x: 7, y: sadTearFall ? 16 : 12)
                                .opacity(sadTearFall ? 0.0 : 1.0)
                                .animation(
                                    .easeIn(duration: 1.2)
                                    .repeatForever(autoreverses: false),
                                    value: sadTearFall
                                )
                        }

                    case 4:
                        ZStack {
                            Text("😩")
                                .font(.system(size: 40))

                            Text("💦")
                                .font(.system(size: 10))
                                .offset(x: anxiousSweat ? 12 : 15, y: anxiousSweat ? 15 : -5)
                                .opacity(anxiousSweat ? 0.1 : 1.0)
                                .animation(
                                    .easeIn(duration: 0.7)
                                    .repeatForever(autoreverses: false),
                                    value: anxiousSweat
                                )
                        }

                    default:
                        Text(emoji)
                            .font(.system(size: 32))
                    }
                }
                .frame(width: 38, height: 38)

                Text(label)
                    .font(.caption2)
                    .fontWeight(selectedMood == index ? .bold : .regular)
                    .foregroundColor(selectedMood == index ? Color("DeepPurple") : Color("MutedText"))
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 6)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(selectedMood == index ? Color.white : Color.clear)
                    .shadow(color: selectedMood == index ? Color("DeepPurple").opacity(0.12) : .clear, radius: 6, x: 0, y: 3)
            )
        }
    }
}

#Preview {
    HomeView()
}
