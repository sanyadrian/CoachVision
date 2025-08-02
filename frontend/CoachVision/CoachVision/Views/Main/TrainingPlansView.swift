import SwiftUI

struct TrainingPlansView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showingCreatePlan = false
    @State private var plansCount = 0
    @State private var selectedPlan: TrainingPlan?
    @State private var showingPlanDetail = false
    @State private var showingReplacePlanAlert = false
    @State private var isReplacingPlan = false
    
    func checkAndCreatePlan() {
        // Check if there's an active plan
        let hasActivePlan = authManager.trainingPlanManager.plans.contains { $0.isActive }
        
        if hasActivePlan {
            // Show confirmation alert
            showingReplacePlanAlert = true
        } else {
            // No active plan, proceed directly
            isReplacingPlan = false
            showingCreatePlan = true
        }
    }
    
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
                            Text("Training Plans")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Your personalized workout plans")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        // Create New Plan Button
                        Button(action: {
                            checkAndCreatePlan()
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                Text("Create New Plan")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.white)
                            .cornerRadius(25)
                        }
                        .padding(.horizontal, 20)
                        
                        // Plans List
                        VStack(spacing: 16) {
                            HStack {
                                Text("Your Plans")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                // Debug info
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("(\(plansCount) plans)")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Text("Loading: \(authManager.trainingPlanManager.isLoading ? "Yes" : "No")")
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                }
                                
                                if authManager.trainingPlanManager.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                }
                            }
                            
                            if plansCount == 0 && !authManager.trainingPlanManager.isLoading {
                                // Empty state
                                VStack(spacing: 16) {
                                    Image(systemName: "dumbbell")
                                        .font(.system(size: 60))
                                        .foregroundColor(.gray)
                                    
                                    Text("No plans yet")
                                        .font(.headline)
                                        .foregroundColor(.gray)
                                    
                                    Text("Create your first training plan to get started")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 200)
                                .background(Color(red: 0.1, green: 0.1, blue: 0.15))
                                .cornerRadius(16)
                            } else {
                                                                // Plans list
                                VStack(spacing: 12) {
                                    ForEach(authManager.trainingPlanManager.plans) { plan in
                                        PlanCard(planId: plan.id)
                                            .environmentObject(authManager)
                                            .onTapGesture {
                                                print("Plan tapped: \(plan.title)")
                                                print("Plan ID: \(plan.id)")
                                                selectedPlan = plan
                                                print("selectedPlan set to plan")
                                            }
                                    }
                                }
                                .onAppear {
                                    print("Plans list appeared with \(authManager.trainingPlanManager.plans.count) plans")
                                    print("Plan IDs in list: \(authManager.trainingPlanManager.plans.map { $0.id })")
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer(minLength: 100)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingCreatePlan) {
            CreatePlanView(isReplacingExistingPlan: isReplacingPlan)
        }
        .sheet(item: $selectedPlan) { plan in
            PlanDetailView(plan: plan)
        }
        .alert("Replace Current Plan?", isPresented: $showingReplacePlanAlert) {
            Button("Yes, Replace") {
                isReplacingPlan = true
                showingCreatePlan = true
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("You already have an active training plan. Creating a new plan will replace your current one. Are you sure you want to continue?")
        }
        .task {
            // Fetch plans when view appears
            if let userId = authManager.currentUser?.id {
                print("Task: Fetching plans for user \(userId)")
                await authManager.trainingPlanManager.fetchPlans(userId: userId)
                print("Task: Plans count after fetch: \(authManager.trainingPlanManager.plans.count)")
                plansCount = authManager.trainingPlanManager.plans.count
            }
        }
        .refreshable {
            // Pull to refresh
            if let userId = authManager.currentUser?.id {
                await authManager.trainingPlanManager.fetchPlans(userId: userId)
                plansCount = authManager.trainingPlanManager.plans.count
            }
        }
        .onReceive(authManager.trainingPlanManager.$plans) { plans in
            plansCount = plans.count
            print("onReceive: Plans count updated to \(plans.count)")
            print("onReceive: Plan IDs: \(plans.map { $0.id })")
        }
    }
}

