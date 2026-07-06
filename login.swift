import SwiftUI

struct LoginView: View {

    @State private var email = ""
    @State private var password = ""

    var body: some View {

        VStack(spacing: 20) {

            Text("Login")
                .font(.largeTitle)
                .fontWeight(.bold)

            TextField("Email", text: $email)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .textFieldStyle(.roundedBorder)

            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)

            Button(action: {
                print("Login Button Pressed")
            }) {
                Text("Login")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }

            Button("Forgot Password?") {
                print("Forgot Password")
            }

            Spacer()

            NavigationLink(destination: RegisterView()) {
                Text("Don't have an account? Register")
            }

        }
        .padding()
    }
}

#Preview {
    LoginView()
}