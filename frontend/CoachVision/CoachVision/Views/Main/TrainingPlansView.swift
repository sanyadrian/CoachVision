import SwiftUI

struct TrainingPlansView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showingCreatePlan = false
    
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
                            Text("Your Plans")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            // Placeholder for plans
                            VStack(spacing: 12) {
                                ForEach(0..<3) { index in
                                    PlanCard(
                                        title: "Weekly Plan \(index + 1)",
                                        subtitle: "Strength Training",
                                        progress: Double(index + 1) / 3.0,
                                        isActive: index == 0
                                    )
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
    }
}

struct PlanCard: View {
    let title: String
    let subtitle: String
    let progress: Double
    let isActive: Bool
    
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
    @State private var planType = "weekly"
    @State private var focusArea = "strength"
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Text("Create New Plan")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
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
                        
                        // Focus Area
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Focus Area")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Picker("Focus Area", selection: $focusArea) {
                                Text("Strength").tag("strength")
                                Text("Cardio").tag("cardio")
                                Text("Flexibility").tag("flexibility")
                                Text("Mixed").tag("mixed")
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    // Create Button
                    Button("Create Plan") {
                        // TODO: Create plan logic
                        dismiss()
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.white)
                    .cornerRadius(25)
                    .padding(.horizontal, 20)
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