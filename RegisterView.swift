import SwiftUI

struct RegisterView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var email = ""
    @State private var age = ""
    @State private var gender = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var message = ""
    @State private var showAlert = false
    @State private var success = false

    private let genders = ["Male", "Female", "Non-binary", "Prefer not to say"]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Image("BrandIcon").resizable().scaledToFit().frame(width: 90, height: 90)
                Text("Create Account").font(.largeTitle.bold()).foregroundStyle(AppConfig.deepPurple)
                Text("A private space to understand your emotions and build healthier routines.")
                    .multilineTextAlignment(.center).foregroundStyle(AppConfig.muted)

                TextField("Full name", text: $name).appField()
                TextField("Email", text: $email).textInputAutocapitalization(.never).keyboardType(.emailAddress).appField()

                HStack {
                    TextField("Age", text: $age).keyboardType(.numberPad).appField()
                    Menu {
                        ForEach(genders, id: \.self) { value in Button(value) { gender = value } }
                    } label: {
                        HStack { Text(gender.isEmpty ? "Gender" : gender); Image(systemName: "chevron.down") }
                            .foregroundStyle(AppConfig.deepPurple).padding(14)
                            .background(AppConfig.softLavender).clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }

                SecureField("Password (8+ characters)", text: $password).appField()
                SecureField("Confirm password", text: $confirmPassword).appField()

                Button(action: register) {
                    HStack { if isLoading { ProgressView().tint(.white) }; Text(isLoading ? "Creating..." : "Create Account").fontWeight(.bold) }
                        .frame(maxWidth: .infinity).padding().background(AppConfig.deepPurple).foregroundStyle(.white).clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(isLoading)
            }
            .padding(24)
        }
        .navigationTitle("Register")
        .navigationBarTitleDisplayMode(.inline)
        .alert(success ? "Account created" : "Registration failed", isPresented: $showAlert) {
            Button("OK") { if success { dismiss() } }
        } message: { Text(message) }
    }

    private func register() {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !email.isEmpty, let ageValue = Int(age), ageValue >= 13,
              !gender.isEmpty, password.count >= 8 else {
            message = "Complete every field. Age must be at least 13 and the password must contain at least 8 characters."
            success = false; showAlert = true; return
        }
        guard password == confirmPassword else { message = "Passwords do not match."; success = false; showAlert = true; return }
        isLoading = true
        Task {
            do {
                let _: SimpleResponse = try await APIClient.request("/api/register", method: "POST", body: RegisterRequest(name: name, email: email, age: ageValue, gender: gender, password: password))
                message = "Your account is ready. Please log in."
                success = true
            } catch { message = error.localizedDescription; success = false }
            isLoading = false; showAlert = true
        }
    }
}

#Preview { NavigationStack { RegisterView() } }
