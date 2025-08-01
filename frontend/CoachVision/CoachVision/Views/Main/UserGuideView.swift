import SwiftUI

struct UserGuideView: View {
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
                    VStack(spacing: 32) {
                        // Header
                        VStack(spacing: 16) {
                            Image(systemName: "book.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.blue)
                            
                            Text("User Guide")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Learn how to use CoachVision effectively")
                                .font(.body)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 20)
                        
                        // Getting Started
                        GuideSection(
                            title: "Getting Started",
                            icon: "play.circle.fill",
                            color: .green
                        ) {
                            GuideStep(
                                number: "1",
                                title: "Create Your Profile",
                                description: "Complete your profile with accurate information including age, weight, height, fitness goals, and experience level. This helps CoachVision create personalized recommendations."
                            )
                            
                            GuideStep(
                                number: "2",
                                title: "Generate Your First Plan",
                                description: "Go to Training Plans and tap 'Generate New Plan'. CoachVision will create a personalized workout routine based on your profile information."
                            )
                            
                            GuideStep(
                                number: "3",
                                title: "Start Tracking",
                                description: "Use the dashboard to track your daily progress, log meals, and monitor your fitness journey."
                            )
                        }
                        
                        // Dashboard
                        GuideSection(
                            title: "Dashboard",
                            icon: "chart.bar.fill",
                            color: .blue
                        ) {
                            GuideStep(
                                number: "1",
                                title: "Daily Overview",
                                description: "View your current week's training plan, daily calorie intake, and recent video analyses at a glance."
                            )
                            
                            GuideStep(
                                number: "2",
                                title: "Nutrition Tracking",
                                description: "Tap on your daily calorie total to see detailed meal breakdown. Add meals manually or use the camera to scan food."
                            )
                            
                            GuideStep(
                                number: "3",
                                title: "Progress Monitoring",
                                description: "Track your completed workouts with green checkmarks and monitor your fitness stats over time."
                            )
                        }
                        
                        // Training Plans
                        GuideSection(
                            title: "Training Plans",
                            icon: "dumbbell.fill",
                            color: .orange
                        ) {
                            GuideStep(
                                number: "1",
                                title: "View Your Plan",
                                description: "See your personalized workout routine for the current week. Each day shows the workout type and exercises."
                            )
                            
                            GuideStep(
                                number: "2",
                                title: "Mark as Complete",
                                description: "Tap the checkmark next to completed workouts to track your progress and maintain your streak."
                            )
                            
                            GuideStep(
                                number: "3",
                                title: "Edit Workouts",
                                description: "Tap the pencil icon to modify exercises, add new ones, or change workout types to match your preferences."
                            )
                            
                            GuideStep(
                                number: "4",
                                title: "Generate New Plans",
                                description: "Create fresh training plans whenever you want to change your routine or start a new fitness phase."
                            )
                        }
                        
                        // Nutrition Tracking
                        GuideSection(
                            title: "Nutrition Tracking",
                            icon: "fork.knife",
                            color: .purple
                        ) {
                            GuideStep(
                                number: "1",
                                title: "Manual Entry",
                                description: "Add meals manually by entering food name, calories, protein, carbs, and fats. Perfect for home-cooked meals or when you know the nutrition facts."
                            )
                            
                            GuideStep(
                                number: "2",
                                title: "Camera Scanning",
                                description: "Take a photo of your food to automatically identify it and get nutrition information. Works best with clear, well-lit photos."
                            )
                            
                            GuideStep(
                                number: "3",
                                title: "Live Camera Scan",
                                description: "Use real-time camera scanning for instant food recognition. Point your camera at food items for immediate analysis."
                            )
                            
                            GuideStep(
                                number: "4",
                                title: "Review and Edit",
                                description: "Always review AI-generated nutrition data and edit if needed for accuracy. You can modify calories, macros, and food names."
                            )
                        }
                        
                        // Video Analysis
                        GuideSection(
                            title: "Video Analysis",
                            icon: "video.fill",
                            color: .red
                        ) {
                            GuideStep(
                                number: "1",
                                title: "Record Your Workout",
                                description: "Record yourself performing exercises to get feedback on your form and technique."
                            )
                            
                            GuideStep(
                                number: "2",
                                title: "Upload Video",
                                description: "Upload your workout video through the Video Analysis tab. Ensure good lighting and full body visibility."
                            )
                            
                            GuideStep(
                                number: "3",
                                title: "Get Feedback",
                                description: "Receive detailed analysis of your form, including posture, movement patterns, and improvement suggestions."
                            )
                            
                            GuideStep(
                                number: "4",
                                title: "Track Progress",
                                description: "View your analysis history to track improvements in your form over time."
                            )
                        }
                        
                        // Profile Management
                        GuideSection(
                            title: "Profile Management",
                            icon: "person.circle.fill",
                            color: .cyan
                        ) {
                            GuideStep(
                                number: "1",
                                title: "Update Information",
                                description: "Keep your profile current by updating weight, fitness goals, and experience level as your journey progresses."
                            )
                            
                            GuideStep(
                                number: "2",
                                title: "View Stats",
                                description: "Check your fitness statistics including BMI, current goals, and experience level in the profile section."
                            )
                            
                            GuideStep(
                                number: "3",
                                title: "Get Support",
                                description: "Access help, FAQ, and support options through the profile settings to get assistance when needed."
                            )
                        }
                        
                        // Tips Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Pro Tips")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            VStack(spacing: 12) {
                                TipCard(
                                    icon: "lightbulb.fill",
                                    title: "Consistency is Key",
                                    description: "Use the app daily to track your progress. Even small consistent efforts lead to big results over time."
                                )
                                
                                TipCard(
                                    icon: "target",
                                    title: "Set Realistic Goals",
                                    description: "Start with achievable fitness goals and gradually increase intensity as you progress."
                                )
                                
                                TipCard(
                                    icon: "camera.fill",
                                    title: "Use Video Analysis Regularly",
                                    description: "Regular form checks help prevent injuries and ensure you're getting the most from your workouts."
                                )
                                
                                TipCard(
                                    icon: "chart.line.uptrend.xyaxis",
                                    title: "Monitor Trends",
                                    description: "Pay attention to your nutrition and workout patterns to identify what works best for your body."
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer(minLength: 100)
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

struct GuideSection<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    let content: Content
    
    init(title: String, icon: String, color: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.color = color
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 12) {
                content
            }
        }
        .padding(.horizontal, 20)
    }
}

struct GuideStep: View {
    let number: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Color.blue)
                .clipShape(Circle())
            
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

struct TipCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.yellow)
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
    UserGuideView()
} 