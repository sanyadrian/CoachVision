import Foundation

struct Meal: Identifiable, Codable {
    let id: UUID
    let name: String
    let calories: Int
    let protein: Int
    let carbs: Int
    let fats: Int
    let date: Date
} 