import Foundation
import SwiftUI

class MealManager: ObservableObject {
    @Published var meals: [Meal] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    var authToken: String?
    var userId: Int?
    
    init(authToken: String?, userId: Int?) {
        self.authToken = authToken
        self.userId = userId
    }
    
    func updateAuth(token: String?, userId: Int?) {
        self.authToken = token
        self.userId = userId
    }
    
    func fetchMeals(for date: Date) async {
        guard let token = authToken, let userId = userId else {
            print("No auth token or user ID for fetching meals")
            return
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)
        guard let url = URL(string: "http://192.168.4.27:8000/meals/user/\(userId)?date=\(dateString)") else { return }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        isLoading = true
        errorMessage = nil
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                errorMessage = "Failed to fetch meals"
                isLoading = false
                return
            }
            let decoded = try JSONDecoder().decode([Meal].self, from: data)
            await MainActor.run {
                self.meals = decoded
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func addMeal(_ meal: Meal, completion: @escaping (Bool) -> Void) {
        guard let token = authToken else {
            print("No auth token for adding meal")
            completion(false)
            return
        }
        guard let url = URL(string: "http://192.168.4.27:8000/meals") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(meal)
            request.httpBody = data
        } catch {
            print("Failed to encode meal: \(error)")
            completion(false)
            return
        }
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error adding meal: \(error)")
                    completion(false)
                    return
                }
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
                    print("Failed to add meal, status code: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
                    completion(false)
                    return
                }
                if let data = data, let newMeal = try? JSONDecoder().decode(Meal.self, from: data) {
                    self.meals.append(newMeal)
                    completion(true)
                } else {
                    completion(false)
                }
            }
        }.resume()
    }
    
    func meals(for date: Date) -> [Meal] {
        let calendar = Calendar.current
        return meals.filter { calendar.isDate($0.date, inSameDayAs: date) }
    }
    
    func totalCalories(for date: Date) -> Int {
        meals(for: date).reduce(0) { $0 + $1.calories }
    }
} 