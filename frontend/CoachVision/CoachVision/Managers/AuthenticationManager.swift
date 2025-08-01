import Foundation
import SwiftUI

class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: UserProfile?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var registrationSuccessful = false
    
    // Use your computer's local IP address here
    // You can find it by running 'ifconfig' in Terminal on your Mac
    // Look for 'inet' followed by an IP like 192.168.1.xxx
    private let baseURL = "http://192.168.4.27:8000"  // Your computer's local IP
    var authToken: String?
    
    // Training Plan Manager
    lazy var trainingPlanManager = TrainingPlanManager(authToken: authToken)
    
    // Meal Manager reference
    weak var mealManager: MealManager?
    
    init() {
        // Check for saved token on app launch
        if let token = UserDefaults.standard.string(forKey: "authToken") {
            self.authToken = token
            self.isAuthenticated = true
        }
    }
    
    func initializeUserProfile() async {
        if let token = authToken, isAuthenticated {
            await fetchCurrentUser()
        }
    }
    
    private func handleAuthError() {
        // Clear invalid token and reset authentication state
        UserDefaults.standard.removeObject(forKey: "authToken")
        authToken = nil
        isAuthenticated = false
        currentUser = nil
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
    
    func completeProfile(age: Int, weight: Double, height: Double, fitnessGoal: String, experienceLevel: String) async {
        await performRequest(
            endpoint: "/auth/complete-profile",
            method: "POST",
            body: [
                "age": age,
                "weight": weight,
                "height": height,
                "fitness_goal": fitnessGoal,
                "experience_level": experienceLevel
            ]
        )
    }
    
    func updateProfile(name: String, age: Int, weight: Double, height: Double, fitnessGoal: String, experienceLevel: String) async {
        await performRequest(
            endpoint: "/auth/update-profile",
            method: "PUT",
            body: [
                "name": name,
                "age": age,
                "weight": weight,
                "height": height,
                "fitness_goal": fitnessGoal,
                "experience_level": experienceLevel
            ]
        )
    }
    
    func submitSupportRequest(_ request: SupportRequest) async -> Bool {
        guard let authToken = authToken else {
            print("No auth token for submitting support request")
            return false
        }
        
        let url = URL(string: "\(baseURL)/support/submit")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        
        do {
            let jsonData = try JSONEncoder().encode(request)
            urlRequest.httpBody = jsonData
            
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Support request response status: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode == 200 {
                    print("Support request submitted successfully")
                    return true
                } else {
                    print("Support request failed with status: \(httpResponse.statusCode)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Response: \(responseString)")
                    }
                    return false
                }
            }
            
            return false
        } catch {
            print("Error submitting support request: \(error)")
            return false
        }
    }
    
    func fetchCurrentUser() async {
        await performRequest(
            endpoint: "/auth/me",
            method: "GET",
            body: [:]
        )
    }
    
    private func performRequest(endpoint: String, method: String, body: [String: Any]) async {
        guard let token = authToken else { 
            print("No auth token available")
            return 
        }
        
        print("Making request to: \(endpoint)")
        print("Token: \(token.prefix(20))...")
        
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
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        if method != "GET" {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            await MainActor.run {
                isLoading = false
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("Response status: \(httpResponse.statusCode)")
                    if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                        if let userResponse = try? JSONDecoder().decode(UserProfile.self, from: data) {
                            print("Successfully updated user profile")
                            print("User age: \(userResponse.age ?? -1)")
                            print("User weight: \(userResponse.weight ?? -1)")
                            print("User height: \(userResponse.height ?? -1)")
                            print("User fitness goal: \(userResponse.fitnessGoal ?? "nil")")
                            print("User experience level: \(userResponse.experienceLevel ?? "nil")")
                            print("Is profile complete: \(userResponse.isProfileComplete)")
                            
                            self.currentUser = userResponse
                            // Clear any error messages on success
                            self.errorMessage = nil
                            
                            // Update meal manager with user ID
                            if let token = self.authToken {
                                self.mealManager?.updateAuth(token: token, userId: userResponse.id)
                            }
                        } else {
                            print("Failed to decode user response")
                            print("Response data: \(String(data: data, encoding: .utf8) ?? "nil")")
                        }
                    } else {
                        print("Request failed with status: \(httpResponse.statusCode)")
                        
                        // Handle 401 Unauthorized - clear invalid token
                        if httpResponse.statusCode == 401 {
                            print("Token is invalid, clearing authentication state")
                            self.handleAuthError()
                            self.errorMessage = "Session expired. Please login again."
                        } else {
                            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                                self.errorMessage = errorResponse.detail
                                print("Error detail: \(errorResponse.detail)")
                            } else {
                                self.errorMessage = "Request failed with status: \(httpResponse.statusCode)"
                                print("Response data: \(String(data: data, encoding: .utf8) ?? "nil")")
                            }
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
        
        var shouldFetchUser = false
        
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
                                shouldFetchUser = true
                                
                                // Update training plan manager with new token
                                self.trainingPlanManager.updateAuthToken(tokenResponse.access_token)
                                
                                // Update meal manager with new token and user ID
                                if let currentUser = self.currentUser {
                                    self.mealManager?.updateAuth(token: tokenResponse.access_token, userId: currentUser.id)
                                }
                            }
                        } else {
                            // Handle registration response
                            if let userResponse = try? JSONDecoder().decode(UserProfile.self, from: data) {
                                self.currentUser = userResponse
                                self.registrationSuccessful = true
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
            
            // Fetch user profile after successful login (outside MainActor)
            if shouldFetchUser {
                await fetchCurrentUser()
            }
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }
} 