struct PlanCard: View {
    let planId: Int
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var currentPlan: TrainingPlan?
    
    init(planId: Int) {
        self.planId = planId
        print("PlanCard init: Created for plan \(planId)")
    }
    
    private func updateCurrentPlan() {
        print("PlanCard updateCurrentPlan: Looking for plan \(planId)")
        print("Available plans: \(authManager.trainingPlanManager.plans.map { $0.id })")
        currentPlan = authManager.trainingPlanManager.plans.first { $0.id == planId }
        print("Found plan: \(currentPlan?.title ?? "nil")")
    }
    
    var body: some View {
        Group {
            if let plan = currentPlan {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(plan.title)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            Text(plan.subtitle)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            Text(plan.formattedDate)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        if plan.isActive {
                            Text("ACTIVE")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green.opacity(0.2))
                                .cornerRadius(8)
                        }
                    }
                    
                    // Progress bar
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Progress")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Spacer()
                            
                            Text("\(Int(plan.progress * 100))%")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .onAppear {
                                    print("PlanCard showing progress: \(plan.progress * 100)% for plan \(plan.id)")
                                }
                        }
                        
                        ProgressView(value: plan.progress)
                            .progressViewStyle(LinearProgressViewStyle(tint: .green))
                    }
                }
                .padding()
                .background(Color(red: 0.1, green: 0.1, blue: 0.15))
                .cornerRadius(16)
            } else {
                // Fallback if plan not found
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Loading...")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            Text("Plan ID: \(planId)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    }
                    
                    // Progress bar placeholder
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Progress")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Spacer()
                            
                            Text("0%")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                        
                        ProgressView(value: 0)
                            .progressViewStyle(LinearProgressViewStyle(tint: .green))
                    }
                }
                .padding()
                .background(Color(red: 0.1, green: 0.1, blue: 0.15))
                .cornerRadius(16)
            }
        }
        .onReceive(authManager.trainingPlanManager.$plans) { plans in
            print("PlanCard onReceive: Plans updated, looking for plan \(planId)")
            updateCurrentPlan()
            print("PlanCard: Updated currentPlan for plan \(planId), progress: \(currentPlan?.progress ?? 0)")
        }
        .onAppear {
            print("PlanCard onAppear: Looking for plan \(planId)")
            updateCurrentPlan()
        }
    }
}

