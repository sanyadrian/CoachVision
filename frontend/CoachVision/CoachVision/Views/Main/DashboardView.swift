import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var planManager: TrainingPlanManager
    // Dummy video analyses for now
    @State private var videoAnalyses: [VideoAnalysis] = []
    // Selected day index in the week
    @State private var selectedDayIndex: Int = 0
    
    // Helper: Get the current active plan
    var currentPlan: TrainingPlan? {
        planManager.plans.first(where: { $0.isActive }) ?? planManager.plans.first
    }
    // Helper: Parse week days from plan creation date
    var weekDates: [Date] {
        guard let plan = currentPlan else { return [] }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        guard let startDate = formatter.date(from: plan.createdAt) else { return [] }
        return (0..<7).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: startDate) }
    }
    var selectedDate: Date? {
        guard selectedDayIndex < weekDates.count else { return nil }
        return weekDates[selectedDayIndex]
    }
    var selectedDayName: String {
        guard let date = selectedDate else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date).lowercased()
    }
    // Dummy nutrition data
    let dummyNutrition: [String: (cal: Int, protein: Int, carbs: Int, fats: Int)] = [
        "monday": (2200, 120, 250, 70),
        "tuesday": (2100, 110, 240, 65),
        "wednesday": (2300, 130, 260, 75),
        "thursday": (2000, 100, 230, 60),
        "friday": (2250, 125, 255, 72),
        "saturday": (2400, 135, 270, 80),
        "sunday": (2150, 115, 245, 68)
    ]
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black,
                        Color(red: 0.1, green: 0.1, blue: 0.15),
                        Color(red: 0.05, green: 0.05, blue: 0.1)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Welcome back,")
                                .font(.title2)
                                .foregroundColor(.gray)
                            Text(authManager.currentUser?.name ?? "User")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        // Week Bar
                        if !weekDates.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(weekDates.indices, id: \.self) { idx in
                                        let date = weekDates[idx]
                                        let day = Calendar.current.component(.day, from: date)
                                        let month = Calendar.current.component(.month, from: date)
                                        let isSelected = idx == selectedDayIndex
                                        VStack {
                                            Text(shortWeekday(date: date))
                                                .font(.caption)
                                                .foregroundColor(isSelected ? .white : .gray)
                                            Text("\(day)")
                                                .font(.headline)
                                                .fontWeight(isSelected ? .bold : .regular)
                                                .foregroundColor(isSelected ? .white : .gray)
                                        }
                                        .padding(10)
                                        .background(isSelected ? Color.blue : Color.clear)
                                        .cornerRadius(10)
                                        .onTapGesture { selectedDayIndex = idx }
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        // DEBUG: Show loaded plans and their active status
                        if !planManager.plans.isEmpty {
                            VStack(alignment: .leading) {
                                Text("DEBUG: Plans loaded:")
                                    .foregroundColor(.yellow)
                                ForEach(planManager.plans, id: \.id) { plan in
                                    Text("Plan: \(plan.name), Active: \(plan.isActive ? "Yes" : "No")")
                                        .foregroundColor(.yellow)
                                }
                            }
                        }
                        // Training Plan Progress Card
                        TrainingPlanProgressCard(plan: currentPlan, selectedDay: selectedDayName)
                        // Video Analysis Progress Card (dummy)
                        VideoAnalysisProgressCard(videoAnalyses: videoAnalyses)
                        // Nutrition Card (placeholder)
                        NutritionCard(day: selectedDayName, nutrition: dummyNutrition[selectedDayName])
                        Spacer(minLength: 100)
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                print("Loaded plans: \(planManager.plans)")
                if let plan = planManager.plans.first {
                    print("First plan isActive: \(plan.isActive)")
                }
            }
        }
    }
    // Helper for short weekday
    func shortWeekday(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
}

// MARK: - Training Plan Progress Card
struct TrainingPlanProgressCard: View {
    let plan: TrainingPlan?
    let selectedDay: String
    
