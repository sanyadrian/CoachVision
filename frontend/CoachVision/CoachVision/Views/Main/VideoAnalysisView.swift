import SwiftUI

struct VideoAnalysisView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showingCamera = false
    @State private var selectedExercise = "squat"
    
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
                            Text("Video Analysis")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Record and analyze your form")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        // Exercise Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Select Exercise")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 12) {
                                ExerciseCard(
                                    title: "Squat",
                                    icon: "figure.walk",
                                    isSelected: selectedExercise == "squat"
                                ) {
                                    selectedExercise = "squat"
                                }
                                
                                ExerciseCard(
                                    title: "Deadlift",
                                    icon: "figure.strengthtraining.traditional",
                                    isSelected: selectedExercise == "deadlift"
                                ) {
                                    selectedExercise = "deadlift"
                                }
                                
                                ExerciseCard(
                                    title: "Push-up",
                                    icon: "figure.mixed.cardio",
                                    isSelected: selectedExercise == "pushup"
                                ) {
                                    selectedExercise = "pushup"
                                }
                                
                                ExerciseCard(
                                    title: "Pull-up",
                                    icon: "figure.climbing",
                                    isSelected: selectedExercise == "pullup"
                                ) {
                                    selectedExercise = "pullup"
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Record Button
                        Button(action: {
                            showingCamera = true
                        }) {
                            HStack {
                                Image(systemName: "video.fill")
                                    .font(.title2)
                                Text("Record Exercise")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(Color.white)
                            .cornerRadius(30)
                        }
                        .padding(.horizontal, 20)
                        
                        // Recent Analyses
                        VStack(spacing: 16) {
                            Text("Recent Analyses")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            VStack(spacing: 12) {
                                ForEach(0..<3) { index in
                                    AnalysisCard(
                                        exercise: ["Squat", "Deadlift", "Push-up"][index],
                                        date: "Today",
                                        score: 85 - (index * 5),
                                        feedback: "Good form overall, keep your back straight"
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
        .sheet(isPresented: $showingCamera) {
            CameraView(exerciseType: selectedExercise)
        }
    }
}

struct ExerciseCard: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundColor(isSelected ? .white : .gray)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .gray)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(isSelected ? Color(red: 0.2, green: 0.2, blue: 0.3) : Color(red: 0.1, green: 0.1, blue: 0.15))
            .cornerRadius(16)
        }
    }
}

struct AnalysisCard: View {
    let exercise: String
    let date: String
    let score: Int
    let feedback: String
    
    var body: some View {
        Button(action: {
            // TODO: Navigate to analysis details
        }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(exercise)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text(date)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(score)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(scoreColor)
                        
                        Text("Score")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Text(feedback)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
            .padding()
            .background(Color(red: 0.1, green: 0.1, blue: 0.15))
            .cornerRadius(16)
        }
    }
    
    private var scoreColor: Color {
        if score >= 80 { return .green }
        if score >= 60 { return .orange }
        return .red
    }
}

struct CameraView: View {
    let exerciseType: String
    @Environment(\.dismiss) var dismiss
    @State private var isRecording = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("Record \(exerciseType.capitalized)")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                Spacer()
                
                // Camera placeholder
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(red: 0.1, green: 0.1, blue: 0.15))
                    .frame(height: 400)
                    .overlay(
                        VStack(spacing: 16) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            
                            Text("Camera View")
                                .font(.headline)
                                .foregroundColor(.gray)
                            
                            Text("Tap to start recording")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    )
                    .onTapGesture {
                        isRecording.toggle()
                    }
                
                Spacer()
                
                // Recording indicator
                if isRecording {
                    HStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 12, height: 12)
                            .scaleEffect(isRecording ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isRecording)
                        
                        Text("Recording...")
                            .font(.headline)
                            .foregroundColor(.red)
                    }
                }
                
                Spacer(minLength: 50)
            }
        }
    }
}

#Preview {
    VideoAnalysisView()
        .environmentObject(AuthenticationManager())
} 