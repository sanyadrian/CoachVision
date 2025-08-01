import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showingEditProfile = false
    @State private var showingAbout = false
    @State private var showingHelpSupport = false
    
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
                            Text("Profile")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Manage your account")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        // Profile Card
                        VStack(spacing: 20) {
                            // Avatar and Name
                            VStack(spacing: 16) {
                                Circle()
                                    .fill(Color(red: 0.2, green: 0.2, blue: 0.3))
                                    .frame(width: 80, height: 80)
                                    .overlay(
                                        Text(String(authManager.currentUser?.name.prefix(1) ?? "U").uppercased())
                                            .font(.title)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                    )
                                
                                VStack(spacing: 4) {
                                    Text(authManager.currentUser?.name ?? "User")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                    
                                    Text(authManager.currentUser?.email ?? "user@example.com")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            // Edit Profile Button
                            Button(action: {
                                showingEditProfile = true
                            }) {
                                Text("Edit Profile")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color.white)
                                    .cornerRadius(25)
                            }
                        }
                        .padding()
                        .background(Color(red: 0.1, green: 0.1, blue: 0.15))
                        .cornerRadius(20)
                        .padding(.horizontal, 20)
                        
                        // Fitness Stats
                        VStack(spacing: 16) {
                            Text("Fitness Stats")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 16) {
                                StatCard(
                                    title: "Age",
                                    value: "\(authManager.currentUser?.age ?? 0)",
                                    icon: "person.circle"
                                )
                                
                                StatCard(
                                    title: "Weight",
                                    value: "\(Int(authManager.currentUser?.weight ?? 0)) kg",
                                    icon: "scalemass"
                                )
                                
                                StatCard(
                                    title: "Height",
                                    value: "\(Int(authManager.currentUser?.height ?? 0)) cm",
                                    icon: "ruler"
                                )
                                
                                StatCard(
                                    title: "BMI",
                                    value: String(format: "%.1f", calculateBMI()),
                                    icon: "chart.bar"
                                )
                                
                                StatCard(
                                    title: "Goal",
                                    value: formatFitnessGoal(),
                                    icon: "target"
                                )
                                
                                StatCard(
                                    title: "Level",
                                    value: formatExperienceLevel(),
                                    icon: "star"
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Settings
                        VStack(spacing: 16) {
                            Text("Settings")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            VStack(spacing: 0) {
                                SettingsRow(
                                    title: "Notifications",
                                    icon: "bell",
                                    action: { /* TODO */ }
                                )
                                
                                Divider()
                                    .background(Color.gray.opacity(0.3))
                                
                                SettingsRow(
                                    title: "Privacy",
                                    icon: "lock",
                                    action: { /* TODO */ }
                                )
                                
                                Divider()
                                    .background(Color.gray.opacity(0.3))
                                
                                SettingsRow(
                                    title: "Help & Support",
                                    icon: "questionmark.circle",
                                    action: { showingHelpSupport = true }
                                )
                                
                                Divider()
                                    .background(Color.gray.opacity(0.3))
                                
                                SettingsRow(
                                    title: "About",
                                    icon: "info.circle",
                                    action: { showingAbout = true }
                                )
                            }
                            .background(Color(red: 0.1, green: 0.1, blue: 0.15))
                            .cornerRadius(16)
                        }
                        .padding(.horizontal, 20)
                        
                        // Logout Button
                        Button(action: {
                            authManager.logout()
                        }) {
                            Text("Logout")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.red)
                                .cornerRadius(25)
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer(minLength: 100)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingEditProfile) {
            EditProfileView()
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
        .sheet(isPresented: $showingHelpSupport) {
            HelpSupportView()
        }
    }
    
    private func calculateBMI() -> Double {
        guard let weight = authManager.currentUser?.weight,
              let height = authManager.currentUser?.height,
              height > 0 else { return 0 }
        
        let heightInMeters = height / 100
        return weight / (heightInMeters * heightInMeters)
    }
    
    private func formatFitnessGoal() -> String {
        guard let goal = authManager.currentUser?.fitnessGoal else { return "Not set" }
        return goal.replacingOccurrences(of: "_", with: " ").capitalized
    }
    
    private func formatExperienceLevel() -> String {
        guard let level = authManager.currentUser?.experienceLevel else { return "Not set" }
        return level.capitalized
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 80)
        .background(Color(red: 0.1, green: 0.1, blue: 0.15))
        .cornerRadius(16)
    }
}