struct CreatePlanView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var planType = "weekly"
    @State private var focusArea = "strength"
    @State private var isCreating = false
    let isReplacingExistingPlan: Bool
    
    init(isReplacingExistingPlan: Bool = false) {
        self.isReplacingExistingPlan = isReplacingExistingPlan
    }
    
    private var userFitnessGoal: String {
        guard let goal = authManager.currentUser?.fitnessGoal else { return "general_fitness" }
        return goal
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Text("Create New Plan")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    // User Profile Info
                    VStack(spacing: 12) {
                        Text("Personalized for you")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Goal: \(userFitnessGoal.replacingOccurrences(of: "_", with: " ").capitalized)")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                
                                if let experience = authManager.currentUser?.experienceLevel {
                                    Text("Level: \(experience.capitalized)")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                if let age = authManager.currentUser?.age {
                                    Text("Age: \(age)")
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                }
                                
                                if let weight = authManager.currentUser?.weight {
                                    Text("Weight: \(Int(weight)) kg")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(red: 0.1, green: 0.1, blue: 0.15))
                    .cornerRadius(16)
                    
                    VStack(spacing: 16) {
                        // Plan Type (Weekly Only)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Plan Type")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            HStack {
                                Text("Weekly")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.green.opacity(0.2))
                                    .cornerRadius(8)
                                
                                Spacer()
                            }
                        }
                        
                        // Plan Duration
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Plan Duration")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("7-day personalized plan starting from today")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.top, 8)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    // Create Button
                    Button("Create Plan") {
                        Task {
                            isCreating = true
                            
                            // If replacing existing plan, delete active plans first
                            if isReplacingExistingPlan {
                                print("Replacing existing plan - deleting active plans first")
                                await authManager.trainingPlanManager.deleteActivePlans()
                            }
                            
                            await authManager.trainingPlanManager.createPlan(
                                planType: planType,
                                focusArea: focusArea,
                                userId: authManager.currentUser?.id ?? 0
                            )
                            // Refresh plans after creation
                            if let userId = authManager.currentUser?.id {
                                await authManager.trainingPlanManager.fetchPlans(userId: userId)
                            }
                            isCreating = false
                            dismiss()
                        }
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.white)
                    .cornerRadius(25)
                    .padding(.horizontal, 20)
                    .disabled(isCreating)
                    .opacity(isCreating ? 0.6 : 1.0)
                    
                    if isCreating {
                        ProgressView("Creating plan...")
                            .foregroundColor(.white)
                            .padding(.top, 8)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

struct SimplePlanDetailView: View {
    let plan: TrainingPlan
    @Environment(\.dismiss) var dismiss
    
    init(plan: TrainingPlan) {
        self.plan = plan
        print("SimplePlanDetailView initialized with plan: \(plan.title)")
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Plan Detail")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                
                Text("Title: \(plan.title)")
                    .foregroundColor(.white)
                
                Text("ID: \(plan.id)")
                    .foregroundColor(.white)
                
                Button("Close") {
                    dismiss()
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.blue)
                .cornerRadius(8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .onAppear {
            print("SimplePlanDetailView appeared")
        }
    }
}

struct PlanDetailView: View {
    let plan: TrainingPlan
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showingDeleteAlert = false
    @State private var isDeleting = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text(plan.title)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text(plan.subtitle)
                                .font(.headline)
                                .foregroundColor(.gray)
                            
                            HStack {
                                Text("Created: \(plan.formattedDate)")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                
                                Spacer()
                                
                                Text("Starts Today")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.green)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.green.opacity(0.2))
                                    .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        // Plan Content
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Your Training Plan")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                            
                            // Parse and display the JSON content
                            if let planData = parsePlanContent(plan.content) {
                                PlanContentView(planData: planData, planCreatedAt: plan.createdAt, plan: plan)
                                    .environmentObject(authManager)
                            } else {
                                // Fallback: show raw content
                                Text("Raw Plan Content:")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                
                                Text(plan.content)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(Color(red: 0.1, green: 0.1, blue: 0.15))
                                    .cornerRadius(8)
                                    .padding(.horizontal, 20)
                            }
                        }
                        
                        Spacer(minLength: 100)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingDeleteAlert = true
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .disabled(isDeleting)
                }
            }
            .alert("Delete Plan", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    Task {
                        await deletePlan()
                    }
                }
            } message: {
                Text("Are you sure you want to delete this plan? This action cannot be undone.")
            }
        }
    }
    
    private func parsePlanContent(_ content: String) -> [String: Any]? {
        // Remove markdown code blocks if present (robust)
        var cleanContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanContent.hasPrefix("```json") {
            cleanContent = String(cleanContent.dropFirst(7))
        }
        if cleanContent.hasPrefix("```") {
            cleanContent = String(cleanContent.dropFirst(3))
        }
        if cleanContent.hasSuffix("```") {
            cleanContent = String(cleanContent.dropLast(3))
        }
        cleanContent = cleanContent.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = cleanContent.data(using: .utf8) else { return nil }
        return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    }
    
    private func deletePlan() async {
        isDeleting = true
        guard let token = authManager.authToken else { isDeleting = false; return }
        guard let url = URL(string: "http://192.168.4.27:8000/plans/\(plan.id)") else { isDeleting = false; return }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                // Remove plan from list
                await MainActor.run {
                    if let idx = authManager.trainingPlanManager.plans.firstIndex(where: { $0.id == plan.id }) {
                        authManager.trainingPlanManager.plans.remove(at: idx)
                    }
                    dismiss()
                }
            }
        } catch {
            // Optionally show error
        }
        isDeleting = false
    }
}

