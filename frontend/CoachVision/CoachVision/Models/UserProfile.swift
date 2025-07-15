import Foundation

enum FitnessGoal: String, CaseIterable, Codable {
    case weightLoss = "weight_loss"
    case muscleGain = "muscle_gain"
    case generalFitness = "general_fitness"
    case endurance = "endurance"
    case flexibility = "flexibility"
    
    var displayName: String {
        switch self {
        case .weightLoss: return "Weight Loss"
        case .muscleGain: return "Muscle Gain"
        case .generalFitness: return "General Fitness"
        case .endurance: return "Endurance"
        case .flexibility: return "Flexibility"
        }
    }
}

enum ExperienceLevel: String, CaseIterable, Codable {
    case beginner = "beginner"
    case intermediate = "intermediate"
    case advanced = "advanced"
    
    var displayName: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        }
    }
}

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