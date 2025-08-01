import Foundation

class TrainingPlanManager: ObservableObject {
    @Published var plans: [TrainingPlan] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var refreshTrigger = UUID() // Force UI refresh
    
    private let baseURL = "http://192.168.4.27:8000"  // Your computer's local IP
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
    
    func deletePlan(planId: Int) async {
        print("Deleting plan with ID: \(planId)")
        
        // Remove from local array immediately for UI responsiveness
        await MainActor.run {
            plans.removeAll { $0.id == planId }
            print("Removed plan \(planId) from local array. Remaining plans: \(plans.count)")
        }
        
        await performRequest(
            endpoint: "/plans/\(planId)",
            method: "DELETE",
            body: [:]
        )
    }
    
    func deleteActivePlans() async {
        print("Deleting all active plans")
        
        // Get all active plan IDs
        let activePlanIds = plans.filter { $0.isActive }.map { $0.id }
        print("Found \(activePlanIds.count) active plans to delete: \(activePlanIds)")
        
        // Remove active plans from local array immediately
        await MainActor.run {
            plans.removeAll { $0.isActive }
            print("Removed active plans from local array. Remaining plans: \(plans.count)")
        }
        
        // Delete each active plan from backend
        for planId in activePlanIds {
            await performRequest(
                endpoint: "/plans/\(planId)",
                method: "DELETE",
                body: [:]
            )
        }
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
    
    func editPlanDay(planId: Int, dayName: String, workout: [String: Any], completion: @escaping (Bool) -> Void) {
        guard let token = authToken else { 
            completion(false)
            return 
        }
        guard let url = URL(string: "http://192.168.4.27:8000/plans/\(planId)/edit-day") else { 
            completion(false)
            return 
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "day_name": dayName,
            "workout": workout
        ]
        
        do {
            let data = try JSONSerialization.data(withJSONObject: body)
            request.httpBody = data
        } catch {
            print("❌ Failed to encode edit request: \(error)")
            completion(false)
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Error editing plan day: \(error)")
                    completion(false)
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    print("❌ Failed to edit plan day, status code: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
                    completion(false)
                    return
                }
                
                // Update local plan data
                if let planIndex = self.plans.firstIndex(where: { $0.id == planId }) {
                    let originalPlan = self.plans[planIndex]
                    
                    // Parse the current plan content
                    if let planData = try? JSONSerialization.jsonObject(with: originalPlan.content.data(using: .utf8) ?? Data()) as? [String: Any] {
                        var mutablePlanData = planData
                        
                        // Update the specific day in the workouts
                        if var workouts = mutablePlanData["workouts"] as? [String: Any] {
                            workouts[dayName] = workout
                            mutablePlanData["workouts"] = workouts
                            
                            // Update the plan content
                            if let updatedContent = try? JSONSerialization.data(withJSONObject: mutablePlanData),
                               let contentString = String(data: updatedContent, encoding: .utf8) {
                                
                                // Create a new plan instance with updated content
                                let updatedPlan = TrainingPlan(
                                    id: originalPlan.id,
                                    userId: originalPlan.userId,
                                    planType: originalPlan.planType,
                                    content: contentString,
                                    createdAt: originalPlan.createdAt,
                                    isActive: originalPlan.isActive,
                                    completedDays: originalPlan.completedDays
                                )
                                
                                // Force UI refresh by updating on main thread
                                DispatchQueue.main.async {
                                    self.plans[planIndex] = updatedPlan
                                    self.refreshTrigger = UUID() // Force UI refresh
                                    print("✅ Local plan data updated for day \(dayName)")
                                    print("🔍 Updated plan content preview: \(String(contentString.prefix(200)))...")
                                }
                            }
                        }
                    }
                }
                
                print("✅ Plan day \(dayName) updated successfully")
                completion(true)
            }
        }.resume()
    }
} 