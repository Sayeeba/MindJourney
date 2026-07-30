import SwiftUI

struct RegisterView: View {
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    
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
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color("DeepPurple"), lineWidth: 2)
                )
            
            TextField("Email", text: $email).foregroundColor(Color("MutedText"))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color("DeepPurple"), lineWidth: 2)
                )
            
            SecureField("Password", text: $password ).foregroundColor(Color("MutedText"))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color("DeepPurple"), lineWidth: 2)
                )
            SecureField("Confirm Password", text: $confirmPassword).foregroundColor(Color("MutedText"))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color("DeepPurple"), lineWidth: 2)
                )
            
            Button(action: {
                // TODO: Call Python /api/register endpoint here
                print("Registration tapped for \(name)")
            }) {
                Text("Sign Up")
                    .foregroundColor(Color.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.deepPurple)
                    .cornerRadius(10)
            }
            HStack {
                Text("Already have an account?")
                    .foregroundColor(Color("MutedText"))
                
                NavigationLink(destination: LoginView()) {
                    Text("Login")
                        .fontWeight(.bold)
                        .foregroundColor(Color("DeepPurple"))
                }
            }
            Spacer()
        }
        .padding()
        .navigationTitle("Register")
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

