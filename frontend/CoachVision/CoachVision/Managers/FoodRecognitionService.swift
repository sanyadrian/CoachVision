import Foundation
import UIKit

struct FoodItem: Codable {
    let name: String
    let calories: Int
    let protein: Double
    let carbs: Double
    let fats: Double
    let confidence: Double
}

class FoodRecognitionService: ObservableObject {
    @Published var isAnalyzing = false
    @Published var errorMessage: String?
    
    func recognizeFood(from image: UIImage, completion: @escaping (Result<FoodItem, Error>) -> Void) {
        isAnalyzing = true
        errorMessage = nil
        
        // Simulate API call delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.isAnalyzing = false
            
            // Mock food recognition response
            let mockFoods = [
                FoodItem(name: "Grilled Chicken Breast", calories: 165, protein: 31.0, carbs: 0.0, fats: 3.6, confidence: 0.95),
                FoodItem(name: "Salmon Fillet", calories: 208, protein: 25.0, carbs: 0.0, fats: 12.0, confidence: 0.92),
                FoodItem(name: "Mixed Salad", calories: 45, protein: 2.5, carbs: 8.0, fats: 0.3, confidence: 0.88),
                FoodItem(name: "Brown Rice", calories: 216, protein: 4.5, carbs: 45.0, fats: 1.8, confidence: 0.90),
                FoodItem(name: "Broccoli", calories: 55, protein: 3.7, carbs: 11.2, fats: 0.6, confidence: 0.85),
                FoodItem(name: "Banana", calories: 105, protein: 1.3, carbs: 27.0, fats: 0.4, confidence: 0.98),
                FoodItem(name: "Apple", calories: 95, protein: 0.5, carbs: 25.0, fats: 0.3, confidence: 0.97),
                FoodItem(name: "Greek Yogurt", calories: 130, protein: 22.0, carbs: 9.0, fats: 0.5, confidence: 0.93),
                FoodItem(name: "Oatmeal", calories: 150, protein: 5.0, carbs: 27.0, fats: 3.0, confidence: 0.91),
                FoodItem(name: "Eggs", calories: 140, protein: 12.0, carbs: 1.0, fats: 10.0, confidence: 0.94)
            ]
            
            let randomFood = mockFoods.randomElement()!
            completion(.success(randomFood))
        }
    }
}

enum FoodRecognitionError: Error, LocalizedError {
    case invalidImage
    case noData
    case noFoodDetected
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image format"
        case .noData:
            return "No data received from server"
        case .noFoodDetected:
            return "No food detected in image"
        }
    }
} 