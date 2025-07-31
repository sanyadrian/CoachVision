import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) var dismiss
    
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
                        // App Icon and Title
                        VStack(spacing: 16) {
                            Circle()
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: [Color.blue, Color.purple]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Image(systemName: "dumbbell.fill")
                                        .font(.title)
                                        .foregroundColor(.white)
                                )
                            
                            Text("CoachVision")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Your AI-Powered Fitness Companion")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 20)
                        
                        // Mission Statement
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Our Mission")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("We are passionate fitness enthusiasts dedicated to helping people achieve their fitness goals through innovative technology and personalized coaching. Our mission is to make professional fitness guidance accessible to everyone, regardless of their experience level or background.")
                                .font(.body)
                                .foregroundColor(.gray)
                                .lineSpacing(4)
                        }
                        .padding(.horizontal, 20)
                        
                        // Features Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("What We Offer")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            VStack(spacing: 12) {
                                FeatureRow(
                                    icon: "brain.head.profile",
                                    title: "AI-Powered Training Plans",
                                    description: "Personalized workout routines tailored to your goals and experience level"
                                )
                                
                                FeatureRow(
                                    icon: "camera.fill",
                                    title: "Video Analysis",
                                    description: "Get instant feedback on your form and technique using advanced computer vision"
                                )
                                
                                FeatureRow(
                                    icon: "fork.knife",
                                    title: "Smart Nutrition Tracking",
                                    description: "Track your meals with AI-powered food recognition and detailed nutrition analysis"
                                )
                                
                                FeatureRow(
                                    icon: "chart.line.uptrend.xyaxis",
                                    title: "Progress Monitoring",
                                    description: "Track your fitness journey with detailed analytics and progress insights"
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Team Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Our Team")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("We are a team of fitness enthusiasts, developers, and AI researchers who believe that everyone deserves access to high-quality fitness coaching. Our diverse backgrounds in fitness, technology, and health sciences drive us to create innovative solutions that make fitness more accessible and effective.")
                                .font(.body)
                                .foregroundColor(.gray)
                                .lineSpacing(4)
                        }
                        .padding(.horizontal, 20)
                        
                        // Values Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Our Values")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            VStack(spacing: 12) {
                                ValueRow(
                                    icon: "heart.fill",
                                    title: "Passion for Fitness",
                                    description: "We live and breathe fitness, and we want to share that passion with you"
                                )
                                
                                ValueRow(
                                    icon: "person.2.fill",
                                    title: "Personalized Approach",
                                    description: "Every individual is unique, and your fitness journey should reflect that"
                                )
                                
                                ValueRow(
                                    icon: "lightbulb.fill",
                                    title: "Innovation",
                                    description: "We leverage cutting-edge technology to deliver the best possible experience"
                                )
                                
                                ValueRow(
                                    icon: "shield.fill",
                                    title: "Safety First",
                                    description: "Your health and safety are our top priorities in every feature we build"
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // App Version
                        VStack(spacing: 8) {
                            Text("Version 1.0.0")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Text("© 2024 CoachVision. All rights reserved.")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineSpacing(2)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(red: 0.1, green: 0.1, blue: 0.15))
        .cornerRadius(12)
    }
}

struct ValueRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.green)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineSpacing(2)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(red: 0.1, green: 0.1, blue: 0.15))
        .cornerRadius(12)
    }
}

#Preview {
    AboutView()
} 