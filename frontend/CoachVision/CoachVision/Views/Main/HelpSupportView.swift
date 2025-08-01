import SwiftUI

struct HelpSupportView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var subject = ""
    @State private var message = ""
    @State private var selectedCategory = SupportCategory.general
    @State private var isSubmitting = false
    @State private var showSuccessAlert = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var showingUserGuide = false
    @State private var showingFAQ = false
    @State private var showingEmailSupport = false
    
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
                        VStack(spacing: 16) {
                            Image(systemName: "questionmark.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.blue)
                            
                            Text("Help & Support")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("We're here to help! Send us your questions, feedback, or report any issues you're experiencing.")
                                .font(.body)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                        }
                        .padding(.top, 20)
                        
                        // Contact Form
                        VStack(spacing: 20) {
                            // Category Selection
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Category")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Picker("Category", selection: $selectedCategory) {
                                    ForEach(SupportCategory.allCases, id: \.self) { category in
                                        Text(category.displayName).tag(category)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color(red: 0.1, green: 0.1, blue: 0.15))
                                .cornerRadius(12)
                                .foregroundColor(.white)
                            }
                            
                            // Subject
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Subject")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                TextField("Brief description of your issue", text: $subject)
                                    .textFieldStyle(CustomTextFieldStyle())
                            }
                            
                            // Message
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Message")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                TextEditor(text: $message)
                                    .frame(minHeight: 120)
                                    .padding(12)
                                    .background(Color(red: 0.1, green: 0.1, blue: 0.15))
                                    .cornerRadius(12)
                                    .foregroundColor(.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                            }
                            
                            // User Info Display
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Your Information")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Name: \(authManager.currentUser?.name ?? "Not available")")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    
                                    Text("Email: \(authManager.currentUser?.email ?? "Not available")")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .background(Color(red: 0.1, green: 0.1, blue: 0.15))
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Submit Button
                        Button(action: {
                            Task {
                                await submitSupportRequest()
                            }
                        }) {
                            HStack {
                                if isSubmitting {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                        .scaleEffect(0.8)
                                }
                                
                                Text(isSubmitting ? "Sending..." : "Send Request")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(isFormValid ? Color.white : Color.gray)
                            .cornerRadius(25)
                        }
                        .disabled(!isFormValid || isSubmitting)
                        .padding(.horizontal, 20)
                        
                        // Quick Help Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Quick Help")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            VStack(spacing: 12) {
                                QuickHelpRow(
                                    icon: "book.fill",
                                    title: "User Guide",
                                    description: "Learn how to use CoachVision effectively",
                                    action: { showingUserGuide = true }
                                )
                                
                                QuickHelpRow(
                                    icon: "questionmark.circle.fill",
                                    title: "FAQ",
                                    description: "Find answers to common questions",
                                    action: { showingFAQ = true }
                                )
                                
                                QuickHelpRow(
                                    icon: "envelope.fill",
                                    title: "Email Support",
                                    description: "Get direct support via email",
                                    action: { showingEmailSupport = true }
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
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .alert("Success!", isPresented: $showSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your support request has been sent successfully. We'll get back to you soon!")
            }
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showingUserGuide) {
                UserGuideView()
            }
            .sheet(isPresented: $showingFAQ) {
                FAQView()
            }
            .sheet(isPresented: $showingEmailSupport) {
                EmailSupportView()
            }
        }
    }
    
    private var isFormValid: Bool {
        !subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func submitSupportRequest() async {
        isSubmitting = true
        
        do {
            let request = SupportRequest(
                category: selectedCategory.rawValue,
                subject: subject.trimmingCharacters(in: .whitespacesAndNewlines),
                message: message.trimmingCharacters(in: .whitespacesAndNewlines),
                userName: authManager.currentUser?.name ?? "Unknown",
                userEmail: authManager.currentUser?.email ?? "Unknown"
            )
            
            let success = await authManager.submitSupportRequest(request)
            
            if success {
                showSuccessAlert = true
            } else {
                errorMessage = "Failed to send support request. Please try again."
                showErrorAlert = true
            }
        } catch {
            errorMessage = "An error occurred: \(error.localizedDescription)"
            showErrorAlert = true
        }
        
        isSubmitting = false
    }
}

enum SupportCategory: String, CaseIterable {
    case general = "general"
    case technical = "technical"
    case billing = "billing"
    case feature = "feature"
    case bug = "bug"
    case feedback = "feedback"
    
    var displayName: String {
        switch self {
        case .general:
            return "General Inquiry"
        case .technical:
            return "Technical Issue"
        case .billing:
            return "Billing & Payment"
        case .feature:
            return "Feature Request"
        case .bug:
            return "Bug Report"
        case .feedback:
            return "Feedback"
        }
    }
}

struct SupportRequest: Codable {
    let category: String
    let subject: String
    let message: String
    let userName: String
    let userEmail: String
}

struct QuickHelpRow: View {
    let icon: String
    let title: String
    let description: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
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
    HelpSupportView()
        .environmentObject(AuthenticationManager())
} 