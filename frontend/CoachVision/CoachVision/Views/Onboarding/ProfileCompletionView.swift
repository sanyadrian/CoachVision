import SwiftUI

struct ProfileCompletionView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var age = ""
    @State private var weight = ""
    @State private var height = ""
    @State private var selectedFitnessGoal = FitnessGoal.generalFitness
    @State private var selectedExperienceLevel = ExperienceLevel.beginner
    @State private var currentStep = 0
    
    private let totalSteps = 5
    
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
                
                VStack(spacing: 0) {
                    // Progress bar
                    ProgressView(value: Double(currentStep + 1), total: Double(totalSteps))
                        .progressViewStyle(LinearProgressViewStyle(tint: .white))
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    
                    // Step indicator
                    Text("Step \(currentStep + 1) of \(totalSteps)")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.top, 8)
                    
                    // Content
                    TabView(selection: $currentStep) {
                        // Step 1: Age
                        VStack(spacing: 24) {
                            Spacer()
                            
                            VStack(spacing: 16) {
                                Image(systemName: "person.circle")
                                    .font(.system(size: 60))
                                    .foregroundColor(.white)
                                
                                Text("How old are you?")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Text("This helps us personalize your fitness plan")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                            }
                            
                            TextField("Enter your age", text: $age)
                                .textFieldStyle(CustomTextFieldStyle())
                                .keyboardType(.numberPad)
                                .frame(maxWidth: 200)
                            
                            Spacer()
                        }
                        .tag(0)
                        
                        // Step 2: Weight
                        VStack(spacing: 24) {
                            Spacer()
                            
                            VStack(spacing: 16) {
                                Image(systemName: "scalemass")
                                    .font(.system(size: 60))
                                    .foregroundColor(.white)
                                
                                Text("What's your weight?")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Text("We'll use this to calculate your calorie needs")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                            }
                            
                            HStack {
                                TextField("Weight", text: $weight)
                                    .textFieldStyle(CustomTextFieldStyle())
                                    .keyboardType(.decimalPad)
                                
                                Text("kg")
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: 200)
                            
                            Spacer()
                        }
                        .tag(1)
                        
                        // Step 3: Height
                        VStack(spacing: 24) {
                            Spacer()
                            
                            VStack(spacing: 16) {
                                Image(systemName: "ruler")
                                    .font(.system(size: 60))
                                    .foregroundColor(.white)
                                
                                Text("What's your height?")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Text("This helps us calculate your BMI and ideal weight")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                            }
                            
                            HStack {
                                TextField("Height", text: $height)
                                    .textFieldStyle(CustomTextFieldStyle())
                                    .keyboardType(.decimalPad)
                                
                                Text("cm")
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: 200)
                            
                            Spacer()
                        }
                        .tag(2)
                        
                        // Step 4: Fitness Goal
                        VStack(spacing: 24) {
                            Spacer()
                            
                            VStack(spacing: 16) {
                                Image(systemName: "target")
                                    .font(.system(size: 60))
                                    .foregroundColor(.white)
                                
                                Text("What's your fitness goal?")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Text("Choose your primary objective")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                            }
                            
                            VStack(spacing: 12) {
                                ForEach(FitnessGoal.allCases, id: \.self) { goal in
                                    Button(action: {
                                        selectedFitnessGoal = goal
                                    }) {
                                        HStack {
                                            Text(goal.displayName)
                                                .foregroundColor(.white)
                                                .fontWeight(.medium)
                                            
                                            Spacer()
                                            
                                            if selectedFitnessGoal == goal {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(.green)
                                            }
                                        }
                                        .padding()
                                        .background(selectedFitnessGoal == goal ? Color(red: 0.2, green: 0.2, blue: 0.3) : Color(red: 0.15, green: 0.15, blue: 0.2))
                                        .cornerRadius(12)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            Spacer()
                        }
                        .tag(3)
                        
                        // Step 5: Experience Level
                        VStack(spacing: 24) {
                            Spacer()
                            
                            VStack(spacing: 16) {
                                Image(systemName: "star.circle")
                                    .font(.system(size: 60))
                                    .foregroundColor(.white)
                                
                                Text("What's your experience level?")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Text("This helps us create the right workout intensity")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                            }
                            
                            VStack(spacing: 12) {
                                ForEach(ExperienceLevel.allCases, id: \.self) { level in
                                    Button(action: {
                                        selectedExperienceLevel = level
                                    }) {
                                        HStack {
                                            Text(level.displayName)
                                                .foregroundColor(.white)
                                                .fontWeight(.medium)
                                            
                                            Spacer()
                                            
                                            if selectedExperienceLevel == level {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(.green)
                                            }
                                        }
                                        .padding()
                                        .background(selectedExperienceLevel == level ? Color(red: 0.2, green: 0.2, blue: 0.3) : Color(red: 0.15, green: 0.15, blue: 0.2))
                                        .cornerRadius(12)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            Spacer()
                        }
                        .tag(4)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    
                    // Navigation buttons
                    HStack {
                        if currentStep > 0 {
                            Button("Back") {
                                withAnimation {
                                    currentStep -= 1
                                }
                            }
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(25)
                        }
                        
                        Spacer()
                        
                        if currentStep < totalSteps - 1 {
                            Button("Next") {
                                withAnimation {
                                    currentStep += 1
                                }
                            }
                            .foregroundColor(.black)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(25)
                            .disabled(!canProceed)
                            .opacity(canProceed ? 1.0 : 0.6)
                        } else {
                            Button("Complete Profile") {
                                Task {
                                    await completeProfile()
                                }
                            }
                            .foregroundColor(.black)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(25)
                            .disabled(!canProceed || authManager.isLoading)
                            .opacity((canProceed && !authManager.isLoading) ? 1.0 : 0.6)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private var canProceed: Bool {
        switch currentStep {
        case 0: return !age.isEmpty && Int(age) != nil
        case 1: return !weight.isEmpty && Double(weight) != nil
        case 2: return !height.isEmpty && Double(height) != nil
        case 3: return true // Fitness goal is always selected
        case 4: return true // Experience level is always selected
        default: return false
        }
    }
    
    private func completeProfile() async {
        guard let ageInt = Int(age),
              let weightDouble = Double(weight),
              let heightDouble = Double(height) else { return }
        
        print("Completing profile with data:")
        print("- Age: \(ageInt)")
        print("- Weight: \(weightDouble)")
        print("- Height: \(heightDouble)")
        print("- Fitness Goal: \(selectedFitnessGoal.rawValue)")
        print("- Experience Level: \(selectedExperienceLevel.rawValue)")
        
        await authManager.completeProfile(
            age: ageInt,
            weight: weightDouble,
            height: heightDouble,
            fitnessGoal: selectedFitnessGoal.rawValue,
            experienceLevel: selectedExperienceLevel.rawValue
        )
        
        print("Profile completion finished")
        print("Current user: \(authManager.currentUser?.name ?? "nil")")
        print("Is profile complete: \(authManager.currentUser?.isProfileComplete ?? false)")
        
        // Add a small delay to ensure the UI updates
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
    }
}

#Preview {
    ProfileCompletionView()
        .environmentObject(AuthenticationManager())
        .preferredColorScheme(.dark)
} 