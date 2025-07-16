import SwiftUI

struct TrainingPlansView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showingCreatePlan = false
    @State private var plansCount = 0
    
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
                            showingCreatePlan = true
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
                                        PlanCard(
                                            title: plan.title,
                                            subtitle: plan.subtitle,
                                            progress: plan.progress,
                                            isActive: plan.isActive,
                                            date: plan.formattedDate
                                        )
                                    }
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
            CreatePlanView()
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
        }
    }
}

struct PlanCard: View {
    let title: String
    let subtitle: String
    let progress: Double
    let isActive: Bool
    let date: String
    
    var body: some View {
        Button(action: {
            // TODO: Navigate to plan details
        }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Text(date)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    if isActive {
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
                        
                        Text("\(Int(progress * 100))%")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                    
                    ProgressView(value: progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .green))
                }
            }
            .padding()
            .background(Color(red: 0.1, green: 0.1, blue: 0.15))
            .cornerRadius(16)
        }
    }
}

struct CreatePlanView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var planType = "weekly"
    @State private var focusArea = "strength"
    @State private var isCreating = false
    
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
                        // Plan Type
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Plan Type")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Picker("Plan Type", selection: $planType) {
                                Text("Weekly").tag("weekly")
                                Text("Monthly").tag("monthly")
                                Text("Custom").tag("custom")
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                        
                        // Plan Duration
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Plan Duration")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("Your plan will be personalized based on your fitness goal: \(userFitnessGoal.replacingOccurrences(of: "_", with: " ").capitalized)")
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

#Preview {
    TrainingPlansView()
        .environmentObject(AuthenticationManager())
} 