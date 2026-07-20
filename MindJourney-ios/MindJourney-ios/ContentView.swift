import SwiftUI

struct ContentView: View {
    var body: some View {
        LoginView()
    }
}

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isLoggedIn = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 5) {
                Image("BrandIcon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 150, height: 150)
                   // .border(Color.red, width: 1)    // 👈 TEMPORARY: Draws a red outline to show its exact layout space
                Image("MindJourney")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 250)
                    .padding(.top, -100)
                
                Text("Your Emotional Wellness Companion")
                    .font(.subheadline)
                    .foregroundColor(Color("LavenderBG"))
                    .padding(.top, -100)
                    .padding(.bottom, 10)
            }
                    TextField("", text: $email, prompt: Text("Email").foregroundColor(Color("MutedText").opacity(0.5)))
                        .padding(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color("DeepPurple"), lineWidth: 2)
                        )
                        .autocapitalization(.none)
                    
                    
                    SecureField("", text: $password, prompt: Text("Password").foregroundColor(Color("MutedText").opacity(0.5)))
                        .padding(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color("DeepPurple"), lineWidth: 2)
                            
                        )
                        .padding(.top, -100)
                        .padding(.bottom, 10)
                    
                    Button(action: {
                        // Temporary flag to test navigation
                        isLoggedIn = true
                    }) {
                        Text("Login")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color("DeepPurple"))
                            .cornerRadius(10)
                    }
                    .navigationDestination(isPresented: $isLoggedIn) {
                        HomeView()
                    }
                    
                    HStack {
                        Text("Don't have an account?")
                        NavigationLink("Register", destination: RegisterView())
                    }
                    .padding(.top, 20)
                }
                .padding()
            
            }
        }
    

    
    #Preview {
        ContentView()
    }