struct SettingsRow: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(width: 24)
                
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
        }
    }
}

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var name = ""
    @State private var age = ""
    @State private var weight = ""
    @State private var height = ""
    @State private var selectedFitnessGoal = FitnessGoal.generalFitness
    @State private var selectedExperienceLevel = ExperienceLevel.beginner
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        Text("Edit Profile")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        VStack(spacing: 16) {
                            // Name
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Name")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                TextField("Enter your name", text: $name)
                                    .textFieldStyle(CustomTextFieldStyle())
                            }
                            
                            // Age
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Age")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                TextField("Enter your age", text: $age)
                                    .textFieldStyle(CustomTextFieldStyle())
                                    .keyboardType(.numberPad)
                            }
                            
                            // Weight
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Weight (kg)")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                TextField("Enter your weight", text: $weight)
                                    .textFieldStyle(CustomTextFieldStyle())
                                    .keyboardType(.decimalPad)
                            }
                            
                            // Height
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Height (cm)")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                TextField("Enter your height", text: $height)
                                    .textFieldStyle(CustomTextFieldStyle())
                                    .keyboardType(.decimalPad)
                            }
                            
                            // Fitness Goal
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Fitness Goal")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Picker("Fitness Goal", selection: $selectedFitnessGoal) {
                                    ForEach(FitnessGoal.allCases, id: \.self) { goal in
                                        Text(goal.displayName).tag(goal)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color(red: 0.1, green: 0.1, blue: 0.15))
                                .cornerRadius(12)
                                .foregroundColor(.white)
                            }
                            
                            // Experience Level
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Experience Level")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Picker("Experience Level", selection: $selectedExperienceLevel) {
                                    ForEach(ExperienceLevel.allCases, id: \.self) { level in
                                        Text(level.displayName).tag(level)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color(red: 0.1, green: 0.1, blue: 0.15))
                                .cornerRadius(12)
                                .foregroundColor(.white)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer()
                        
                        // Save Button
                        Button("Save Changes") {
                            Task {
                                await updateProfile()
                                dismiss()
                            }
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.white)
                        .cornerRadius(25)
                        .padding(.horizontal, 20)
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
            .onAppear {
                // Load current user data
                name = authManager.currentUser?.name ?? ""
                age = String(authManager.currentUser?.age ?? 0)
                weight = String(authManager.currentUser?.weight ?? 0)
                height = String(authManager.currentUser?.height ?? 0)
                
                // Load current fitness goal and experience level
                if let goal = authManager.currentUser?.fitnessGoal,
                   let fitnessGoal = FitnessGoal(rawValue: goal) {
                    selectedFitnessGoal = fitnessGoal
                }
                
                if let level = authManager.currentUser?.experienceLevel,
                   let experienceLevel = ExperienceLevel(rawValue: level) {
                    selectedExperienceLevel = experienceLevel
                }
            }
        }
    }
    
    private func updateProfile() async {
        guard let ageInt = Int(age),
              let weightDouble = Double(weight),
              let heightDouble = Double(height) else { return }
        
        await authManager.updateProfile(
            name: name,
            age: ageInt,
            weight: weightDouble,
            height: heightDouble,
            fitnessGoal: selectedFitnessGoal.rawValue,
            experienceLevel: selectedExperienceLevel.rawValue
        )
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthenticationManager())
} 