struct PlanContentView: View {
    let planData: [String: Any]
    let planCreatedAt: String
    let planId: Int
    @State private var completedDays: Set<String>
    @State private var refreshKey = UUID() // Force view refresh
    @EnvironmentObject var authManager: AuthenticationManager
    
    init(planData: [String: Any], planCreatedAt: String, plan: TrainingPlan) {
        self.planData = planData
        self.planCreatedAt = planCreatedAt
        self.planId = plan.id
        self._completedDays = State(initialValue: plan.completedDays)
    }
    
    private var currentPlan: TrainingPlan? {
        authManager.trainingPlanManager.plans.first { $0.id == planId }
    }
    
    private var currentWorkouts: [String: Any]? {
        // Use refreshKey to force recalculation
        _ = refreshKey
        
        guard let currentPlan = currentPlan,
              let data = currentPlan.content.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let workouts = json["workouts"] as? [String: Any] else {
            return nil
        }
        print("🔍 PlanContentView: Getting current workouts for plan \(currentPlan.id)")
        print("🔍 PlanContentView: Workouts keys: \(workouts.keys)")
        
        // Debug: Print the actual workout data for the day being edited
        if let mondayWorkout = workouts["monday"] as? [String: Any] {
            print("🔍 PlanContentView: Monday workout type: \(mondayWorkout["workout_type"] ?? "nil")")
            if let exercises = mondayWorkout["exercises"] as? [String] {
                print("🔍 PlanContentView: Monday exercises: \(exercises)")
            }
        }
        
        return workouts
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Weekly plan - display by days
            if let workouts = currentWorkouts,
               let currentPlan = currentPlan {
                WorkoutsSection(
                    workouts: workouts, 
                    planCreatedAt: planCreatedAt,
                    plan: currentPlan,
                    completedDays: $completedDays,
                    onDayToggle: { day in
                        let dayKey = day.lowercased()
                        print("Toggling day: \(day) -> \(dayKey)")
                        print("Before toggle - completedDays: \(completedDays)")
                        
                        if completedDays.contains(dayKey) {
                            completedDays.remove(dayKey)
                            print("Removed \(dayKey) from completedDays")
                        } else {
                            completedDays.insert(dayKey)
                            print("Added \(dayKey) to completedDays")
                        }
                        
                        print("After toggle - completedDays: \(completedDays)")
                        print("Progress should be: \(Double(completedDays.count) / 7.0 * 100)%")
                        
                        // Save to backend
                        Task {
                            await authManager.trainingPlanManager.updateCompletedDays(
                                planId: currentPlan.id,
                                completedDays: completedDays
                            )
                        }
                    }
                )
                .environmentObject(authManager)
            }
            
            // Nutrition Section
            if let nutrition = planData["nutrition"] as? [String: Any] {
                NutritionSection(nutrition: nutrition)
            }
            
            // Recommendations Section
            if let recommendations = planData["recommendations"] as? [String: Any] {
                RecommendationsSection(recommendations: recommendations)
            }
        }
        .padding(.horizontal, 20)
        .onReceive(authManager.trainingPlanManager.$plans) { plans in
            // Update completedDays when the plan is updated
            if let updatedPlan = plans.first(where: { $0.id == planId }) {
                completedDays = updatedPlan.completedDays
                print("PlanContentView: Updated completedDays to \(completedDays)")
            }
        }
        .onReceive(authManager.trainingPlanManager.$refreshTrigger) { _ in
            // Force view refresh when refreshTrigger changes
            print("PlanContentView: Refresh trigger activated")
            refreshKey = UUID() // Force view to recalculate
        }
    }
}

