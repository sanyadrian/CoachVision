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
    @State private var videoAnalyses: [VideoAnalysis] = []
    @State private var isLoadingAnalyses = false
    @State private var showingAnalysisDetail = false
    @State private var selectedAnalysis: VideoAnalysis?
    @State private var selectedViewMode = 0
    @State private var showingDeleteAlert = false
    @State private var analysisToDelete: VideoAnalysis?
    @State private var isViewReady = false
    @State private var isAnalyzing = false
    @State private var showUploadButtons = true
    @State private var showingDurationAlert = false
    @State private var videoDuration: Double = 0
    @State private var recordingTimer: Timer?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Video Analysis")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Record or upload your training videos (max 10 seconds, trimming available)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            fetchVideoAnalyses()
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.top, 20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Segmented Control
                    Picker("View Mode", selection: $selectedViewMode) {
                        Text("Record").tag(0)
                        Text("Analyses").tag(1)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal, 20)
                    
                    if selectedViewMode == 0 {
                        // Recording View
                        recordingView
                    } else {
                        // Analyses View
                        analysesView
                    }
                }
                .padding(.horizontal, 20)
            }
            
            // Upload Loading Overlay
            if isUploading {
                ZStack {
                    Color.black.opacity(0.7)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        
                        Text("Analyzing Video...")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("This may take a few moments")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Text("Video will be deleted after analysis for privacy")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(Color(red: 0.1, green: 0.1, blue: 0.15))
                    .cornerRadius(16)
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(mediaTypes: ["public.movie"], allowsEditing: true) { videoURL in
                if let url = videoURL {
                    checkVideoDuration(url: url) { duration in
                        if duration <= 10.0 {
                            recordedVideoURL = url
                            videoDuration = duration
                        } else {
                            // For longer videos, show trimming option
                            recordedVideoURL = url
                            videoDuration = duration
                            // Note: The user can trim in the picker, so we accept the result
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingExerciseTypePicker) {
            ExerciseTypePickerView(selectedExerciseType: $selectedExerciseType) {
                uploadVideoForAnalysis()
                // Dismiss the picker after starting upload
                showingExerciseTypePicker = false
            }
        }
        .sheet(isPresented: $showingVideoPlayer) {
            if let videoURL = recordedVideoURL {
                VideoPlayerView(videoURL: videoURL)
            }
        }
        .sheet(isPresented: $showingAnalysisDetail) {
            if let analysis = selectedAnalysis {
                VideoAnalysisDetailView(analysis: analysis) {
                    fetchVideoAnalyses()
                }
            }
        }
        .onReceive(cameraManager.$recordedVideoURL) { url in
            if let videoURL = url {
                checkVideoDuration(url: videoURL) { duration in
                    recordedVideoURL = videoURL
                    videoDuration = duration
                }
            }
        }
        .onReceive(cameraManager.$videoSavedToPhotos) { saved in
            videoSavedToPhotos = saved
        }
        .onAppear {
            cameraManager.checkCameraPermission()
            fetchVideoAnalyses()
        }
    }
    
    // MARK: - Computed Views
    
    private var recordingView: some View {
        VStack(spacing: 24) {
            // Camera Preview
            if let previewLayer = cameraManager.previewLayer {
                CameraPreviewView(previewLayer: previewLayer)
                    .frame(height: 300)
                    .frame(maxWidth: .infinity)
                    .background(Color(red: 0.1, green: 0.1, blue: 0.15))
                    .cornerRadius(16)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "video.slash")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("Camera Not Available")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("Please allow camera access in Settings")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .frame(height: 300)
                .frame(maxWidth: .infinity)
                .background(Color(red: 0.1, green: 0.1, blue: 0.15))
                .cornerRadius(16)
            }
            
            // Recording Timer (if recording)
            if isRecording {
                Text("Recording... \(Int(videoDuration))s / 10s")
                    .font(.headline)
                    .foregroundColor(.red)
                    .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: isRecording)
            }
            
            // Recording Controls
            HStack(spacing: 40) {
                // Record Button
                Button(action: {
                    if isRecording {
                        cameraManager.stopRecording()
                        isRecording = false
                        recordingTimer?.invalidate()
                        recordingTimer = nil
                    } else {
                        cameraManager.startRecording()
                        isRecording = true
                        videoDuration = 0
                        // Reset upload buttons when starting new recording
                        showUploadButtons = true
                        
                        // Start timer to track recording duration
                        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                            videoDuration += 0.1
                            if videoDuration >= 10.0 {
                                cameraManager.stopRecording()
                                isRecording = false
                                recordingTimer?.invalidate()
                                recordingTimer = nil
                            }
                        }
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
                if showUploadButtons || recordedVideoURL == nil {
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
            }
            
            // Status Text
            if isRecording {
                Text("Recording... (Max 10 seconds)")
                    .font(.headline)
                    .foregroundColor(.red)
                    .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: isRecording)
            } else if let videoURL = recordedVideoURL, !isAnalyzing {
                VStack(spacing: 12) {
                    Text("Video Recorded! (\(String(format: "%.1f", videoDuration))s)")
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
                        // Immediately switch to Analyses tab and show analyzing state
                        selectedViewMode = 1
                        isAnalyzing = true
                        showingExerciseTypePicker = true
                    }
                    .foregroundColor(isAnalyzing ? .gray : .orange)
                    .font(.subheadline)
                    .padding(.top, 8)
                    .disabled(isAnalyzing)
                    .overlay(
                        Group {
                            if isAnalyzing {
                                HStack {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                                    Text("Analyzing...")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    )
                }
                .opacity(isAnalyzing ? 0.3 : 1.0)
                .disabled(isAnalyzing)
            }
            
            Spacer()
        }
    }
    
    private var analysesView: some View {
        VStack(spacing: 16) {
            if isAnalyzing {
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: .orange))
                    
                    Text("Analyzing Video...")
                        .font(.headline)
                        .foregroundColor(.orange)
                    
                    Text("Please wait while AI analyzes your form")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                    
                    Text("This may take a few moments")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if isLoadingAnalyses {
                ProgressView("Loading analyses...")
                    .foregroundColor(.white)
            } else if videoAnalyses.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "video.slash")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("No Video Analyses")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("Record and upload videos to see your analysis results")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(videoAnalyses) { analysis in
                        VideoAnalysisCard(analysis: analysis) {
                            selectedAnalysis = analysis
                            showingAnalysisDetail = true
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                analysisToDelete = analysis
                                showingDeleteAlert = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
                .background(Color.black)
            }
        }
    }
    
    // MARK: - Methods
    
    private func fetchVideoAnalyses() {
        guard let token = authManager.authToken,
              let userId = authManager.currentUser?.id else {
            print("No authentication available")
            return
        }
        
        isLoadingAnalyses = true
        
                    let url = URL(string: "https://flash-list.com/videos/user/\(userId)")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoadingAnalyses = false
                
                if let error = error {
                    print("Error fetching video analyses: \(error)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode == 200,
                   let data = data {
                    do {
                        let analyses = try JSONDecoder().decode([VideoAnalysis].self, from: data)
                        self.videoAnalyses = analyses
                        print("Fetched \(analyses.count) video analyses")
                    } catch {
                        print("Error decoding video analyses: \(error)")
                    }
                } else {
                    print("Failed to fetch video analyses")
                }
            }
        }.resume()
    }
    
    private func deleteVideoAnalysis(analysis: VideoAnalysis) {
        guard let token = authManager.authToken else {
            print("No authentication available")
            return
        }
        
        let url = URL(string: "https://flash-list.com/videos/\(analysis.id)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Delete error: \(error)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        print("Video analysis deleted successfully")
                        // Remove from local array
                        self.videoAnalyses.removeAll { $0.id == analysis.id }
                    } else {
                        print("Delete failed with status: \(httpResponse.statusCode)")
                        if let data = data {
                            print("Error response: \(String(data: data, encoding: .utf8) ?? "")")
                        }
                    }
                }
            }
        }.resume()
    }
    
    private func uploadVideoForAnalysis() {
        guard let token = authManager.authToken,
              let userId = authManager.currentUser?.id,
              let videoURL = recordedVideoURL else {
            print("Missing authentication or video URL")
            return
        }
        
        isUploading = true
        
        let url = URL(string: "https://flash-list.com/videos/analyze")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        var body = Data()
        
        // Add user_id
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"user_id\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(userId)\r\n".data(using: .utf8)!)
        
        // Add exercise_type
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"exercise_type\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(selectedExerciseType)\r\n".data(using: .utf8)!)
        
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
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isUploading = false
                
                if let error = error {
                    print("Upload error: \(error)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        print("Video uploaded and analyzed successfully")
                        // Clear the recorded video URL
                        recordedVideoURL = nil
                        // Switch to Analyses tab to show the analyzing state
                        selectedViewMode = 1
                        // Refresh the analyses list immediately
                        fetchVideoAnalyses()
                        // Keep showing analyzing state for a moment
                        isAnalyzing = true
                        // Stop analyzing state after 3 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            isAnalyzing = false
                            // Refresh again to show the new analysis
                            fetchVideoAnalyses()
                        }
                    } else {
                        print("Upload failed with status: \(httpResponse.statusCode)")
                        if let data = data {
                            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                            print("Error response: \(errorMessage)")
                        }
                    }
                }
            }
        }.resume()
    }
    
    private func checkVideoDuration(url: URL, completion: @escaping (Double) -> Void) {
        let asset = AVURLAsset(url: url)
        let duration = asset.duration.seconds
        completion(duration)
    }
}

