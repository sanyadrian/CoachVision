import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var planManager: TrainingPlanManager
    @EnvironmentObject var mealManager: MealManager
    @State private var videoAnalyses: [VideoAnalysis] = []
    @State private var selectedDayIndex: Int = 0
    @State private var showMealSheet: Bool = false
    @State private var showMealScanning: Bool = false
    @State private var newMealName: String = ""
    @State private var newMealCalories: String = ""
    @State private var newMealProtein: String = ""
    @State private var newMealCarbs: String = ""
    @State private var newMealFats: String = ""
    @State private var mealAddError: String? = nil

    // Dummy week dates for now
    var weekDates: [Date] {
        guard let plan = currentPlan else { return [] }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        guard let startDate = formatter.date(from: plan.createdAt) else { return [] }
        // Find the most recent Monday before or on startDate
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: startDate)
        // In Calendar, Sunday = 1, Monday = 2, ..., Saturday = 7
        let daysToMonday = (weekday == 2) ? 0 : ((weekday == 1) ? 6 : weekday - 2)
        guard let monday = calendar.date(byAdding: .day, value: -daysToMonday, to: startDate) else { return [] }
        var dates: [Date] = []
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: i, to: monday) {
                dates.append(date)
            }
        }
        return dates
    }

    func shortWeekday(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
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

    var selectedDayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        guard selectedDayIndex < weekDates.count else { return "monday" }
        let date = weekDates[selectedDayIndex]
        return formatter.string(from: date).lowercased()
    }

    // Computed property for current plan
    var currentPlan: TrainingPlan? {
        planManager.plans.first(where: { $0.isActive }) ?? planManager.plans.first
    }

    // Helper to parse workout for selected day from plan content
    func workoutForSelectedDay(plan: TrainingPlan?) -> String? {
        guard let plan = plan else { return nil }
        guard let data = plan.content.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let workouts = json["workouts"] as? [String: Any] else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        let day = formatter.string(from: weekDates[selectedDayIndex]).lowercased()
        print("Looking for workout for day: \(day)")
        print("Available workout keys: \(workouts.keys)")
        print("Value for \(day): \(String(describing: workouts[day]))")
        if let dict = workouts[day] as? [String: Any] {
            if let exercises = dict["exercises"] as? [String] {
                let workoutType = dict["workout_type"] as? String
                let exercisesList = exercises.joined(separator: "\n")
                if let workoutType = workoutType {
                    return "\(workoutType):\n\(exercisesList)"
                } else {
                    return exercisesList
                }
            }
            if let workout = dict["workout"] as? String {
                return workout
            }
        } else if let workout = workouts[day] as? String {
            return workout
        }
        return nil
    }

    func fetchVideoAnalyses() {
        guard let token = authManager.authToken,
              let userId = authManager.currentUser?.id else {
            print("No authentication available")
            return
        }

        let url = URL(string: "http://192.168.4.27:8000/videos/user/\(userId)")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error fetching video analyses: \(error)")
                    return
                }

                if let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode == 200,
                   let data = data {
                    do {
                        let analyses = try JSONDecoder().decode([VideoAnalysis].self, from: data)
                        self.videoAnalyses = analyses
                        print("Fetched \(analyses.count) video analyses")
                    } catch {
                        print("Error decoding video analyses: \(error)")
                    }
                } else {
                    print("Failed to fetch video analyses")
                }
            }
        }.resume()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            Text("Welcome back,")
                .font(.title2)
                .foregroundColor(.gray)
            Text(authManager.currentUser?.name ?? "User")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.bottom, 10)

            // Week Bar
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(weekDates.indices, id: \.self) { idx in
                        let date = weekDates[idx]
                        let isSelected = idx == selectedDayIndex
                        let day = Calendar.current.component(.day, from: date)
                        let month = DateFormatter().monthSymbols[Calendar.current.component(.month, from: date) - 1].prefix(3)
                        let plan = currentPlan
                        let fullDayName: String = {
                            let formatter = DateFormatter()
                            formatter.dateFormat = "EEEE"
                            return formatter.string(from: date).lowercased()
                        }()
                        let isCompleted = plan?.completedDays.contains(fullDayName) ?? false
                        VStack {
                            Text(shortWeekday(date: date))
                                .font(.caption)
                                .foregroundColor(isSelected ? .white : .gray)
                            Text("\(day)")
                                .font(.headline)
                                .fontWeight(isSelected ? .bold : .regular)
                                .foregroundColor(isSelected ? .white : .gray)
                            Text(month)
                                .font(.caption2)
                                .foregroundColor(.gray)
                            if isCompleted {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.caption)
                            }
                        }
                        .padding(10)
                        .background(isSelected ? Color.blue : Color.clear)
                        .cornerRadius(10)
                        .onTapGesture { selectedDayIndex = idx }
                    }
                }
                .padding(.horizontal, 20)
            }

            // Training Plan Progress Card (dynamic)
            if let plan = currentPlan {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Training Plan Progress")
                        .font(.headline)
                        .foregroundColor(.white)
                    ProgressView(value: plan.progress)
                        .accentColor(.green)
                    Text("\(Int(plan.progress * 100))% complete")
                        .font(.caption)
                        .foregroundColor(.gray)
                    if let workout = workoutForSelectedDay(plan: plan) {
                        Text("Workout for \(selectedDayName.capitalized):")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        Text(workout)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.leading)
                    } else {
                        Text("No workout scheduled for \(selectedDayName.capitalized)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color(red: 0.1, green: 0.1, blue: 0.15))
                .cornerRadius(16)
                .padding(.horizontal, 20)
            }

            // Video Analysis Progress Card (dynamic)
            let videoCount = videoAnalyses.count
            let avgFormScore = videoAnalyses.isEmpty ? 0 : Int(videoAnalyses.map { $0.confidenceScore }.reduce(0, +) / Double(videoAnalyses.count))
            VStack(alignment: .leading, spacing: 12) {
                Text("Video Analysis Progress")
                    .font(.headline)
                    .foregroundColor(.white)
                HStack {
                    VStack(alignment: .leading) {
                        Text("Videos analyzed")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("\(videoCount)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    Spacer()
                    VStack(alignment: .leading) {
                        Text("Avg. Form Score")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("\(avgFormScore)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
                // Dummy trend bar
                HStack(spacing: 4) {
                    ForEach([70, 75, 80, 85, 90], id: \.self) { score in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.blue)
                            .frame(width: 16, height: CGFloat(score) * 0.5)
                    }
                }
                .frame(height: 40)
            }
            .padding()
            .background(Color(red: 0.1, green: 0.1, blue: 0.15))
            .cornerRadius(16)
            .padding(.horizontal, 20)

            // Nutrition Card (placeholder)
            VStack(alignment: .leading, spacing: 12) {
                Text("Nutrition")
                    .font(.headline)
                    .foregroundColor(.white)
                // Use real nutrition data from mealManager
                let selectedDate = weekDates.indices.contains(selectedDayIndex) ? weekDates[selectedDayIndex] : Date()
                let totalCalories = mealManager.totalCalories(for: selectedDate)
                let totalProtein = mealManager.totalProtein(for: selectedDate)
                let totalCarbs = mealManager.totalCarbs(for: selectedDate)
                let totalFats = mealManager.totalFats(for: selectedDate)
                
                HStack {
                    // Placeholder for pie chart
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 80, height: 80)
                    VStack(alignment: .leading, spacing: 4) {
                        // Calories is tappable
                        Button(action: { showMealSheet = true }) {
                            Text("Calories: \(totalCalories)")
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .underline()
                        }
                        
                        // Macronutrient breakdown with progress bars
                        MacronutrientRow(name: "Protein", value: totalProtein, color: .red, maxValue: 150)
                        MacronutrientRow(name: "Carbs", value: totalCarbs, color: .green, maxValue: 300)
                        MacronutrientRow(name: "Fats", value: totalFats, color: .yellow, maxValue: 80)
                    }
                }
                .padding(.bottom, 4)
                
                // Scan button
                Button(action: { showMealScanning = true }) {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text("Scan Meal")
                    }
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .cornerRadius(8)
                }
            }
            .padding()
            .background(Color(red: 0.1, green: 0.1, blue: 0.15))
            .cornerRadius(16)
            .padding(.horizontal, 20)
            .sheet(isPresented: $showMealSheet) {
                MealSheetView(
                    meals: mealManager.meals(for: weekDates[selectedDayIndex]),
                    selectedDate: weekDates[selectedDayIndex],
                    showMealSheet: $showMealSheet,
                    newMealName: $newMealName,
                    newMealCalories: $newMealCalories,
                    newMealProtein: $newMealProtein,
                    newMealCarbs: $newMealCarbs,
                    newMealFats: $newMealFats,
                    mealAddError: $mealAddError,
                    addMealAction: {
                        guard let calories = Int(newMealCalories),
                              let protein = Int(newMealProtein),
                              let carbs = Int(newMealCarbs),
                              let fats = Int(newMealFats),
                              !newMealName.isEmpty else {
                            mealAddError = "Please fill all fields with valid values."
                            return
                        }
                        let selectedDate = weekDates.indices.contains(selectedDayIndex) ? weekDates[selectedDayIndex] : Date()
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy-MM-dd"
                        let dateString = formatter.string(from: selectedDate)
                        let meal = Meal(id: 0, name: newMealName, calories: calories, protein: protein, carbs: carbs, fats: fats, date: dateString)
                        mealManager.addMeal(meal) { success in
                            if success {
                                newMealName = ""
                                newMealCalories = ""
                                newMealProtein = ""
                                newMealCarbs = ""
                                newMealFats = ""
                                mealAddError = nil
                                // Refresh meals
                                Task { await mealManager.fetchMeals(for: selectedDate) }
                            } else {
                                mealAddError = "Failed to add meal."
                            }
                        }
                    }
                )
            }
            .sheet(isPresented: $showMealScanning) {
                MealScanningView(selectedDate: weekDates.indices.contains(selectedDayIndex) ? weekDates[selectedDayIndex] : Date())
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 20)
        .background(Color.black)
        .onAppear {
            print("Plans loaded: \(planManager.plans)")
            if let plan = currentPlan {
                print("Current plan: \(plan)")
            } else {
                print("No current plan found")
            }
            // Fetch plans if not already loaded
            if let userId = authManager.currentUser?.id, planManager.plans.isEmpty {
                Task {
                    await planManager.fetchPlans(userId: userId)
                }
            }
            fetchVideoAnalyses()
            // Fetch meals for the selected day
            Task {
                if weekDates.indices.contains(selectedDayIndex) {
                    await mealManager.fetchMeals(for: weekDates[selectedDayIndex])
                }
            }
        }
        .onChange(of: selectedDayIndex) { newValue in
            Task {
                if weekDates.indices.contains(newValue) {
                    await mealManager.fetchMeals(for: weekDates[newValue])
                }
            }
        }
    }
}

struct MealSheetView: View {
    let meals: [Meal]
    let selectedDate: Date
    @Binding var showMealSheet: Bool
    @Binding var newMealName: String
    @Binding var newMealCalories: String
    @Binding var newMealProtein: String
    @Binding var newMealCarbs: String
    @Binding var newMealFats: String
    @Binding var mealAddError: String?
    var addMealAction: () -> Void

    var body: some View {
        VStack {
            Text("Meals for the day")
                .font(.title2)
                .padding()
            List(meals) { meal in
                VStack(alignment: .leading) {
                    Text(meal.name)
                        .font(.headline)
                    Text("Calories: \(meal.calories)")
                        .font(.caption)
                    Text("Protein: \(meal.protein)g, Carbs: \(meal.carbs)g, Fats: \(meal.fats)g")
                        .font(.caption2)
                }
            }
            Divider().padding(.vertical, 8)
            Text("Add Meal Manually")
                .font(.headline)
            TextField("Meal name", text: $newMealName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            HStack {
                TextField("Calories", text: $newMealCalories)
                    .keyboardType(.numberPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                TextField("Protein", text: $newMealProtein)
                    .keyboardType(.numberPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                TextField("Carbs", text: $newMealCarbs)
                    .keyboardType(.numberPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                TextField("Fats", text: $newMealFats)
                    .keyboardType(.numberPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding(.horizontal)
            if let error = mealAddError {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            Button("Add Meal", action: addMealAction)
                .padding()
            Button("Close") { showMealSheet = false }
                .padding()
        }
    }
}

// Macronutrient Row Component
struct MacronutrientRow: View {
    let name: String
    let value: Int
    let color: Color
    let maxValue: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text("\(name): \(value)g")
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 4)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: min(CGFloat(value) / CGFloat(maxValue) * geometry.size.width, geometry.size.width), height: 4)
                }
            }
            .frame(height: 4)
        }
    }
}

#Preview {
    DashboardView()
        .environmentObject(AuthenticationManager())
        .environmentObject(TrainingPlanManager(authToken: nil))
        .preferredColorScheme(.dark)
} 
