import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    
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
                        
                        // Quick Actions
                        VStack(spacing: 16) {
                            Text("Quick Actions")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 16) {
                                QuickActionCard(
                                    title: "Record Exercise",
                                    subtitle: "Analyze your form",
                                    icon: "video.fill",
                                    color: .blue
                                ) {
                                    // TODO: Navigate to video recording
                                }
                                
                                QuickActionCard(
                                    title: "View Plans",
                                    subtitle: "Your training plans",
                                    icon: "dumbbell.fill",
                                    color: .green
                                ) {
                                    // TODO: Navigate to plans
                                }
                                
                                QuickActionCard(
                                    title: "Progress",
                                    subtitle: "Track your goals",
                                    icon: "chart.line.uptrend.xyaxis",
                                    color: .orange
                                ) {
                                    // TODO: Navigate to progress
                                }
                                
                                QuickActionCard(
                                    title: "Profile",
                                    subtitle: "Update your info",
                                    icon: "person.fill",
                                    color: .purple
                                ) {
                                    // TODO: Navigate to profile
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Logout button
                        Button("Logout") {
                            authManager.logout()
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(25)
                        .padding(.horizontal, 20)
                        
                        Spacer(minLength: 100)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct QuickActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(Color(red: 0.1, green: 0.1, blue: 0.15))
            .cornerRadius(16)
        }
    }
}

#Preview {
    DashboardView()
        .environmentObject(AuthenticationManager())
        .preferredColorScheme(.dark)
} 