import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient like YouTube Music
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
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                        
                        Text("CoachVision")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("AI-Powered Fitness Coaching")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 60)
                    .padding(.bottom, 40)
                    
                    // Debug button to clear cache (remove this later)
                    Button("Clear Cache (Debug)") {
                        UserDefaults.standard.removeObject(forKey: "authToken")
                        authManager.authToken = nil
                        authManager.isAuthenticated = false
                        authManager.currentUser = nil
                    }
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.bottom, 20)
                    
                    // Tab selector
                    HStack(spacing: 0) {
                        TabButton(
                            title: "Sign In",
                            isSelected: selectedTab == 0
                        ) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                selectedTab = 0
                            }
                        }
                        
                        TabButton(
                            title: "Sign Up",
                            isSelected: selectedTab == 1
                        ) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                selectedTab = 1
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Tab content
                    TabView(selection: $selectedTab) {
                        LoginView()
                            .tag(0)
                        
                        RegisterView()
                            .tag(1)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .animation(.easeInOut(duration: 0.3), value: selectedTab)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? .white : .gray)
                
                Rectangle()
                    .fill(isSelected ? Color.white : Color.clear)
                    .frame(height: 2)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(AuthenticationManager())
} 