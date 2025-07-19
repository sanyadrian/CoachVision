import SwiftUI
import AVFoundation
import AVKit
import Photos

struct VideoAnalysisView: View {
    @StateObject private var cameraManager = CameraManager()
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var recordedVideoURL: URL?
    @State private var isRecording = false
    @State private var showingVideoPlayer = false
    @State private var videoSavedToPhotos = false
    @State private var isUploading = false
    @State private var uploadProgress: Double = 0.0
    @State private var showingExerciseTypePicker = false
    @State private var selectedExerciseType = "pushup"
    @State private var uploadedVideoURL: URL?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Video Analysis")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Record or upload your training videos")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 20)
                    
                    Spacer()
                    
                    // Camera Preview
                    if let previewLayer = cameraManager.previewLayer {
                        CameraPreviewView(previewLayer: previewLayer)
                            .frame(height: 300)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    } else {
                        // Placeholder when camera not available
                        VStack(spacing: 16) {
                            Image(systemName: "video.slash")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            
                            Text("Camera Access Required")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("Please grant camera permissions to record videos")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                        .frame(height: 300)
                        .frame(maxWidth: .infinity)
                        .background(Color(red: 0.1, green: 0.1, blue: 0.15))
                        .cornerRadius(16)
                    }
                    
                    // Recording Controls
                    HStack(spacing: 40) {
                        // Record Button
                        Button(action: {
                            if isRecording {
                                cameraManager.stopRecording()
                                isRecording = false
                            } else {
                                cameraManager.startRecording()
                                isRecording = true
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .fill(isRecording ? Color.red : Color.white)
                                    .frame(width: 80, height: 80)
                                
                                if isRecording {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.white)
                                        .frame(width: 32, height: 32)
                                } else {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 60, height: 60)
                                }
                            }
                        }
                        .disabled(!cameraManager.isCameraAvailable)
                        
                        // Upload Button
                        Button(action: {
                            showingImagePicker = true
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: "photo.on.rectangle")
                                    .font(.system(size: 30))
                                    .foregroundColor(.white)
                                
                                Text("Upload")
                                    .font(.caption)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    
                    // Status Text
                    if isRecording {
                        Text("Recording...")
                            .font(.headline)
                            .foregroundColor(.red)
                            .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: isRecording)
                    } else if let videoURL = recordedVideoURL {
                        VStack(spacing: 12) {
                            Text("Video Recorded!")
                                .font(.headline)
                                .foregroundColor(.green)
                            
                            if videoSavedToPhotos {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("Saved to Photos")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                }
                            }
                            
                            Button("Play Video") {
                                showingVideoPlayer = true
                            }
                            .foregroundColor(.blue)
                            .font(.subheadline)
                            
                            Button("Upload for Analysis") {
                                showingExerciseTypePicker = true
                            }
                            .foregroundColor(.orange)
                            .font(.subheadline)
                            .padding(.top, 8)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
            }
        }
        .onAppear {
            cameraManager.checkCameraPermission()
        }
                                .sheet(isPresented: $showingImagePicker) {
                            ImagePicker(mediaTypes: ["public.movie"], allowsEditing: true) { url in
                                if let videoURL = url {
                                    recordedVideoURL = videoURL
                                    uploadedVideoURL = videoURL
                                }
                            }
                        }
        .sheet(isPresented: $showingVideoPlayer) {
            if let videoURL = recordedVideoURL {
                VideoPlayerView(videoURL: videoURL)
            }
        }
        .onReceive(cameraManager.$recordedVideoURL) { url in
            recordedVideoURL = url
        }
        .onReceive(cameraManager.$videoSavedToPhotos) { saved in
            videoSavedToPhotos = saved
        }
        .sheet(isPresented: $showingExerciseTypePicker) {
            ExerciseTypePickerView(
                selectedExerciseType: $selectedExerciseType,
                onUpload: {
                    if let videoURL = uploadedVideoURL {
                        uploadVideoForAnalysis(videoURL: videoURL, exerciseType: selectedExerciseType)
                    }
                }
            )
        }
    }
    
    private func uploadVideoForAnalysis(videoURL: URL, exerciseType: String) {
        guard let token = authManager.authToken,
              let userId = authManager.currentUser?.id else {
            print("No authentication available")
            return
        }
        
        isUploading = true
        uploadProgress = 0.0
        
        // Create the upload URL
        let uploadURL = URL(string: "http://192.168.4.27:8000/videos/analyze")!
        
        // Create the request
        var request = URLRequest(url: uploadURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        // Create multipart form data
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add user_id parameter
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"user_id\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(userId)\r\n".data(using: .utf8)!)
        
        // Add exercise_type parameter
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"exercise_type\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(exerciseType)\r\n".data(using: .utf8)!)
        
        // Add video file
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"video_file\"; filename=\"\(videoURL.lastPathComponent)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: video/mp4\r\n\r\n".data(using: .utf8)!)
        
        do {
            let videoData = try Data(contentsOf: videoURL)
            body.append(videoData)
            body.append("\r\n".data(using: .utf8)!)
        } catch {
            print("Error reading video data: \(error)")
            isUploading = false
            return
        }
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        // Perform the upload
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isUploading = false
                
                if let error = error {
                    print("Upload error: \(error)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                        print("Video uploaded successfully!")
                        if let data = data {
                            print("Response: \(String(data: data, encoding: .utf8) ?? "")")
                        }
                    } else {
                        print("Upload failed with status: \(httpResponse.statusCode)")
                        if let data = data {
                            print("Error response: \(String(data: data, encoding: .utf8) ?? "")")
                        }
                    }
                }
            }
        }.resume()
    }
}

