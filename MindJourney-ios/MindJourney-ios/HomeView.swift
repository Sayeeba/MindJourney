import SwiftUI

struct HomeView: View {
    // State for our cute bouncing emoji animation
    @State private var selectedMood: Int = 0
    @State private var happyBlink = false
    @State private var calmSparkle = false
    @State private var neutralLook = false
    @State private var sadTearFall = false
    @State private var anxiousSweat = false
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
                        
                        Image("MindJourney") // Your saved text image
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .frame(height: 30)
                        
                        Spacer()
                        
                        // Cute little profile button placeholder
                        Circle()
                            .fill(Color("LavenderBG"))
                            .frame(width: 40, height: 40)
                            .overlay(Text("👤").font(.title3))
                            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
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
                            //happyBlink = true
                            calmSparkle = true
                            neutralLook = true
                            sadTearFall = true
                            anxiousSweat = true
                        }
                        .task {
                            // Smooth 0.15s eye blink every 2.5 seconds
                            while !Task.isCancelled {
                                try? await Task.sleep(nanoseconds: 2_500_000_000) // Wait 2.5s
                                happyBlink = true
                                try? await Task.sleep(nanoseconds: 150_000_000)   // Blink for 0.15s
                                happyBlink = false
                            }
                        }
                    .padding(.vertical, 10)
                    
                }
                     
                    // 4. Emotional Pattern Detection Insight (Journal Suggestion)
                    insightCard()
                    
                    // 5. Feature Grid section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Explore & Connect")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(Color("DeepPurple"))
                            .padding(.horizontal, 24)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            featureCard(icon: "🏕️", title: "Group Trip", subtitle: "Connect in nature")
                            featureCard(icon: "🤝", title: "Community", subtitle: "Share & support")
                            featureCard(icon: "🩺", title: "Psychiatrist", subtitle: "Find help near you")
                            featureCard(icon: "📞", title: "Helpline", subtitle: "24/7 support")
                            featureCard(icon: "🏨", title: "Safe Haven", subtitle: "Find a quiet hotel/resort")
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer(minLength: 40)
                }
            }
        }
    }
    
    // MARK: - Subviews & Helpers
    
    // 🧠 Emotional Pattern Card Builder
    @ViewBuilder
    private func insightCard() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("✨ Pattern Detected")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(Color("DeepPurple"))
                Spacer()
            }
            
            Text("Based on your recent journal entries, you've been feeling a bit overwhelmed in the evenings. Would you like to try a 5-minute guided meditation before bed?")
                .font(.footnote)
                .foregroundColor(Color("MutedText"))
                .lineSpacing(4)
            
            Button(action: {
                // Action to open suggestion
            }) {
                Text("Try a Meditation")
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
    private func featureCard(icon: String, title: String, subtitle: String) -> some View {
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
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
    }
}


extension HomeView {
    @ViewBuilder
    private func moodButton(emoji: String, label: String, index: Int) -> some View {
        Button(action: {
            selectedMood = index
        }) {
            VStack(spacing: 6) {
                
                // 1. EXPRESSIVE ANIMATED EMOJI CONTAINER
                ZStack {
                    switch index {
                    case 0: // 😃 HAPPY: Eyes open normally, switches to closed smile 😄 during blink
                        Text(happyBlink ? "😄" : "😃")
                            .font(.system(size: 40))
                            .id("happyEmoji") // Prevents unexpected view rebuild glitches

                    case 1: // 😌 CALM: Floating sparkle overhead
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

                    case 2: // 😐 OKAY: Eye glance shift side-to-side
                        Text("😐")
                            .font(.system(size: 40))
                            .offset(x: neutralLook ? 1.5 : -1.5)
                            .animation(
                                .easeInOut(duration: 1.4)
                                .repeatForever(autoreverses: true),
                                value: neutralLook
                            )

                    case 3: // 😔 SAD: Tear falling down from eye
                        ZStack {
                            Text("😔")
                                .font(.system(size: 40))

                            Text("💧")
                            .font(.system(size: 12))
                            // Aligned to right eye level (x: 7, y starts at 8)
                            .offset(x: 7, y: sadTearFall ? 16 : 12)
                            .opacity(sadTearFall ? 0.0 : 1.0)
                            .animation(.easeIn(duration: 1.2)
                            .repeatForever(autoreverses: false),
                            value: sadTearFall
                                                            )
                                                    }

                    case 4: // 😩 ANXIOUS: Nervous sweat drop sliding
                        ZStack {
                            Text("😩")
                                .font(.system(size: 40))

                            Text("💦")
                                .font(.system(size: 10))
                            // Aligned to right temple/forehead level (x: 9, y starts at -5)
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

                // 2. STATIC TEXT LABEL (Never moves)
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
