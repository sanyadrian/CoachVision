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

struct TrainingPlan: Codable, Identifiable {
    let id: Int
    let userId: Int
    let planType: String
    let content: String
    let createdAt: String
    let isActive: Bool
    var completedDays: Set<String> // Track completed days
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case planType = "plan_type"
        case content
        case createdAt = "created_at"
        case isActive = "is_active"
        case completedDays
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        userId = try container.decode(Int.self, forKey: .userId)
        planType = try container.decode(String.self, forKey: .planType)
        content = try container.decode(String.self, forKey: .content)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        isActive = try container.decode(Bool.self, forKey: .isActive)
        completedDays = try container.decodeIfPresent(Set<String>.self, forKey: .completedDays) ?? []
    }
    
    // Computed properties for display
    var title: String {
        return "\(planType.capitalized) Plan"
    }
    
    var subtitle: String {
        // Extract focus area from content or use plan type
        if content.contains("strength") { return "Strength Training" }
        if content.contains("cardio") { return "Cardio" }
        if content.contains("flexibility") { return "Flexibility" }
        return "Mixed Training"
    }
    
    var progress: Double {
        // Calculate progress based on completed days
        let totalDays = 7.0 // Weekly plans have 7 days
        return Double(completedDays.count) / totalDays
    }
    
    var formattedDate: String {
        // Convert createdAt to a readable format
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        
        if let date = formatter.date(from: createdAt) {
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
        return "Recent"
    }
    
    // Helper method to check if a day is completed
    func isDayCompleted(_ day: String) -> Bool {
        return completedDays.contains(day.lowercased())
    }
    
    // Helper method to toggle day completion
    mutating func toggleDayCompletion(_ day: String) {
        let dayKey = day.lowercased()
        if completedDays.contains(dayKey) {
            completedDays.remove(dayKey)
        } else {
            completedDays.insert(dayKey)
        }
    }
} 