// Camera Preview View
struct CameraPreviewView: UIViewRepresentable {
    let previewLayer: AVCaptureVideoPreviewLayer
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        
        // Add preview layer as sublayer
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Update frame when view bounds change
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
                    print("Camera session started successfully")
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
                        // Don't dismiss immediately - let the upload process handle it
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

// MARK: - Video Analysis Card

struct VideoAnalysisCard: View {
    let analysis: VideoAnalysis
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(analysis.exerciseTypeDisplay)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text(analysis.formattedDate)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(analysis.formRating)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(formRatingColor)
                        
                        Text("\(Int(analysis.confidenceScore * 100))%")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Text(analysis.feedback)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }
            .padding()
            .background(Color(red: 0.1, green: 0.1, blue: 0.15))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var formRatingColor: Color {
        switch analysis.formRating.lowercased() {
        case "excellent": return .green
        case "good": return .blue
        case "fair": return .orange
        case "poor": return .red
        default: return .gray
        }
    }
}

// MARK: - Video Analysis Detail View

struct VideoAnalysisDetailView: View {
    let analysis: VideoAnalysis
    let onDelete: () -> Void
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var isViewReady = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        if isViewReady {
                            VStack(spacing: 16) {
                                // Header
                                VStack(spacing: 8) {
                                    Text(analysis.exerciseType.capitalized)
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                    
                                    Text("Analysis Results")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    
                                    // Privacy Notice
                                    HStack {
                                        Image(systemName: "lock.shield")
                                            .foregroundColor(.green)
                                        Text("Video deleted after analysis for privacy")
                                            .font(.caption)
                                            .foregroundColor(.green)
                                    }
                                    .padding(.top, 4)
                                }
                                
                                // Form Rating
                                VStack(spacing: 12) {
                                    Text("Form Rating")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    
                                    HStack {
                                        Text(analysis.formRating)
                                            .font(.title)
                                            .fontWeight(.bold)
                                            .foregroundColor(formRatingColor)
                                        
                                        Spacer()
                                        
                                        VStack(alignment: .trailing, spacing: 4) {
                                            Text("Confidence")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                            Text("\(Int(analysis.confidenceScore * 100))%")
                                                .font(.title2)
                                                .fontWeight(.bold)
                                                .foregroundColor(.white)
                                        }
                                    }
                                    
                                    // Form Score
                                    if let formScore = analysis.parsedAnalysisResult?["form_score"] as? Int {
                                        HStack {
                                            Text("Form Score")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                            Spacer()
                                            Text("\(formScore)/100")
                                                .font(.title2)
                                                .fontWeight(.bold)
                                                .foregroundColor(.white)
                                        }
                                        .padding(.top, 8)
                                    }
                                    
                                    // Frames Analyzed
                                    if let framesAnalyzed = analysis.parsedAnalysisResult?["total_frames_analyzed"] as? Int {
                                        HStack {
                                            Text("Frames Analyzed")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                            Spacer()
                                            Text("\(framesAnalyzed)")
                                                .font(.title2)
                                                .fontWeight(.bold)
                                                .foregroundColor(.white)
                                        }
                                        .padding(.top, 4)
                                    }
                                }
                                .padding()
                                .background(Color(red: 0.1, green: 0.1, blue: 0.15))
                                .cornerRadius(12)
                                
                                // Recommendations
                                if let recommendations = analysis.parsedAnalysisResult?["recommendations"] as? [String], !recommendations.isEmpty {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("Recommendations")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        
                                        VStack(alignment: .leading, spacing: 8) {
                                            ForEach(recommendations, id: \.self) { recommendation in
                                                HStack(alignment: .top, spacing: 8) {
                                                    Image(systemName: "lightbulb.fill")
                                                        .foregroundColor(.yellow)
                                                        .font(.caption)
                                                    Text(recommendation)
                                                        .font(.body)
                                                        .foregroundColor(.white)
                                                        .multilineTextAlignment(.leading)
                                                    Spacer()
                                                }
                                            }
                                        }
                                    }
                                    .padding()
                                    .background(Color(red: 0.1, green: 0.1, blue: 0.15))
                                    .cornerRadius(12)
                                }
                                
                                // Areas for Improvement
                                if let areasForImprovement = analysis.parsedAnalysisResult?["areas_for_improvement"] as? [String], !areasForImprovement.isEmpty {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("Areas for Improvement")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        
                                        VStack(alignment: .leading, spacing: 8) {
                                            ForEach(areasForImprovement, id: \.self) { area in
                                                HStack(alignment: .top, spacing: 8) {
                                                    Image(systemName: "exclamationmark.triangle.fill")
                                                        .foregroundColor(.orange)
                                                        .font(.caption)
                                                    Text(area)
                                                        .font(.body)
                                                        .foregroundColor(.white)
                                                        .multilineTextAlignment(.leading)
                                                    Spacer()
                                                }
                                            }
                                        }
                                    }
                                    .padding()
                                    .background(Color(red: 0.1, green: 0.1, blue: 0.15))
                                    .cornerRadius(12)
                                }
                                