struct WorkoutsSection: View {
    let workouts: [String: Any]
    let planCreatedAt: String
    let plan: TrainingPlan
    @Binding var completedDays: Set<String>
    let onDayToggle: (String) -> Void
    @EnvironmentObject var authManager: AuthenticationManager
    
    // Function to get days in correct order starting from the day the plan was created
    private func sortedDays() -> [String] {
        let dayOrder = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]
        let workoutDays = Array(workouts.keys)
        
        // Parse the creation date to get the day of week
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        
        guard let creationDate = formatter.date(from: planCreatedAt) else {
            print("Could not parse creation date: \(planCreatedAt)")
            return workoutDays
        }
        
        // Get the day of week when the plan was created
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: creationDate)
        // Convert from Calendar weekday (1=Sunday, 2=Monday, etc.) to our day order (0=Monday, 1=Tuesday, etc.)
        let creationDayIndex = (weekday + 5) % 7 // Adjust to make Monday=0, Tuesday=1, etc.
        
        print("Plan created on weekday: \(weekday), adjusted index: \(creationDayIndex)")
        print("Creation day: \(dayOrder[creationDayIndex])")
        
        // Create the correct order starting from the creation day
        var orderedDays: [String] = []
        for i in 0..<7 {
            let dayIndex = (creationDayIndex + i) % 7
            let dayName = dayOrder[dayIndex]
            print("Looking for day: \(dayName)")
            
            // Find the actual day name in workouts (preserving original casing)
            if let actualDay = workoutDays.first(where: { $0.lowercased() == dayName }) {
                orderedDays.append(actualDay)
                print("Added day: \(actualDay)")
            }
        }
        
        print("Final ordered days: \(orderedDays)")
        return orderedDays
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Workout Schedule")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            VStack(spacing: 8) {
                ForEach(sortedDays(), id: \.self) { day in
                    if let dayWorkout = workouts[day] as? [String: Any] {
                        DayWorkoutCard(
                            day: day, 
                            workout: dayWorkout,
                            isCompleted: completedDays.contains(day.lowercased()),
                            onToggleCompletion: {
                                onDayToggle(day)
                            },
                            planId: plan.id
                        )
                    } else if let restDay = workouts[day] as? String {
                        // Handle rest day as string
                        RestDayCard(day: day, description: restDay)
                    }
                }
            }
        }
    }
}

struct MonthlyWorkoutsSection: View {
    let weeks: [String: Any]
    
    // Function to get weeks in correct order
    private func sortedWeeks() -> [(String, [String: Any])] {
        let weekKeys = Array(weeks.keys).sorted { week1, week2 in
            // Extract week number and sort numerically
            let week1Num = Int(week1.replacingOccurrences(of: "week_", with: "")) ?? 0
            let week2Num = Int(week2.replacingOccurrences(of: "week_", with: "")) ?? 0
            return week1Num < week2Num
        }
        
        return weekKeys.compactMap { weekKey in
            if let weekData = weeks[weekKey] as? [String: Any] {
                return (weekKey, weekData)
            }
            return nil
        }
    }
    
    // Function to get days in a week in correct order
    private func sortedDaysInWeek(_ weekData: [String: Any]) -> [(String, Any)] {
        let dayOrder = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]
        let weekDays = Array(weekData.keys)
        
        var orderedDays: [(String, Any)] = []
        
        // Sort days according to the standard week order
        for dayName in dayOrder {
            if let actualDay = weekDays.first(where: { $0.lowercased().contains(dayName) }) {
                if let dayData = weekData[actualDay] {
                    orderedDays.append((actualDay, dayData))
                }
            }
        }
        
