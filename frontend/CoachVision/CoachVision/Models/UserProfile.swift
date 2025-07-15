import Foundation

struct UserProfile: Codable, Identifiable {
    let id: Int
    let email: String
    let name: String
    let age: Int?
    let weight: Double?
    let height: Double?
    let fitnessGoal: String?
    let experienceLevel: String?
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, email, name, age, weight, height
        case fitnessGoal = "fitness_goal"
        case experienceLevel = "experience_level"
        case createdAt = "created_at"
    }
    
    var isProfileComplete: Bool {
        return age != nil && weight != nil && height != nil && 
               fitnessGoal != nil && experienceLevel != nil
    }
}

// Response models for API
struct TokenResponse: Codable {
    let access_token: String
    let token_type: String
}

struct ErrorResponse: Codable {
    let detail: String
} 