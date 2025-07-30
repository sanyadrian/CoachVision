import SwiftUI

struct EditWorkoutDayView: View {
    let dayName: String
    let currentWorkout: [String: Any]
    let planId: Int
    @EnvironmentObject var planManager: TrainingPlanManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var workoutType: String = ""
    @State private var exercises: [String] = []
    @State private var newExercise: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text("Edit \(dayName.capitalized)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Customize your workout for this day")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.top)
                
                // Workout Type
                VStack(alignment: .leading, spacing: 8) {
                    Text("Workout Type")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    TextField("e.g., Upper Body Strength Training", text: $workoutType)
                        .textFieldStyle(CustomTextFieldStyle())
                }
                .padding(.horizontal)
                
                // Exercises
                VStack(alignment: .leading, spacing: 12) {
                    Text("Exercises")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    // Add new exercise
                    HStack {
                        TextField("e.g., Bench Press: 4 sets x 8 reps", text: $newExercise)
                            .textFieldStyle(CustomTextFieldStyle())
                        
                        Button(action: addExercise) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                                .font(.title2)
                        }
                        .disabled(newExercise.isEmpty)
                    }
                    
                    // Exercise list
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(exercises.indices, id: \.self) { index in
                                HStack {
                                    Text(exercises[index])
                                        .foregroundColor(.white)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                        .background(Color(red: 0.2, green: 0.2, blue: 0.25))
                                        .cornerRadius(8)
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        exercises.remove(at: index)
                                    }) {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                }
                .padding(.horizontal)
                
                // Error message
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                // Save button
                Button(action: saveWorkout) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                .scaleEffect(0.8)
                        } else {
                            Text("Save Changes")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(25)
                }
                .disabled(isLoading || workoutType.isEmpty || exercises.isEmpty)
                .opacity((workoutType.isEmpty || exercises.isEmpty) ? 0.6 : 1.0)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .background(Color.black)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
        .onAppear {
            loadCurrentWorkout()
        }
    }
    
    private func loadCurrentWorkout() {
        if let workoutTypeValue = currentWorkout["workout_type"] as? String {
            workoutType = workoutTypeValue
        }
        
        if let exercisesArray = currentWorkout["exercises"] as? [String] {
            exercises = exercisesArray
        }
    }
    
    private func addExercise() {
        guard !newExercise.isEmpty else { return }
        exercises.append(newExercise)
        newExercise = ""
    }
    
    private func saveWorkout() {
        guard !workoutType.isEmpty && !exercises.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        
        let updatedWorkout: [String: Any] = [
            "workout_type": workoutType,
            "exercises": exercises
        ]
        
        planManager.editPlanDay(planId: planId, dayName: dayName.lowercased(), workout: updatedWorkout) { success in
            DispatchQueue.main.async {
                isLoading = false
                if success {
                    dismiss()
                } else {
                    errorMessage = "Failed to save changes. Please try again."
                }
            }
        }
    }
}



#Preview {
    EditWorkoutDayView(
        dayName: "Monday",
        currentWorkout: [
            "workout_type": "Upper Body Strength",
            "exercises": ["Bench Press: 4 sets x 8 reps", "Pull-Ups: 3 sets x 10 reps"]
        ],
        planId: 1
    )
    .environmentObject(TrainingPlanManager(authToken: nil))
    .preferredColorScheme(.dark)
} 