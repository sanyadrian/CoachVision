import SwiftUI

struct EmailSupportView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showingSupportForm = false
    
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
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.blue)
                            
                            Text("Email Support")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Get in touch with our support team")
                                .font(.body)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 20)
                        
                        // Contact Information
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Contact Information")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            VStack(spacing: 12) {
                                ContactCard(
                                    icon: "envelope.fill",
                                    title: "Support Email",
                                    value: "support@coachvision.app",
                                    action: {
                                        if let url = URL(string: "mailto:support@coachvision.app") {
                                            UIApplication.shared.open(url)
                                        }
                                    }
                                )
                                
                                ContactCard(
                                    icon: "clock.fill",
                                    title: "Response Time",
                                    value: "Within 24 hours",
                                    action: nil
                                )
                                
                                ContactCard(
                                    icon: "globe",
                                    title: "Website",
                                    value: "coachvision.app",
                                    action: {
                                        if let url = URL(string: "https://coachvision.app") {
                                            UIApplication.shared.open(url)
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Support Form Option
                        VStack(spacing: 16) {
                            Text("Submit Support Request")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Use our in-app support form for faster response times and better tracking of your request.")
                                .font(.body)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                            
                            Button(action: {
                                showingSupportForm = true
                            }) {
                                Text("Open Support Form")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color.white)
                                    .cornerRadius(25)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // What to Include
                        VStack(alignment: .leading, spacing: 16) {
                            Text("What to Include in Your Email")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            VStack(spacing: 12) {
                                InfoCard(
                                    icon: "person.fill",
                                    title: "Your Information",
                                    description: "Include your name, email address, and user ID if available."
                                )
                                
                                InfoCard(
                                    icon: "questionmark.circle.fill",
                                    title: "Detailed Description",
                                    description: "Clearly describe the issue, what you were doing when it occurred, and any error messages you saw."
                                )
                                
                                InfoCard(
                                    icon: "iphone",
                                    title: "Device Information",
                                    description: "Mention your device model, iOS version, and app version for technical issues."
                                )
                                
                                InfoCard(
                                    icon: "camera.fill",
                                    title: "Screenshots",
                                    description: "Attach screenshots or screen recordings if relevant to help us understand the issue better."
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Common Issues
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Common Issues We Can Help With")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            VStack(spacing: 8) {
                                CommonIssueRow(issue: "App crashes or freezes")
                                CommonIssueRow(issue: "Login or authentication problems")
                                CommonIssueRow(issue: "Training plan generation issues")
                                CommonIssueRow(issue: "Food recognition not working")
                                CommonIssueRow(issue: "Video analysis problems")
                                CommonIssueRow(issue: "Data sync issues")
                                CommonIssueRow(issue: "Feature requests")
                                CommonIssueRow(issue: "Account management")
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Alternative Support
                        VStack(spacing: 16) {
                            Text("Other Support Options")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            VStack(spacing: 12) {
                                AlternativeCard(
                                    icon: "questionmark.circle.fill",
                                    title: "FAQ",
                                    description: "Find quick answers to common questions",
                                    action: {
                                        // This would open FAQ view
                                        dismiss()
                                    }
                                )
                                
                                AlternativeCard(
                                    icon: "book.fill",
                                    title: "User Guide",
                                    description: "Learn how to use all features effectively",
                                    action: {
                                        // This would open User Guide view
                                        dismiss()
                                    }
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
            .sheet(isPresented: $showingSupportForm) {
                HelpSupportView()
            }
        }
    }
}

struct ContactCard: View {
    let icon: String
    let title: String
    let value: String
    let action: (() -> Void)?
    
    var body: some View {
        Button(action: {
            action?()
        }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text(value)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                if action != nil {
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(Color(red: 0.1, green: 0.1, blue: 0.15))
            .cornerRadius(12)
        }
        .disabled(action == nil)
    }
}

struct InfoCard: View {
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

struct CommonIssueRow: View {
    let issue: String
    
    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .font(.caption)
                .foregroundColor(.green)
            
            Text(issue)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Spacer()
        }
    }
}

struct AlternativeCard: View {
    let icon: String
    let title: String
    let description: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.purple)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color(red: 0.1, green: 0.1, blue: 0.15))
            .cornerRadius(12)
        }
    }
}

#Preview {
    EmailSupportView()
        .environmentObject(AuthenticationManager())
} 