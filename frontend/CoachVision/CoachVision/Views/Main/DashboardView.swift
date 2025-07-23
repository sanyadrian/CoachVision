import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var planManager: TrainingPlanManager
    @State private var videoAnalyses: [VideoAnalysis] = []
    @State private var selectedDayIndex: Int = 0

    // Dummy week dates for now
    var weekDates: [Date] {
        let today = Date()
        var dates: [Date] = []
        for i in 0..<7 {
            if let date = Calendar.current.date(byAdding: .day, value: i, to: today) {
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
                        let day = Calendar.current.component(.day, from: date)
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

            // Training Plan Progress Card (placeholder)
            VStack(alignment: .leading, spacing: 12) {
                Text("Training Plan Progress")
                    .font(.headline)
                    .foregroundColor(.white)
                ProgressView(value: 0.5)
                    .accentColor(.green)
                Text("50% complete")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text("Workout for Monday:")
                    .font(.subheadline)
                    .foregroundColor(.white)
                Text("Pushups, Squats, Plank")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color(red: 0.1, green: 0.1, blue: 0.15))
            .cornerRadius(16)
            .padding(.horizontal, 20)

            // Video Analysis Progress Card (placeholder)
            VStack(alignment: .leading, spacing: 12) {
                Text("Video Analysis Progress")
                    .font(.headline)
                    .foregroundColor(.white)
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
                if let nutrition = dummyNutrition[selectedDayName] {
                    HStack {
                        // Placeholder for pie chart
                        Circle()
                            .fill(Color.gray.opacity(0.3))
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

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 20)
        .background(Color.black)
    }
}

#Preview {
    DashboardView()
        .environmentObject(AuthenticationManager())
        .environmentObject(TrainingPlanManager(authToken: nil))
        .preferredColorScheme(.dark)
} 