                                // Issues Detected
                                if let issuesDetected = analysis.parsedAnalysisResult?["issues_detected"] as? [String], !issuesDetected.isEmpty {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("Issues Detected")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        
                                        VStack(alignment: .leading, spacing: 8) {
                                            ForEach(issuesDetected, id: \.self) { issue in
                                                HStack(alignment: .top, spacing: 8) {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .foregroundColor(.red)
                                                        .font(.caption)
                                                    Text(issue)
                                                        .font(.body)
                                                        .foregroundColor(.white)
                                                        .multilineTextAlignment(.leading)
                                                    Spacer()
                                                }
                                            }
                                        }
                                    }
                                    .padding()
                                    .background(Color(red: 0.1, green: 0.1, blue: 0.15))
                                    .cornerRadius(12)
                                }
                                
                                // Raw Feedback (fallback)
                                if analysis.parsedAnalysisResult == nil {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("Analysis Data")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        
                                        if analysis.feedback.isEmpty {
                                            VStack(spacing: 16) {
                                                Image(systemName: "exclamationmark.triangle")
                                                    .font(.system(size: 40))
                                                    .foregroundColor(.orange)
                                                
                                                Text("Analysis Data Unavailable")
                                                    .font(.headline)
                                                    .foregroundColor(.white)
                                                
                                                Text("The analysis data could not be loaded. Please try refreshing or contact support if the issue persists.")
                                                    .font(.body)
                                                    .foregroundColor(.gray)
                                                    .multilineTextAlignment(.center)
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                        } else {
                                            Text("Feedback")
                                                .font(.headline)
                                                .foregroundColor(.white)
                                            
                                            Text(analysis.feedback)
                                                .font(.body)
                                                .foregroundColor(.gray)
                                                .lineSpacing(4)
                                        }
                                    }
                                    .padding()
                                    .background(Color(red: 0.1, green: 0.1, blue: 0.15))
                                    .cornerRadius(12)
                                }
                                
                                // Delete Button
                                Button(action: {
                                    showingDeleteAlert = true
                                }) {
                                    HStack {
                                        Image(systemName: "trash.circle.fill")
                                            .font(.title2)
                                        Text("Delete Analysis")
                                            .font(.headline)
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.red)
                                    .cornerRadius(12)
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
        }
        .onAppear {
            // Debug: Print analysis data
            print("VideoAnalysisDetailView appeared")
            print("Analysis ID: \(analysis.id)")
            print("Exercise Type: \(analysis.exerciseType)")
            print("Form Rating: \(analysis.formRating)")
            print("Confidence Score: \(analysis.confidenceScore)")
            print("Analysis Result: \(analysis.analysisResult)")
            print("Parsed Result: \(analysis.parsedAnalysisResult ?? [:])")
            
            // Always show the view after a short delay to prevent black screen
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                isViewReady = true
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
        .alert("Delete Analysis", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteVideoAnalysis()
            }
        } message: {
            Text("Are you sure you want to delete this video analysis? This action cannot be undone.")
        }
    }
    
    func deleteVideoAnalysis() {
        guard let token = authManager.authToken else {
            print("No authentication available")
            return
        }
        
        let url = URL(string: "https://flash-list.com/videos/\(analysis.id)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Delete error: \(error)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        print("Video analysis deleted successfully")
                        onDelete() // Callback to refresh the main view
                        dismiss() // Close the detail view
                    } else {
                        print("Delete failed with status: \(httpResponse.statusCode)")
                        if let data = data {
                            print("Error response: \(String(data: data, encoding: .utf8) ?? "")")
                        }
                    }
                }
            }
        }.resume()
    }
    
    var formRatingColor: Color {
        switch analysis.formRating.lowercased() {
        case "excellent": return .green
        case "good": return .blue
        case "fair": return .orange
        case "poor": return .red
        default: return .gray
        }
    }
}

#Preview {
    VideoAnalysisView()
} 
 