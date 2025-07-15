import Foundation
import SwiftUI

class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: UserProfile?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let baseURL = "http://localhost:8000"
    private var authToken: String?
    
    init() {
        // Check for saved token on app launch
        if let token = UserDefaults.standard.string(forKey: "authToken") {
            self.authToken = token
            self.isAuthenticated = true
        }
    }
    
    func register(email: String, name: String, password: String) async {
        await performAuthRequest(
            endpoint: "/auth/register",
            method: "POST",
            body: [
                "email": email,
                "name": name,
                "password": password
            ]
        )
    }
    
    func login(email: String, password: String) async {
        await performAuthRequest(
            endpoint: "/auth/login",
            method: "POST",
            body: [
                "username": email,
                "password": password
            ],
            isLogin: true
        )
    }
    
    func logout() {
        UserDefaults.standard.removeObject(forKey: "authToken")
        authToken = nil
        isAuthenticated = false
        currentUser = nil
    }
    
    private func performAuthRequest(endpoint: String, method: String, body: [String: Any], isLogin: Bool = false) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        guard let url = URL(string: baseURL + endpoint) else {
            await MainActor.run {
                errorMessage = "Invalid URL"
                isLoading = false
            }
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        if isLogin {
            // For login, send form data
            let formData = body.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.httpBody = formData.data(using: .utf8)
        } else {
            // For registration, send JSON
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            await MainActor.run {
                isLoading = false
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                        if isLogin {
                            // Handle login response
                            if let tokenResponse = try? JSONDecoder().decode(TokenResponse.self, from: data) {
                                self.authToken = tokenResponse.access_token
                                UserDefaults.standard.set(tokenResponse.access_token, forKey: "authToken")
                                self.isAuthenticated = true
                            }
                        } else {
                            // Handle registration response
                            if let userResponse = try? JSONDecoder().decode(UserProfile.self, from: data) {
                                self.currentUser = userResponse
                            }
                        }
                    } else {
                        // Handle error response
                        if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                            self.errorMessage = errorResponse.detail
                        } else {
                            self.errorMessage = "Request failed with status: \(httpResponse.statusCode)"
                        }
                    }
                }
            }
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }
} 