import SwiftUI
import AVFoundation
import UIKit

struct LiveCameraView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var mealManager: MealManager
    @EnvironmentObject var foodRecognitionService: FoodRecognitionService
    
    @State private var showingFoodDetails = false
    @State private var recognizedFood: FoodItem?
    @State private var isScanning = false
    @State private var lastScanTime: Date = Date()
    @State private var cameraError: String?
    
    let selectedDate: Date
    
    var body: some View {
        ZStack {
            // Live camera feed
            LiveCameraPreviewView(
                isScanning: $isScanning, 
                onFrameCaptured: { image in
                    handleFrameCapture(image)
                },
                onError: { error in
                    cameraError = error
                }
            )
            .ignoresSafeArea()
            
            // Overlay UI
            VStack {
                // Top bar
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(8)
                    
                    Spacer()
                    
                    Text("Point camera at food")
                        .foregroundColor(.white)
                        .font(.headline)
                        .padding()
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(8)
                    
                    Spacer()
                    
                    Button(isScanning ? "Stop" : "Start") {
                        isScanning.toggle()
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(isScanning ? Color.red.opacity(0.8) : Color.green.opacity(0.8))
                    .cornerRadius(8)
                }
                .padding()
                
                Spacer()
                
                // Scanning indicator
                if foodRecognitionService.isAnalyzing {
                    VStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(1.2)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        Text("Analyzing...")
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(12)
                }
                
                // Error message
                if let errorMessage = foodRecognitionService.errorMessage {
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(8)
                }
                
                // Camera error message
                if let cameraError = cameraError {
                    Text("Camera Error: \(cameraError)")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(8)
                }
                
                // Instructions
                VStack(spacing: 8) {
                    Text("Hold camera steady over food")
                        .font(.caption)
                        .foregroundColor(.white)
                    Text("Tap 'Start' to begin scanning")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding()
                .background(Color.black.opacity(0.5))
                .cornerRadius(8)
                .padding(.bottom, 50)
            }
        }
        .sheet(isPresented: $showingFoodDetails) {
            if let recognizedFood = recognizedFood {
                FoodDetailsView(
                    food: recognizedFood,
                    selectedDate: selectedDate,
                    onAddMeal: { meal in
                        print("🔍 LiveCameraView: Adding meal with token: \(mealManager.authToken != nil), userId: \(mealManager.userId != nil)")
                        mealManager.addMeal(meal) { success in
                            if success {
                                dismiss()
                            } else {
                                print("❌ LiveCameraView: Failed to add meal")
                            }
                        }
                    }
                )
                .environmentObject(mealManager)
            }
        }
        .onAppear {
            print("🔍 LiveCameraView: onAppear - token: \(mealManager.authToken != nil), userId: \(mealManager.userId)")
        }
    }
    
    private func handleFrameCapture(_ image: UIImage) {
        print("🔍 LiveCameraView: Frame received, isScanning: \(isScanning)")
        // Only process frames if scanning is active and enough time has passed
        let now = Date()
        guard isScanning && 
              now.timeIntervalSince(lastScanTime) > 2.0 && 
              !foodRecognitionService.isAnalyzing else {
            print("🔍 LiveCameraView: Skipping frame - scanning: \(isScanning), timeSinceLast: \(now.timeIntervalSince(lastScanTime)), isAnalyzing: \(foodRecognitionService.isAnalyzing)")
            return
        }
        
        lastScanTime = now
        
        foodRecognitionService.recognizeFood(from: image) { result in
            switch result {
            case .success(let foodItem):
                if foodItem.confidence > 0.7 { // Only show high confidence results
                    recognizedFood = foodItem
                    showingFoodDetails = true
                    isScanning = false // Stop scanning when food is found
                }
            case .failure(let error):
                foodRecognitionService.errorMessage = error.localizedDescription
            }
        }
    }
}

struct LiveCameraPreviewView: UIViewRepresentable {
    @Binding var isScanning: Bool
    let onFrameCaptured: (UIImage) -> Void
    let onError: (String) -> Void
    
    func makeUIView(context: Context) -> UIView {
        print("🔍 LiveCameraPreviewView: makeUIView called")
        let view = UIView()
        view.backgroundColor = .red // Changed to red to test if view is visible
        
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = .high
        print("🔍 LiveCameraPreviewView: Created AVCaptureSession")
        
        // Configure session on background thread
        DispatchQueue.global(qos: .userInitiated).async {
            context.coordinator.isConfiguring = true
            captureSession.beginConfiguration()
            print("🔍 LiveCameraPreviewView: Session configuration started")
        
            guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
                print("❌ LiveCameraPreviewView: Camera not available")
                DispatchQueue.main.async {
                    context.coordinator.onError?("Camera not available")
                }
                return
            }
            print("✅ LiveCameraPreviewView: Camera device found")
            
            guard let input = try? AVCaptureDeviceInput(device: camera) else {
                print("❌ LiveCameraPreviewView: Failed to create camera input")
                DispatchQueue.main.async {
                    context.coordinator.onError?("Failed to access camera")
                }
                return
            }
            print("✅ LiveCameraPreviewView: Camera input created successfully")
            
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
                print("✅ LiveCameraPreviewView: Added camera input to session")
            } else {
                print("❌ LiveCameraPreviewView: Failed to add camera input to session")
                return
            }
            
            let videoOutput = AVCaptureVideoDataOutput()
            videoOutput.setSampleBufferDelegate(context.coordinator, queue: DispatchQueue.global(qos: .userInteractive))
            videoOutput.alwaysDiscardsLateVideoFrames = true
            print("✅ LiveCameraPreviewView: Created video output")
            