// Camera Preview View
struct CameraPreviewView: UIViewRepresentable {
    let previewLayer: AVCaptureVideoPreviewLayer
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        view.layer.addSublayer(previewLayer)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            self.previewLayer.frame = uiView.bounds
            CATransaction.commit()
        }
    }
}

// Camera Manager
class CameraManager: NSObject, ObservableObject {
    @Published var isCameraAvailable = false
    @Published var recordedVideoURL: URL?
    @Published var videoSavedToPhotos = false
    
    private var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureMovieFileOutput?
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        self.setupCamera()
                    }
                }
            }
        case .denied, .restricted:
            break
        @unknown default:
            break
        }
    }
    
    private func setupCamera() {
        DispatchQueue.global(qos: .userInitiated).async {
            let session = AVCaptureSession()
            session.sessionPreset = .high
            
            guard let videoDevice = AVCaptureDevice.default(for: .video),
                  let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else {
                print("Failed to setup video device")
                return
            }
            
            if session.canAddInput(videoInput) {
                session.addInput(videoInput)
            }
            
            let movieOutput = AVCaptureMovieFileOutput()
            if session.canAddOutput(movieOutput) {
                session.addOutput(movieOutput)
            }
            
            let previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer.videoGravity = .resizeAspectFill
            
            DispatchQueue.main.async {
                self.captureSession = session
                self.videoOutput = movieOutput
                self.previewLayer = previewLayer
                self.isCameraAvailable = true
                
                // Start the session on a background queue
                DispatchQueue.global(qos: .userInitiated).async {
                    session.startRunning()
                    print("Camera session started")
                }
            }
        }
    }
    
    func startRecording() {
        guard let videoOutput = videoOutput else { return }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let videoName = "training_video_\(Date().timeIntervalSince1970).mov"
        let videoURL = documentsPath.appendingPathComponent(videoName)
        
        videoOutput.startRecording(to: videoURL, recordingDelegate: self)
    }
    
    func stopRecording() {
        videoOutput?.stopRecording()
    }
}

extension CameraManager: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        DispatchQueue.main.async {
            if error == nil {
                self.recordedVideoURL = outputFileURL
                // Save video to photo library
                self.saveVideoToPhotos(url: outputFileURL)
            }
        }
    }
    
    private func saveVideoToPhotos(url: URL) {
        PHPhotoLibrary.requestAuthorization { status in
            switch status {
            case .authorized, .limited:
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
                }) { success, error in
                    DispatchQueue.main.async {
                        if success {
                            print("Video saved to photo library successfully")
                            self.videoSavedToPhotos = true
                        } else {
                            print("Failed to save video to photo library: \(error?.localizedDescription ?? "Unknown error")")
                        }
                    }
                }
            case .denied, .restricted:
                print("Photo library access denied")
            case .notDetermined:
                print("Photo library access not determined")
            @unknown default:
                print("Unknown photo library authorization status")
            }
        }
    }
}

// Image Picker for uploading videos
struct ImagePicker: UIViewControllerRepresentable {
    let mediaTypes: [String]
    let allowsEditing: Bool
    let completion: (URL?) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.mediaTypes = mediaTypes
        picker.allowsEditing = allowsEditing
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(completion: completion)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let completion: (URL?) -> Void
        
        init(completion: @escaping (URL?) -> Void) {
            self.completion = completion
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let videoURL = info[.mediaURL] as? URL {
                completion(videoURL)
            } else {
                completion(nil)
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            completion(nil)
            picker.dismiss(animated: true)
        }
    }
}

// Video Player View
struct VideoPlayerView: UIViewControllerRepresentable {
    let videoURL: URL
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let player = AVPlayer(url: videoURL)
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        return playerViewController
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}
}

// Exercise Type Picker View
struct ExerciseTypePickerView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedExerciseType: String
    let onUpload: () -> Void
    
    private let exerciseTypes = [
        "pushup", "squat", "deadlift", "bench_press", "pullup", 
        "plank", "burpee", "lunge", "mountain_climber", "jumping_jack"
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Text("Select Exercise Type")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                        ForEach(exerciseTypes, id: \.self) { exerciseType in
                            Button(action: {
                                selectedExerciseType = exerciseType
                            }) {
                                VStack(spacing: 8) {
                                    Text(exerciseType.replacingOccurrences(of: "_", with: " ").capitalized)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(selectedExerciseType == exerciseType ? Color.blue : Color(red: 0.1, green: 0.1, blue: 0.15))
                                .cornerRadius(12)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Button("Upload Video") {
                        onUpload()
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .cornerRadius(12)
                }
                .padding()
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
    }
}

#Preview {
    VideoAnalysisView()
} 