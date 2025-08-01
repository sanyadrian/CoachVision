import SwiftUI

struct FAQView: View {
    @Environment(\.dismiss) var dismiss
    @State private var expandedQuestions: Set<String> = []
    
    let faqs = [
        FAQItem(
            question: "How does CoachVision create personalized training plans?",
            answer: "CoachVision uses advanced AI technology to analyze your fitness goals, experience level, age, weight, and height to create customized workout routines. The AI considers your specific objectives (weight loss, muscle gain, general fitness, etc.) and generates plans that are tailored to your individual needs and capabilities."
        ),
        FAQItem(
            question: "Can I edit my training plan after it's created?",
            answer: "Yes! You can edit any day in your training plan. Simply go to the Training Plans tab, select your active plan, and tap the edit button (pencil icon) next to any workout day. You can modify exercises, add new ones, or change the workout type to better suit your preferences."
        ),
        FAQItem(
            question: "How accurate is the food recognition feature?",
            answer: "Our AI-powered food recognition uses advanced computer vision to identify foods from photos. While it's quite accurate for common foods, complex dishes or unusual presentations might need manual adjustment. You can always manually edit the nutrition information after the AI analysis to ensure accuracy."
        ),
        FAQItem(
            question: "What should I do if the video analysis isn't working?",
            answer: "Make sure you're in a well-lit environment and your full body is visible in the camera. Stand about 6-8 feet from the camera and ensure you have a stable internet connection. If issues persist, try restarting the app or check that you have the latest version installed."
        ),
        FAQItem(
            question: "How often should I update my profile information?",
            answer: "Update your profile whenever there are significant changes in your fitness journey. This includes changes in weight, fitness goals, or experience level. Regular updates help CoachVision provide more accurate and relevant recommendations for your training and nutrition."
        ),
        FAQItem(
            question: "Can I use CoachVision without an internet connection?",
            answer: "Some features like viewing your saved training plans and meal history work offline. However, features that require AI processing (creating new training plans, food recognition, video analysis) need an internet connection to function properly."
        ),
        FAQItem(
            question: "How do I track my progress over time?",
            answer: "CoachVision automatically tracks your progress through the dashboard. You can see your daily calorie intake, completed workouts, and overall fitness stats. The app maintains a history of your meals and workout completion, helping you monitor your fitness journey."
        ),
        FAQItem(
            question: "What if I miss a workout day?",
            answer: "No worries! You can mark workouts as completed on any day, even if you do them later. The app is flexible and adapts to your schedule. You can also edit your training plan to reschedule workouts or adjust the intensity based on your availability."
        ),
        FAQItem(
            question: "How secure is my personal data?",
            answer: "Your privacy and data security are our top priorities. All personal information is encrypted and stored securely. We never share your data with third parties without your explicit consent. Your fitness and nutrition data is only used to provide you with personalized recommendations."
        ),
        FAQItem(
            question: "Can I export my data or training plans?",
            answer: "Currently, your data is stored securely within the app. We're working on features to allow data export and sharing capabilities. For now, you can take screenshots of your training plans and progress for your records."
        ),
        FAQItem(
            question: "What should I do if I encounter a bug or technical issue?",
            answer: "If you experience any technical issues, please use the Help & Support feature in your profile. Select 'Bug Report' as the category and provide detailed information about the issue, including what you were doing when it occurred. Our team will investigate and get back to you promptly."
        ),
        FAQItem(
            question: "How do I get the most out of CoachVision?",
            answer: "To maximize your experience: 1) Keep your profile updated with current information, 2) Use the food recognition feature regularly for accurate nutrition tracking, 3) Complete the video analysis sessions to improve your form, 4) Mark your workouts as completed to track progress, 5) Don't hesitate to edit training plans to match your preferences and schedule."
        )
    ]
    
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
                            
                            Text("Frequently Asked Questions")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Find answers to common questions about CoachVision")
                                .font(.body)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 20)
                        
                        // FAQ List
                        VStack(spacing: 16) {
                            ForEach(faqs, id: \.question) { faq in
                                FAQCard(
                                    faq: faq,
                                    isExpanded: expandedQuestions.contains(faq.question),
                                    onTap: {
                                        if expandedQuestions.contains(faq.question) {
                                            expandedQuestions.remove(faq.question)
                                        } else {
                                            expandedQuestions.insert(faq.question)
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Contact Support
                        VStack(spacing: 16) {
                            Text("Still have questions?")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Can't find what you're looking for? Our support team is here to help!")
                                .font(.body)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                            
                            Button(action: {
                                dismiss()
                            }) {
                                Text("Contact Support")
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
                        .padding(.top, 20)
                        
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

struct FAQItem {
    let question: String
    let answer: String
}

struct FAQCard: View {
    let faq: FAQItem
    let isExpanded: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onTap) {
                HStack {
                    Text(faq.question)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                        .lineLimit(isExpanded ? nil : 2)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding()
            }
            
            if isExpanded {
                Divider()
                    .background(Color.gray.opacity(0.3))
                
                Text(faq.answer)
                    .font(.body)
                    .foregroundColor(.gray)
                    .lineSpacing(4)
                    .padding(.horizontal)
                    .padding(.bottom)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color(red: 0.1, green: 0.1, blue: 0.15))
        .cornerRadius(12)
        .animation(.easeInOut(duration: 0.3), value: isExpanded)
    }
}

#Preview {
    FAQView()
} 