    // Helper to parse plan content JSON for workouts
    func parseWorkouts() -> [String: String] {
        guard let plan = plan else { return [:] }
        var cleanContent = plan.content.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanContent.hasPrefix("```json") { cleanContent = String(cleanContent.dropFirst(7)) }
        if cleanContent.hasPrefix("```") { cleanContent = String(cleanContent.dropFirst(3)) }
        if cleanContent.hasSuffix("```") { cleanContent = String(cleanContent.dropLast(3)) }
        cleanContent = cleanContent.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = cleanContent.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let workouts = json["workouts"] as? [String: Any] else { return [:] }
        var result: [String: String] = [:]
        for (day, value) in workouts {
            if let dict = value as? [String: Any], let workout = dict["workout"] as? String {
                result[day.lowercased()] = workout
            } else if let workout = value as? String {
                result[day.lowercased()] = workout
            }
        }
        return result
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Training Plan Progress")
                .font(.headline)
                .foregroundColor(.white)
            if let plan = plan {
                ProgressView(value: plan.progress)
                    .accentColor(.green)
                // Bar chart for week
                let workouts = parseWorkouts()
                let dayOrder = ["monday","tuesday","wednesday","thursday","friday","saturday","sunday"]
                HStack(spacing: 8) {
                    ForEach(dayOrder, id: \.self) { day in
                        VStack {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(plan.completedDays.contains(day) ? Color.green : Color.gray.opacity(0.3))
                                .frame(width: 18, height: 40)
                            Text(day.prefix(3).capitalized)
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.top, 4)
                Text("\(Int(plan.progress * 100))% complete")
                    .font(.caption)
                    .foregroundColor(.gray)
                // Show selected day's workout
                if let workout = workouts[selectedDay] {
                    Text("Workout for \(selectedDay.capitalized):")
                        .font(.subheadline)
                        .foregroundColor(.white)
                    Text(workout)
                        .font(.caption)
                        .foregroundColor(.gray)
                } else {
                    Text("No workout scheduled for \(selectedDay.capitalized)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            } else {
                Text("No active plan found.")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color(red: 0.1, green: 0.1, blue: 0.15))
        .cornerRadius(16)
        .padding(.horizontal, 20)
    }
}
// MARK: - Video Analysis Progress Card (Dummy)
struct VideoAnalysisProgressCard: View {
    let videoAnalyses: [VideoAnalysis]
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Video Analysis Progress")
                .font(.headline)
                .foregroundColor(.white)
            // Dummy stats
            HStack {
                VStack(alignment: .leading) {
                    Text("Videos analyzed")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("5")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                Spacer()
                VStack(alignment: .leading) {
                    Text("Avg. Form Score")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("82")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                Spacer()
                VStack(alignment: .leading) {
                    Text("Improvement")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("+5%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
            }
            // Dummy trend bar
            HStack(spacing: 4) {
                ForEach([70, 75, 80, 85, 90], id: \.self) { score in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.blue)
                        .frame(width: 16, height: CGFloat(score))
                }
            }
            .frame(height: 40)
        }
        .padding()
        .background(Color(red: 0.1, green: 0.1, blue: 0.15))
        .cornerRadius(16)
        .padding(.horizontal, 20)
    }
}
// MARK: - Nutrition Card (Placeholder with Pie Chart)
struct NutritionCard: View {
    let day: String
    let nutrition: (cal: Int, protein: Int, carbs: Int, fats: Int)?
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nutrition")
                .font(.headline)
                .foregroundColor(.white)
            if let nutrition = nutrition {
                HStack {
                    PieChartView(protein: nutrition.protein, carbs: nutrition.carbs, fats: nutrition.fats)
                        .frame(width: 80, height: 80)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Calories: \(nutrition.cal)")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        Text("Protein: \(nutrition.protein)g")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("Carbs: \(nutrition.carbs)g")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("Fats: \(nutrition.fats)g")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.bottom, 4)
                Text("Coming soon: Scan your meal to auto-track nutrition!")
                    .font(.caption2)
                    .foregroundColor(.orange)
            } else {
                Text("No nutrition data for this day.")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color(red: 0.1, green: 0.1, blue: 0.15))
        .cornerRadius(16)
        .padding(.horizontal, 20)
    }
}
// MARK: - Pie Chart View (Placeholder)
struct PieChartView: View {
    let protein: Int
    let carbs: Int
    let fats: Int
    var total: Int { protein + carbs + fats }
    var proteinRatio: Double { Double(protein) / Double(total) }
    var carbsRatio: Double { Double(carbs) / Double(total) }
    var fatsRatio: Double { Double(fats) / Double(total) }
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Circle()
                    .trim(from: 0, to: CGFloat(proteinRatio))
                    .stroke(Color.green, lineWidth: 16)
                    .rotationEffect(.degrees(-90))
                Circle()
                    .trim(from: CGFloat(proteinRatio), to: CGFloat(proteinRatio + carbsRatio))
                    .stroke(Color.blue, lineWidth: 16)
                    .rotationEffect(.degrees(-90))
                Circle()
                    .trim(from: CGFloat(proteinRatio + carbsRatio), to: 1)
                    .stroke(Color.orange, lineWidth: 16)
                    .rotationEffect(.degrees(-90))
            }
        }
    }
}

#Preview {
    DashboardView()
        .environmentObject(AuthenticationManager())
        .environmentObject(TrainingPlanManager(authToken: nil))
        .preferredColorScheme(.dark)
} 