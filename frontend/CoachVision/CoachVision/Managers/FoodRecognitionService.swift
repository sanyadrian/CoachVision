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

struct OpenAIFoodItem: Codable {
    let name: String
    let calories: Int
    let protein: Double
    let carbs: Double
    let fats: Double
    let confidence: Double = 0.9
}

class FoodRecognitionService: ObservableObject {
    @Published var isAnalyzing = false
    @Published var errorMessage: String?
    
    private let baseURL = "https://flash-list.com"
    private var authToken: String?
    
    func updateAuthToken(_ token: String?) {
        self.authToken = token
    }
    
    func recognizeFood(from image: UIImage, completion: @escaping (Result<FoodItem, Error>) -> Void) {
        isAnalyzing = true
        errorMessage = nil
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            isAnalyzing = false
            completion(.failure(FoodRecognitionError.invalidImage))
            return
        }
        
        let base64Image = imageData.base64EncodedString()
        
        Task {
            await performOpenAIRecognition(base64Image: base64Image, completion: completion)
        }
    }
    
    private func performOpenAIRecognition(base64Image: String, completion: @escaping (Result<FoodItem, Error>) -> Void) async {
        guard let url = URL(string: "\(baseURL)/meals/analyze-food") else {
            await MainActor.run {
                isAnalyzing = false
                completion(.failure(FoodRecognitionError.invalidURL))
            }
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let body: [String: Any] = [
            "image": base64Image
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            await MainActor.run {
                isAnalyzing = false
                completion(.failure(error))
            }
            return
        }
        
        print("Making OpenAI food recognition request...")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            print("OpenAI response status code: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
            print("OpenAI response data: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")
            
            guard let httpResponse = response as? HTTPURLResponse else {
                await MainActor.run {
                    isAnalyzing = false
                    completion(.failure(FoodRecognitionError.apiError("Invalid HTTP response")))
                }
                return
            }
            
            if httpResponse.statusCode != 200 {
                await MainActor.run {
                    isAnalyzing = false
                    completion(.failure(FoodRecognitionError.apiError("API returned status code \(httpResponse.statusCode)")))
                }
                return
            }
            
            // Parse the OpenAI response
            let openAIFood = try JSONDecoder().decode(OpenAIFoodItem.self, from: data)
            
            // Convert to our FoodItem format
            let foodItem = FoodItem(
                name: openAIFood.name,
                calories: openAIFood.calories,
                protein: openAIFood.protein,
                carbs: openAIFood.carbs,
                fats: openAIFood.fats,
                confidence: openAIFood.confidence
            )
            
            await MainActor.run {
                isAnalyzing = false
                print("OpenAI recognized: \(foodItem.name) with \(foodItem.calories) calories")
                completion(.success(foodItem))
            }
            
        } catch {
            await MainActor.run {
                isAnalyzing = false
                print("OpenAI recognition error: \(error)")
                completion(.failure(error))
            }
        }
    }
}

enum FoodRecognitionError: Error, LocalizedError {
    case invalidImage
    case noData
    case noFoodDetected
    case invalidURL
    case custom(String)
    
    static func apiError(_ message: String) -> FoodRecognitionError {
        return .custom(message)
    }
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image format"
        case .noData:
            return "No data received from server"
        case .noFoodDetected:
            return "No food detected in image"
        case .invalidURL:
            return "Invalid URL"
        case .custom(let message):
            return message
        }
    }
} 