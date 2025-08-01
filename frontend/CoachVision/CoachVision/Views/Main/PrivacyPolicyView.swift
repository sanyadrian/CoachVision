import SwiftUI

struct PrivacyPolicyView: View {
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
                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.blue)
                            
                            Text("Privacy Policy")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Last updated: December 2024")
                                .font(.body)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 20)
                        
                        // Introduction
                        PolicySection(
                            title: "Introduction",
                            content: "CoachVision ('we', 'our', or 'us') is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application and related services."
                        )
                        
                        // Information We Collect
                        PolicySection(
                            title: "Information We Collect",
                            content: "We collect information you provide directly to us, including:\n\n• Personal Information: Name, email address, age, weight, height\n• Fitness Data: Workout routines, exercise preferences, fitness goals\n• Health Information: BMI calculations, progress tracking data\n• Usage Data: App interactions, feature usage, performance metrics\n• Device Information: Device type, operating system, app version"
                        )
                        
                        // How We Use Your Information
                        PolicySection(
                            title: "How We Use Your Information",
                            content: "We use the collected information to:\n\n• Create personalized training plans and recommendations\n• Provide AI-powered fitness coaching and analysis\n• Track your progress and fitness journey\n• Improve our app features and user experience\n• Send you important updates and notifications\n• Provide customer support and respond to inquiries\n• Ensure app security and prevent fraud"
                        )
                        
                        // AI and Data Processing
                        PolicySection(
                            title: "AI and Data Processing",
                            content: "Our app uses artificial intelligence to:\n\n• Analyze workout videos for form and technique feedback\n• Recognize food items from photos for nutrition tracking\n• Generate personalized training plans based on your profile\n• Provide intelligent recommendations for your fitness journey\n\nAll AI processing is done securely and your data is protected throughout the process."
                        )
                        
                        // Data Sharing
                        PolicySection(
                            title: "Data Sharing and Disclosure",
                            content: "We do not sell, trade, or rent your personal information to third parties. We may share your information only in the following circumstances:\n\n• With your explicit consent\n• To comply with legal obligations\n• To protect our rights and safety\n• With trusted service providers who assist in app operations\n\nAny third-party access is strictly limited and bound by confidentiality agreements."
                        )
                        
                        // Data Security
                        PolicySection(
                            title: "Data Security",
                            content: "We implement industry-standard security measures to protect your information:\n\n• Encryption of data in transit and at rest\n• Secure authentication and access controls\n• Regular security audits and updates\n• Limited access to personal data by authorized personnel only\n• Secure data centers with physical and digital protection"
                        )
                        
                        // Data Retention
                        PolicySection(
                            title: "Data Retention",
                            content: "We retain your personal information for as long as necessary to provide our services and fulfill the purposes outlined in this policy. You may request deletion of your account and associated data at any time through the app settings or by contacting our support team."
                        )
                        
                        // Your Rights
                        PolicySection(
                            title: "Your Rights",
                            content: "You have the following rights regarding your personal information:\n\n• Access: Request a copy of your personal data\n• Correction: Update or correct inaccurate information\n• Deletion: Request deletion of your account and data\n• Portability: Export your data in a machine-readable format\n• Objection: Object to certain processing activities\n• Restriction: Limit how we process your information"
                        )
                        
                        // Camera and Photo Access
                        PolicySection(
                            title: "Camera and Photo Access",
                            content: "Our app requests access to your camera and photo library for:\n\n• Food recognition and nutrition tracking\n• Video analysis for workout form feedback\n• Profile picture upload (if applicable)\n\nWe only access photos and videos when you explicitly choose to use these features. We do not access your entire photo library or camera roll without your permission."
                        )
                        
                        // Children's Privacy
                        PolicySection(
                            title: "Children's Privacy",
                            content: "CoachVision is not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13. If you are a parent or guardian and believe your child has provided us with personal information, please contact us immediately."
                        )
                        
                        // International Users
                        PolicySection(
                            title: "International Users",
                            content: "If you are using CoachVision from outside the United States, please note that your information may be transferred to, stored, and processed in the United States where our servers are located. By using our app, you consent to the transfer of your information to the United States."
                        )
                        
                        // Changes to Policy
                        PolicySection(
                            title: "Changes to This Policy",
                            content: "We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy in the app and updating the 'Last updated' date. Your continued use of the app after any changes constitutes acceptance of the updated policy."
                        )
                        
                        // Contact Information
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Contact Us")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            VStack(spacing: 12) {
                                ContactInfoRow(
                                    icon: "envelope.fill",
                                    title: "Email",
                                    value: "privacy@coachvision.app"
                                )
                                
                                ContactInfoRow(
                                    icon: "globe",
                                    title: "Website",
                                    value: "coachvision.app/privacy"
                                )
                                
                                ContactInfoRow(
                                    icon: "clock.fill",
                                    title: "Response Time",
                                    value: "Within 48 hours"
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Acknowledgment
                        VStack(spacing: 16) {
                            Text("Acknowledgment")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("By using CoachVision, you acknowledge that you have read and understood this Privacy Policy and agree to the collection, use, and disclosure of your information as described herein.")
                                .font(.body)
                                .foregroundColor(.gray)
                                .lineSpacing(4)
                                .multilineTextAlignment(.center)
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

struct PolicySection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(content)
                .font(.body)
                .foregroundColor(.gray)
                .lineSpacing(4)
        }
        .padding(.horizontal, 20)
    }
}

struct ContactInfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
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
        }
        .padding()
        .background(Color(red: 0.1, green: 0.1, blue: 0.15))
        .cornerRadius(12)
    }
}

#Preview {
    PrivacyPolicyView()
} 