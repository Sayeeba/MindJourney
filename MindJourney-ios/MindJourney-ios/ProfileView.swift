import SwiftUI
  
struct UserProfile: Codable {
    let full_name: String
    let email: String
    let age: Int
    let gender: String
    let joined_date: String
}

struct ProfileView: View {
    @Environment(\.dismiss) var dismiss
    @State private var profile: UserProfile?
    @State private var isLoading = true
    @State private var showLogin = false
    
    // FETCH THE ACTUAL LOGGED-IN USER ID DYNAMICALLY
    var currentUserId: Int {
        UserDefaults.standard.integer(forKey: "userId")
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color("LavenderBG").opacity(0.2)
                    .ignoresSafeArea()
                
                if isLoading {
                    ProgressView()
                } else if let profile = profile {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Header Avatar & Name
                            VStack(spacing: 8) {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .frame(width: 90, height: 90)
                                    .foregroundColor(Color("DeepPurple"))
                                
                                Text(profile.full_name)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Text(profile.email)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            .padding(.top)

                            // Details Section
                            VStack(spacing: 0) {
                                InfoRow(icon: "calendar", title: "Age", value: "\(profile.age) years")
                                Divider()
                                InfoRow(icon: "person.fill", title: "Gender", value: profile.gender)
                                Divider()
                                InfoRow(icon: "clock.fill", title: "Member Since", value: profile.joined_date)
                            }
                            .background(Color.white)
                            .cornerRadius(12)
                            .padding(.horizontal)

                            // Actions Section
                            VStack(spacing: 0) {
                                NavigationLink(destination: Text("Edit Profile View")) {
                                    ActionRow(icon: "square.and.pencil", title: "Edit Profile", color: .primary)
                                }
                                Divider()
                                NavigationLink(destination: Text("Settings View")) {
                                    ActionRow(icon: "gearshape.fill", title: "Settings", color: .primary)
                                }
                            }
                            .background(Color.white)
                            .cornerRadius(12)
                            .padding(.horizontal)

                            // Log Out Button
                            Button(action: handleLogout) {
                                Text("Log Out")
                                    .font(.headline)
                                    .foregroundColor(.red)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear(perform: fetchProfile)
            .onAppear(perform: fetchProfile)
            .fullScreenCover(isPresented: $showLogin) {
                            LoginView()
                        }
        }
    }

    func fetchProfile() {
        // CHANGED PORT TO 8000 TO MATCH YOUR MAIN.PY
        guard let url = URL(string: "http://127.0.0.1:8000/api/profile/\(currentUserId)") else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data, let decoded = try? JSONDecoder().decode(UserProfile.self, from: data) {
                DispatchQueue.main.async {
                    self.profile = decoded
                    self.isLoading = false
                }
            } else {
                // Handle error or unauthenticated state here if needed
                print("Failed to decode profile data.")
            }
        }.resume()
    }

    func handleLogout() {
        // 1. Clear the saved user ID from storage
                UserDefaults.standard.removeObject(forKey: "userId")
                
        // 2. Trigger the login page to show
                showLogin = true
    }
}

// Helper Components
struct InfoRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack {
            Label(title, systemImage: icon)
            Spacer()
            Text(value)
                .foregroundColor(.gray)
        }
        .padding()
    }
}

struct ActionRow: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        HStack {
            Label(title, systemImage: icon)
                .foregroundColor(color)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
    }
}
#Preview {
   ProfileView()
}
