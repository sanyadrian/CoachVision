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
    
    func updateCompletedDays(planId: Int, completedDays: Set<String>) async {
        print("updateCompletedDays called for plan \(planId) with days: \(completedDays)")
        
        // Update local plan immediately for UI responsiveness
        if let index = plans.firstIndex(where: { $0.id == planId }) {
            print("Found plan at index \(index)")
            await MainActor.run {
                // Create a new plan with updated completed days
                let originalPlan = plans[index]
                print("Original plan progress: \(originalPlan.progress * 100)%")
                let updatedPlan = TrainingPlan(
                    id: originalPlan.id,
                    userId: originalPlan.userId,
                    planType: originalPlan.planType,
                    content: originalPlan.content,
                    createdAt: originalPlan.createdAt,
                    isActive: originalPlan.isActive,
                    completedDays: completedDays
                )
                plans[index] = updatedPlan
                print("Updated plan progress: \(updatedPlan.progress * 100)%")
                print("Plans array now has \(plans.count) plans")
            }
        } else {
            print("Plan not found in plans array")
        }
        
        await performRequest(
            endpoint: "/plans/\(planId)/completed-days",
            method: "PUT",
            body: [
                "completed_days": Array(completedDays)
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
                                for plan in plansResponse {
                                    print("Plan \(plan.id): \(plan.completedDays.count) completed days - \(plan.completedDays)")
                                }
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
                        } else if endpoint.contains("/completed-days") {
                            // Handle update completed days response
                            print("Successfully updated completed days")
                            // No need to refresh since we update locally
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