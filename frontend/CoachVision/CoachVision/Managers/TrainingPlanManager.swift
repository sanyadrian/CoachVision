import Foundation

class TrainingPlanManager: ObservableObject {
    @Published var plans: [TrainingPlan] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let baseURL = "http://localhost:8000"
    private var authToken: String?
    
    init(authToken: String?) {
        self.authToken = authToken
    }
    
    func updateAuthToken(_ token: String?) {
        self.authToken = token
    }
    
    func fetchPlans(userId: Int) async {
        print("Fetching plans for user ID: \(userId)")
        await performRequest(
            endpoint: "/plans/user/\(userId)",
            method: "GET",
            body: [:]
        )
    }
    
    func createPlan(planType: String, focusArea: String, userId: Int) async {
        await performRequest(
            endpoint: "/plans/generate",
            method: "POST",
            body: [
                "user_id": userId,
                "plan_type": planType
            ]
        )
    }
    
    private func performRequest(endpoint: String, method: String, body: [String: Any]) async {
        guard let token = authToken else { 
            print("No auth token available for training plans")
            return 
        }
        
        print("Making request to: \(baseURL + endpoint)")
        print("Method: \(method)")
        print("Auth token: \(String(token.prefix(20)))...")
        
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
                    if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                        if endpoint.hasPrefix("/plans/user/") {
                            // Handle fetch plans response
                            print("Raw response data: \(String(data: data, encoding: .utf8) ?? "nil")")
                            if let plansResponse = try? JSONDecoder().decode([TrainingPlan].self, from: data) {
                                self.plans = plansResponse
                                print("Successfully fetched \(plansResponse.count) plans")
                                print("First plan: \(plansResponse.first?.title ?? "nil")")
                                print("First plan content: \(plansResponse.first?.content.prefix(100) ?? "nil")")
                            } else {
                                print("Failed to decode plans response")
                                print("Response data: \(String(data: data, encoding: .utf8) ?? "nil")")
                            }
                        } else if endpoint == "/plans/generate" {
                            // Handle create plan response
                            if let planResponse = try? JSONDecoder().decode(TrainingPlan.self, from: data) {
                                self.plans.append(planResponse)
                                print("Successfully created new plan")
                            } else {
                                print("Failed to decode plan creation response")
                                print("Response data: \(String(data: data, encoding: .utf8) ?? "nil")")
                            }
                        }
                    } else {
                        print("Training plans request failed with status: \(httpResponse.statusCode)")
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
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }
} 