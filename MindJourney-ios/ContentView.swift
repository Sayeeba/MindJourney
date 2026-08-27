import SwiftUI
var isPreview: Bool {
    ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
}
struct ContentView: View {
    var body: some View {
        LoginView()
    }
}

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isLoggedIn = false
    @State private var errorMessage = ""
    @State private var showAlert = false
    @State private var isLoading = false
    @State private var isPasswordVisible: Bool = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 5) {
                        Image("BrandIcon")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 150, height: 150)
                            .padding(.top,50)
                        
                        Image("MindJourney")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 250)
                            .padding(.top, -100)
                            .padding(.bottom, -50)
                        
                        Text("Your Emotional Wellness Companion")
                            .font(.subheadline)
                            .foregroundColor(Color("LavenderBG"))
                            .padding(.top, -50)
                            .padding(.bottom, 10)
                    }
                    TextField("", text: $email, prompt: Text("Email").foregroundColor(Color("MutedText").opacity(0.5)))
                        .padding(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color("DeepPurple"), lineWidth: 2)
                        )
                        .autocapitalization(.none)
                    HStack {
                        if isPasswordVisible {
                            // NEW: Shows password when eye is tapped
                            TextField("", text: $password, prompt: Text("Password").foregroundColor(Color("MutedText").opacity(0.5)))
                                .autocapitalization(.none)
                        } else {                                                SecureField("", text: $password, prompt: Text("Password").foregroundColor(Color("MutedText").opacity(0.5)))
                        }
                        
                        
                        // NEW: The eye icon button
                        Button(action: {
                            isPasswordVisible.toggle()
                        }) {
                            Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(Color("MutedText").opacity(0.8))
                        }
                        
                    }
                    .padding(10) // <-- Paste the styling HERE
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(Color("DeepPurple"),
                                                        lineWidth: 2)
                                        )
                        Button(action: {
                            
                        loginUser()
                    }) {
                        Text("Login")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color("DeepPurple"))
                            .cornerRadius(10)
                    }
                    
                    HStack {
                        Text("Don't have an account?")
                            .foregroundColor(Color("MutedText"))
                        
                        NavigationLink(destination: RegisterView()) {
                            Text("Register")
                                .fontWeight(.bold)
                                .foregroundColor(Color("DeepPurple"))
                        }
                    }
                    .padding(.top, 20)
                }
                .padding()
            }
            .navigationDestination(isPresented: $isLoggedIn) {
                HomeView()
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Login Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
    
    private func loginUser() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter both email and password."
            showAlert = true
            return
        }
        
        isLoading = true
        
        guard let url = URL(string: "http://127.0.0.1:8000/api/login") else {
            print("Invalid URL")
            return}
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["email": email, "password": password]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200, let data = data {
                    // 1. Extract the user_id from the backend response
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let fetchedUserId = json["user_id"] as? Int {
                        
                        // 2. Save it dynamically to storage
                        UserDefaults.standard.set(fetchedUserId, forKey: "userId")
                    }
                    
                    isLoggedIn = true
                } else {
                    errorMessage = "Invalid email or password."
                    showAlert = true
                }
            }
        }.resume()
    }
}

#Preview {
    ContentView()
}
