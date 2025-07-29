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
        print("🔍 MealManager: updateAuth - token: \(token != nil), userId: \(userId)")
        self.authToken = token
        self.userId = userId
    }
    
    func fetchMeals(for date: Date) async {
        print("🔍 MealManager: fetchMeals - token: \(authToken != nil), userId: \(userId)")
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
            print("🔍 MealManager: Fetched \(decoded.count) meals for date \(dateString)")
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
        print("🔍 MealManager: addMeal - token: \(authToken != nil), userId: \(userId)")
        guard let token = authToken, let userId = userId else {
            print("No auth token or user ID for adding meal")
            completion(false)
            return
        }
        guard let url = URL(string: "http://192.168.4.27:8000/meals") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let mealDict: [String: Any] = [
            "user_id": userId,
            "name": meal.name,
            "calories": meal.calories,
            "protein": meal.protein,
            "carbs": meal.carbs,
            "fats": meal.fats,
            "date": meal.date
        ]
        do {
            let data = try JSONSerialization.data(withJSONObject: mealDict)
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
                if let data = data {
                    print("Meal add response: \(String(data: data, encoding: .utf8) ?? "nil")")
                    do {
                        let newMeal = try JSONDecoder().decode(Meal.self, from: data)
                        self.meals.append(newMeal)
                        completion(true)
                    } catch {
                        print("Failed to decode meal from response: \(error)")
                        completion(false)
                    }
                } else {
                    completion(false)
                }
            }
        }.resume()
    }
    
    func meals(for date: Date) -> [Meal] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)
        let filteredMeals = meals.filter { $0.date == dateString }
        print("🔍 MealManager: meals(for: \(date)) - looking for \(dateString), found \(filteredMeals.count) meals out of \(meals.count) total")
        return filteredMeals
    }
    
    func totalCalories(for date: Date) -> Int {
        let mealsForDate = meals(for: date)
        let total = mealsForDate.reduce(0) { $0 + $1.calories }
        print("🔍 MealManager: totalCalories for \(date) - found \(mealsForDate.count) meals, total: \(total)")
        return total
    }
    
    func totalProtein(for date: Date) -> Int {
        meals(for: date).reduce(0) { $0 + $1.protein }
    }
    
    func totalCarbs(for date: Date) -> Int {
        meals(for: date).reduce(0) { $0 + $1.carbs }
    }
    
    func totalFats(for date: Date) -> Int {
        meals(for: date).reduce(0) { $0 + $1.fats }
    }
    
    func deleteMeal(_ mealId: Int, completion: @escaping (Bool) -> Void) {
        print("🔍 MealManager: deleteMeal - token: \(authToken != nil), userId: \(userId)")
        guard let token = authToken else {
            print("No auth token for deleting meal")
            completion(false)
            return
        }
        guard let url = URL(string: "http://192.168.4.27:8000/meals/\(mealId)") else { 
            completion(false)
            return 
        }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error deleting meal: \(error)")
                    completion(false)
                    return
                }
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    print("Failed to delete meal, status code: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
                    completion(false)
                    return
                }
                // Remove meal from local array
                self.meals.removeAll { $0.id == mealId }
                print("🔍 MealManager: Successfully deleted meal with ID \(mealId)")
                completion(true)
            }
        }.resume()
    }
} 