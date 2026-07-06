import SwiftUI

struct RegisterView: View {

    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {

                Text("Create Account")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                TextField("Full Name", text: $fullName)
                    .textFieldStyle(.roundedBorder)

                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .textFieldStyle(.roundedBorder)

                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)

                SecureField("Confirm Password", text: $confirmPassword)
                    .textFieldStyle(.roundedBorder)

                Button(action: {
                    print("Register Button Pressed")
                }) {
                    Text("Register")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }

                Spacer()

                NavigationLink(destination: LoginView()) {
                    Text("Already have an account? Login")
                }

            }
            .padding()
        }
    }
}

#Preview {
    RegisterView()
}