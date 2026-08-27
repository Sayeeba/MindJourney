import SwiftUI

struct RegisterView: View {
    @State private var name = ""
    @State private var email = ""
    @State private var age = ""
    @State private var gender = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage = ""
    @State private var showAlert = false
    @State private var isSuccess = false
    @State private var isLoading = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 5) {
            Image("BrandIcon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 150, height: 150)
                .padding(.top, 95)
               // .border(Color.red, width: 1)    // 👈 TEMPORARY: Draws a red outline to show its exact layout space
            Image("MindJourney")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 250)
                .padding(.top, -70)
            
            Text("Take a deep breath.\nYour safe space is just a step away 🌿")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(Color("LavenderBG"))
                .padding(.top, -80)
                .padding(.bottom, 10)
        }
        VStack(spacing: 20) {
            Text("Create Account").foregroundColor(Color("DeepPurple"))
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, -50)
            
            TextField("Full Name", text: $name).foregroundColor(Color("MutedText"))
                //.textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color("DeepPurple"), lineWidth: 2)
                )
            
            TextField("Email", text: $email).foregroundColor(Color("MutedText"))
                //textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .padding(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color("DeepPurple"), lineWidth: 2)
                )
            HStack(spacing: 15) {
                TextField("Age", text: $age).foregroundColor(Color("MutedText"))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad) // Opens number keyboard
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color("DeepPurple"), lineWidth: 2))
                
                Menu {
                    Button("Male") {
                        gender = "Male"
                    }
                    Button("Female") {
                        gender = "Female"
                    }
                } label: {
                    HStack {
                        Text(gender.isEmpty ? "Gender" : gender).foregroundColor(Color("MutedText"))
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(Color("DeepPurple"))
                            .font(.caption)
                    }
                    .padding(.horizontal, 10)
                    .frame(height: 34)
                    .background(Color.white)
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color("DeepPurple"), lineWidth: 2)
                    )
                    
                    
                }
                
            }
            //.buttonStyle(PlainButtonStyle())
            SecureField("Password", text: $password)
                .foregroundColor(Color("MutedText"))
                .padding(10) // Use padding instead of RoundedBorderTextFieldStyle
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color("DeepPurple"), lineWidth: 2)
                )

            SecureField("Confirm Password", text: $confirmPassword)
                .foregroundColor(Color("MutedText"))
                .padding(10) // Use padding instead of RoundedBorderTextFieldStyle
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color("DeepPurple"), lineWidth: 2)
                )
            
            Button(action: {
                // 1. Check if passwords match FIRST
                    guard password == confirmPassword else {
                        errorMessage = "Passwords do not match."
                        showAlert = true
                        return // This stops the code here so it doesn't try to register
                    }
                    
                    // 2. Check if password is empty
                    guard !password.isEmpty else {
                        errorMessage = "Password cannot be empty."
                        showAlert = true
                        return
                    }
                // TODO: Call Python /api/register endpoint here
                registerUser()
            }) {
                Text("Sign Up")
                    .foregroundColor(Color.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("DeepPurple"))
                    .cornerRadius(10)
                
            }
                
                HStack() {
                    Text("Already have an account?")
                        .foregroundColor(Color("MutedText"))
                    
                    Button(action: {
                        presentationMode.wrappedValue.dismiss() // 👈 Pops back to LoginView
                    }) {
                        Text("Login")
                            .fontWeight(.bold)
                            .foregroundColor(Color("DeepPurple"))
                    }
                }
            
            
            Spacer()
        }
        .padding()
        //.navigationTitle("Register")
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(isSuccess ? "Success" : "Error"),
                message: Text(errorMessage),
                dismissButton: .default(Text("OK")) {
                    if isSuccess { presentationMode.wrappedValue.dismiss() }
                }
            )
        }
    }
    private func registerUser() {
        guard !name.isEmpty, !email.isEmpty, !age.isEmpty, !gender.isEmpty, !password.isEmpty else {
            errorMessage = "Please complete all fields."
            isSuccess = false
            showAlert = true
            return
        }
        
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match."
            isSuccess = false
            showAlert = true
            return
        }
        
        isLoading = true
        
        guard let url = URL(string: "http://127.0.0.1:5001/api/register") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "name": name,
            "email": email,
            "age": Int(age) ?? 0,
            "gender": gender,
            "password": password
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                // Check for connection error
                if let error = error {
                    errorMessage = "Connection error: \(error.localizedDescription)"
                    isSuccess = false
                    showAlert = true
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        errorMessage = "Account created successfully! Please login."
                        isSuccess = true
                        showAlert = true
                    } else if httpResponse.statusCode == 400 {
                        errorMessage = "This email is already registered."
                        isSuccess = false
                        showAlert = true
                    } else {
                        errorMessage = "Server error (\(httpResponse.statusCode)). Check Python terminal."
                        isSuccess = false
                        showAlert = true
                    }
                } else {
                    errorMessage = "Could not connect to Python backend."
                    isSuccess = false
                    showAlert = true
                }
            }
        }.resume()
    }
}//
//  RegisterView.swift
//  MindJourney-ios
//
//  Created by Kazi  Sayeeba Islam on 7/20/26.
//
#Preview {
    RegisterView()
}