        return orderedDays
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Monthly Training Plan")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            VStack(spacing: 16) {
                ForEach(sortedWeeks(), id: \.0) { weekKey, weekData in
                    VStack(alignment: .leading, spacing: 12) {
                        // Week header
                        Text(weekKey.replacingOccurrences(of: "_", with: " ").capitalized)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                            .padding(.horizontal, 20)
                        
                        // Days in this week
                        VStack(spacing: 8) {
                            ForEach(sortedDaysInWeek(weekData), id: \.0) { dayKey, dayData in
                                if let dayWorkout = dayData as? [String: Any] {
                                    MonthlyDayWorkoutCard(day: dayKey, workout: dayWorkout)
                                } else if let restDay = dayData as? String {
                                    MonthlyRestDayCard(day: dayKey, description: restDay)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

struct MonthlyDayWorkoutCard: View {
    let day: String
    let workout: [String: Any]
    
    // Extract day name and date from the key (e.g., "monday_june_01" -> "Monday, June 01")
    private func formatDayDisplay() -> String {
        let components = day.split(separator: "_")
        if components.count >= 3 {
            let dayName = String(components[0]).capitalized
            let month = String(components[1]).capitalized
            let date = String(components[2])
            return "\(dayName), \(month) \(date)"
        }
        return day.capitalized
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(formatDayDisplay())
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                Spacer()
            }
            
            // Show workout type
            if let workoutType = workout["workout_type"] as? String {
                Text(workoutType)
                    .font(.subheadline)
                    .foregroundColor(.green)
            }
            
            // Show exercises
            if let exercises = workout["exercises"] as? [String] {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(exercises, id: \.self) { exercise in
                        HStack(alignment: .top) {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 6))
                                .foregroundColor(.gray)
                            Text(exercise)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(red: 0.1, green: 0.1, blue: 0.15))
        .cornerRadius(12)
        .padding(.horizontal, 20)
    }
}

struct MonthlyRestDayCard: View {
    let day: String
    let description: String
    
    // Extract day name and date from the key (e.g., "monday_june_01" -> "Monday, June 01")
    private func formatDayDisplay() -> String {
        let components = day.split(separator: "_")
        if components.count >= 3 {
            let dayName = String(components[0]).capitalized
            let month = String(components[1]).capitalized
            let date = String(components[2])
            return "\(dayName), \(month) \(date)"
        }
        return day.capitalized
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(formatDayDisplay())
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                Spacer()
                
                Text("Rest Day")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.2))
                    .cornerRadius(8)
            }
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(red: 0.1, green: 0.1, blue: 0.15))
        .cornerRadius(12)
        .padding(.horizontal, 20)
    }
}

struct DayWorkoutCard: View {
    let day: String
    let workout: [String: Any]
    let isCompleted: Bool
    let onToggleCompletion: () -> Void
    let planId: Int
    @State private var showEditSheet = false
    @EnvironmentObject var authManager: AuthenticationManager
    
    private var headerView: some View {
            HStack {
                Text(day.capitalized)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                Spacer()
            
            // Edit button
            Button(action: {
                showEditSheet = true
            }) {
                Image(systemName: "pencil")
                    .foregroundColor(.blue)
                    .font(.subheadline)
            }
            .buttonStyle(BorderlessButtonStyle())
                
                // Completion indicator
                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
            }
                }
            }
            
    private var workoutTypeView: some View {
        Group {
            if let workoutType = workout["workout_type"] as? String {
                Text(workoutType)
                    .font(.subheadline)
                    .foregroundColor(isCompleted ? .gray : .green)
            }
        }
            }
            
