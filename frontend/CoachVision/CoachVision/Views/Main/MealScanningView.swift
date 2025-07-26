 import SwiftUI

struct MealScanningView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var mealManager: MealManager
    @StateObject private var foodRecognitionService = FoodRecognitionService()
    
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var showingActionSheet = false
    @State private var showingLiveCamera = false
    @State private var recognizedFood: FoodItem?
    @State private var showingFoodDetails = false
    
    let selectedDate: Date
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text("Scan Your Meal")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Take a photo or select from library")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                Spacer()
                
                // Image preview or placeholder
                if let selectedImage = selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 300, maxHeight: 300)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("No image selected")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("Tap the button below to scan your food")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: 300, maxHeight: 300)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 12) {
                    Button(action: {
                        showingActionSheet = true
                    }) {
                        HStack {
                            Image(systemName: "camera.fill")
                            Text("Select Image")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    
                    if selectedImage != nil {
                        Button(action: {
                            selectedImage = nil
                        }) {
                            Text("Clear Image")
                                .font(.headline)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(12)
                        }
                    }
                }
                
                // Loading indicator
                if foodRecognitionService.isAnalyzing {
                    VStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Analyzing food...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
                
                // Error message
                if let errorMessage = foodRecognitionService.errorMessage {
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
        }
        .actionSheet(isPresented: $showingActionSheet) {
            ActionSheet(
                title: Text("Select Scanning Method"),
                buttons: [
                    .default(Text("Live Camera Scan")) {
                        showingLiveCamera = true
                    },
                    .default(Text("Take Photo")) {
                        showingCamera = true
                    },
                    .default(Text("Photo Library")) {
                        showingImagePicker = true
                    },
                    .cancel()
                ]
            )
        }
        .sheet(isPresented: $showingImagePicker) {
            PhotoPicker(selectedImage: $selectedImage, sourceType: .photoLibrary)
        }
        .sheet(isPresented: $showingCamera) {
            PhotoPicker(selectedImage: $selectedImage, sourceType: .camera)
        }
        .sheet(isPresented: $showingLiveCamera) {
            LiveCameraView(selectedDate: selectedDate)
        }
        .onChange(of: selectedImage) { newImage in
            if let image = newImage {
                scanFood(image: image)
            }
        }
    }
    
    private func scanFood(image: UIImage) {
        foodRecognitionService.recognizeFood(from: image) { result in
            switch result {
            case .success(let foodItem):
                recognizedFood = foodItem
                showingFoodDetails = true
            case .failure(let error):
                foodRecognitionService.errorMessage = error.localizedDescription
            }
        }
    }
}

// Photo Picker for meal scanning
struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    let sourceType: UIImagePickerController.SourceType
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.mediaTypes = ["public.image"]
        picker.allowsEditing = false
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: PhotoPicker
        
        init(_ parent: PhotoPicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}