            if captureSession.canAddOutput(videoOutput) {
                captureSession.addOutput(videoOutput)
                print("✅ LiveCameraPreviewView: Added video output to session")
            } else {
                print("❌ LiveCameraPreviewView: Failed to add video output to session")
                return
            }
            
            captureSession.commitConfiguration()
            print("✅ LiveCameraPreviewView: Session configuration committed")
            
            // Start the session
            captureSession.startRunning()
            print("✅ LiveCameraPreviewView: Session started successfully")
            
            // Clear configuring flag
            context.coordinator.isConfiguring = false
        }
        
        context.coordinator.captureSession = captureSession
        context.coordinator.onFrameCaptured = onFrameCaptured
        context.coordinator.onError = onError
        print("✅ LiveCameraPreviewView: Coordinator setup complete")
        
        // Setup preview layer on main thread
        DispatchQueue.main.async {
            let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.frame = view.bounds
            print("✅ LiveCameraPreviewView: Created preview layer with frame: \(view.bounds)")
            
            view.layer.addSublayer(previewLayer)
            print("✅ LiveCameraPreviewView: Added preview layer to view")
            
            // Force layout update
            view.setNeedsLayout()
            view.layoutIfNeeded()
            print("✅ LiveCameraPreviewView: Setup complete")
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        print("🔍 LiveCameraPreviewView: updateUIView called, isScanning: \(isScanning)")
        
        // Update preview layer frame
        if let previewLayer = uiView.layer.sublayers?.first(where: { $0 is AVCaptureVideoPreviewLayer }) as? AVCaptureVideoPreviewLayer {
            previewLayer.frame = uiView.bounds
            print("✅ LiveCameraPreviewView: Updated preview layer frame to: \(uiView.bounds)")
        }
        
        // Don't start/stop session if it's being configured
        guard !context.coordinator.isConfiguring else {
            print("🔍 LiveCameraPreviewView: Skipping session control - session is being configured")
            return
        }
        
        if isScanning {
            print("🔍 LiveCameraPreviewView: Starting capture session")
            DispatchQueue.global(qos: .userInitiated).async {
                context.coordinator.captureSession?.startRunning()
            }
        } else {
            print("🔍 LiveCameraPreviewView: Stopping capture session")
            DispatchQueue.global(qos: .userInitiated).async {
                context.coordinator.captureSession?.stopRunning()
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
        var captureSession: AVCaptureSession?
        var onFrameCaptured: ((UIImage) -> Void)?
        var onError: ((String) -> Void)?
        var isConfiguring = false
        
        func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            print("📸 LiveCameraPreviewView: Frame captured")
            guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { 
                print("❌ LiveCameraPreviewView: Failed to get image buffer")
                return 
            }
            
            let ciImage = CIImage(cvImageBuffer: imageBuffer)
            let context = CIContext()
            
            guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { 
                print("❌ LiveCameraPreviewView: Failed to create CGImage")
                return 
            }
            
            let image = UIImage(cgImage: cgImage)
            print("✅ LiveCameraPreviewView: Image created successfully")
            
            DispatchQueue.main.async {
                self.onFrameCaptured?(image)
            }
        }
    }
}

struct FoodDetailsView: View {
    let food: FoodItem
    let selectedDate: Date
    let onAddMeal: (Meal) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var adjustedCalories: String = ""
    @State private var adjustedProtein: String = ""
    @State private var adjustedCarbs: String = ""
    @State private var adjustedFats: String = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Food image placeholder
                Image(systemName: "fork.knife")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                    .frame(width: 120, height: 120)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(60)
                
                // Food name and confidence
                VStack(spacing: 8) {
                    Text(food.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("Confidence: \(Int(food.confidence * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Nutrition details
                VStack(spacing: 16) {
                    NutritionRow(title: "Calories", value: "\(food.calories)", unit: "kcal")
                    NutritionRow(title: "Protein", value: String(format: "%.1f", food.protein), unit: "g")
                    NutritionRow(title: "Carbs", value: String(format: "%.1f", food.carbs), unit: "g")
                    NutritionRow(title: "Fats", value: String(format: "%.1f", food.fats), unit: "g")
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                // Adjustment fields
                VStack(spacing: 12) {
                    Text("Adjust Values (Optional)")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack {
                        Text("Calories:")
                        TextField("\(food.calories)", text: $adjustedCalories)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    HStack {
                        Text("Protein:")
                        TextField(String(format: "%.1f", food.protein), text: $adjustedProtein)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    HStack {
                        Text("Carbs:")
                        TextField(String(format: "%.1f", food.carbs), text: $adjustedCarbs)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    HStack {
                        Text("Fats:")
                        TextField(String(format: "%.1f", food.fats), text: $adjustedFats)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                
                Spacer()
                
                // Add meal button
                Button(action: addMeal) {
                    Text("Add to My Meals")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
            }
            .padding()
            .navigationTitle("Food Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            adjustedCalories = "\(food.calories)"
            adjustedProtein = String(format: "%.1f", food.protein)
            adjustedCarbs = String(format: "%.1f", food.carbs)
            adjustedFats = String(format: "%.1f", food.fats)
        }
    }
    
    private func addMeal() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: selectedDate)
        
        let calories = Int(adjustedCalories) ?? food.calories
        let protein = Int(Double(adjustedProtein) ?? food.protein)
        let carbs = Int(Double(adjustedCarbs) ?? food.carbs)
        let fats = Int(Double(adjustedFats) ?? food.fats)
        
        let meal = Meal(
            id: 0,
            name: food.name,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fats: fats,
            date: dateString
        )
        
        onAddMeal(meal)
    }
}

struct NutritionRow: View {
    let title: String
    let value: String
    let unit: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
            Text(unit)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
} 