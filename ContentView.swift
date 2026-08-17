import SwiftUI

// MARK: - App Configuration

enum AppConfig {
    // Simulator: 127.0.0.1. For a physical iPhone, replace with your Mac's LAN IP.
    static let baseURL = "http://127.0.0.1:5001"
    static let deepPurple = Color(red: 0.20, green: 0.16, blue: 0.38)
    static let lavender = Color(red: 0.72, green: 0.61, blue: 0.78)
    static let softLavender = Color(red: 0.95, green: 0.92, blue: 0.97)
    static let pink = Color(red: 1.00, green: 0.65, blue: 0.76)
    static let muted = Color(red: 0.38, green: 0.36, blue: 0.43)
}

struct APIError: Error, LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

struct APIClient {
    static func request<T: Decodable>(_ path: String, method: String = "GET", body: Encodable? = nil) async throws -> T {
        guard let url = URL(string: AppConfig.baseURL + path) else { throw APIError(message: "Invalid server URL.") }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let body {
            request.httpBody = try JSONEncoder().encode(body)
        }
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw APIError(message: "Invalid server response.") }
        guard (200...299).contains(http.statusCode) else {
            if let detail = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw APIError(message: detail.detail)
            }
            throw APIError(message: "Server returned HTTP \(http.statusCode).")
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    static func requestNoContent(_ path: String, method: String = "DELETE", body: Encodable? = nil) async throws {
        guard let url = URL(string: AppConfig.baseURL + path) else { throw APIError(message: "Invalid server URL.") }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let body { request.httpBody = try JSONEncoder().encode(body) }
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            if let detail = try? JSONDecoder().decode(ErrorResponse.self, from: data) { throw APIError(message: detail.detail) }
            throw APIError(message: "Request failed.")
        }
    }
}

struct ErrorResponse: Decodable { let detail: String }

struct LoginRequest: Encodable { let email: String; let password: String }
struct RegisterRequest: Encodable { let name: String; let email: String; let age: Int; let gender: String; let password: String }
struct LoginResponse: Decodable { let user_id: Int; let name: String; let email: String; let age: Int?; let gender: String? }
struct SimpleResponse: Decodable { let message: String; let id: Int? }

// MARK: - Root

struct ContentView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn = false

    var body: some View {
        Group {
            if isLoggedIn { HomeView() }
            else { LoginView() }
        }
    }
}

// MARK: - Login

struct LoginView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @AppStorage("userId") private var userId = 0
    @AppStorage("userName") private var userName = ""
    @AppStorage("userEmail") private var userEmail = ""

    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var showRegister = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    BrandHeader()
                        .padding(.top, 30)

                    VStack(spacing: 10) {
                        TextField("Email", text: $email)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .appField()

                        SecureField("Password", text: $password)
                            .textContentType(.password)
                            .appField()
                    }

                    Button(action: login) {
                        HStack {
                            if isLoading { ProgressView().tint(.white) }
                            Text(isLoading ? "Signing in..." : "Login")
                                .fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppConfig.deepPurple)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(isLoading)

                    Button("Create a new account") { showRegister = true }
                        .fontWeight(.semibold)
                        .foregroundStyle(AppConfig.deepPurple)
                }
                .padding(24)
            }
            .navigationDestination(isPresented: $showRegister) { RegisterView() }
            .alert("Login failed", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: { Text(errorMessage) }
        }
    }

    private func login() {
        guard !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, !password.isEmpty else {
            errorMessage = "Enter both email and password."
            showError = true
            return
        }
        isLoading = true
        Task {
            do {
                let response: LoginResponse = try await APIClient.request("/api/login", method: "POST", body: LoginRequest(email: email.trimmingCharacters(in: .whitespacesAndNewlines), password: password))
                userId = response.user_id
                userName = response.name
                userEmail = response.email
                isLoggedIn = true
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isLoading = false
        }
    }
}

struct BrandHeader: View {
    var body: some View {
        VStack(spacing: 8) {
            Image("BrandIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
            Image("MindJourney")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 260, maxHeight: 70)
            Text("Your emotional wellness companion")
                .font(.subheadline)
                .foregroundStyle(AppConfig.muted)
        }
    }
}

extension View {
    func appField() -> some View {
        self
            .padding(14)
            .background(Color.white)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppConfig.deepPurple.opacity(0.35), lineWidth: 1.5))
    }
}

#Preview { ContentView() }