    private var exercisesView: some View {
        Group {
            if let exercises = workout["exercises"] as? [String] {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(exercises, id: \.self) { exercise in
                        HStack(alignment: .top) {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 6))
                                .foregroundColor(isCompleted ? .gray.opacity(0.5) : .gray)
                            Text(exercise)
                                .font(.subheadline)
                                .foregroundColor(isCompleted ? .gray.opacity(0.7) : .gray)
                        }
                    }
                }
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            headerView
            workoutTypeView
            exercisesView
        }
        .padding()
        .background(isCompleted ? Color.green.opacity(0.1) : Color(red: 0.1, green: 0.1, blue: 0.15))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isCompleted ? Color.green.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width < -50 { // Swipe left
                        onToggleCompletion()
                    }
                }
        )
        .onTapGesture {
            print("DayWorkoutCard tapped for day: \(day)")
            onToggleCompletion()
        }
        .sheet(isPresented: $showEditSheet) {
            EditWorkoutDayView(
                dayName: day,
                currentWorkout: workout,
                planId: planId
            )
            .environmentObject(authManager.trainingPlanManager)
        }
    }
}

struct NutritionSection: View {
    let nutrition: [String: Any]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nutrition Plan")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            VStack(spacing: 8) {
                // Calorie target
                if let calorieTarget = nutrition["calorie_target"] as? String {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Daily Calorie Target")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        Text(calorieTarget)
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    .padding()
                    .background(Color(red: 0.1, green: 0.1, blue: 0.15))
                    .cornerRadius(12)
                }
                
                // Foods to eat
                if let foodsToEat = nutrition["foods_to_eat"] as? [String] {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("What to Eat")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        ForEach(foodsToEat, id: \.self) { food in
                            HStack {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 6))
                                    .foregroundColor(.gray)
                                Text(food)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding()
                    .background(Color(red: 0.1, green: 0.1, blue: 0.15))
                    .cornerRadius(12)
                }
                
                // Foods to avoid
                if let foodsToAvoid = nutrition["foods_to_avoid"] as? [String] {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("What to Avoid")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        ForEach(foodsToAvoid, id: \.self) { food in
                            HStack {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 6))
                                    .foregroundColor(.gray)
                                Text(food)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding()
                    .background(Color(red: 0.1, green: 0.1, blue: 0.15))
                    .cornerRadius(12)
                }
            }
        }
    }
}

struct RecommendationsSection: View {
    let recommendations: [String: Any]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recommendations")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            VStack(spacing: 8) {
                // Rest days
                if let restDays = recommendations["rest_days"] as? [String: String] {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Rest Days")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        ForEach(Array(restDays.keys), id: \.self) { day in
                            HStack {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 6))
                                    .foregroundColor(.gray)
                                VStack(alignment: .leading, spacing: 0) {
                                    Text(day.capitalized)
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.gray)
                                    if let description = restDays[day] {
                                        Text(description)
                                            .font(.caption2)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(red: 0.1, green: 0.1, blue: 0.15))
                    .cornerRadius(12)
                }
                
                // Recovery tips
                if let recoveryTips = recommendations["recovery_tips"] as? [String] {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Recovery Tips")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        ForEach(recoveryTips, id: \.self) { tip in
                            HStack {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 6))
                                    .foregroundColor(.gray)
                                Text(tip)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding()
                    .background(Color(red: 0.1, green: 0.1, blue: 0.15))
                    .cornerRadius(12)
                }
                
                // Progress tracking tips
                if let progressTips = recommendations["progress_tracking_tips"] as? [String] {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Progress Tracking")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        ForEach(progressTips, id: \.self) { tip in
                            HStack {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 6))
                                    .foregroundColor(.gray)
                                Text(tip)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding()
                    .background(Color(red: 0.1, green: 0.1, blue: 0.15))
                    .cornerRadius(12)
                }
            }
        }
    }
}

struct RestDayCard: View {
    let day: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(day.capitalized)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                Spacer()
            }
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(red: 0.1, green: 0.1, blue: 0.15))
        .cornerRadius(12)
    }
}

#Preview {
    TrainingPlansView()
        .environmentObject(AuthenticationManager())
} 