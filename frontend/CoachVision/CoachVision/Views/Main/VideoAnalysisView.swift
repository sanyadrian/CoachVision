import SwiftUI
import AVFoundation
import Photos

struct VideoAnalysisView: View {
    @StateObject private var cameraManager = CameraManager()
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var recordedVideoURL: URL?
    @State private var isRecording = false
    @State private var showingVideoPlayer = false
    
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
                            
                            Button("Play Video") {
                                showingVideoPlayer = true
                            }
                            .foregroundColor(.blue)
                            .font(.subheadline)
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
    }
}

// Camera Preview View
struct CameraPreviewView: UIViewRepresentable {
    let previewLayer: AVCaptureVideoPreviewLayer
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        previewLayer.frame = uiView.bounds
    }
}

// Camera Manager
class CameraManager: ObservableObject {
    @Published var isCameraAvailable = false
    @Published var recordedVideoURL: URL?
    
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
            
            DispatchQueue.main.async {
                self.captureSession = session
                self.videoOutput = movieOutput
                self.previewLayer = previewLayer
                self.isCameraAvailable = true
                
                session.startRunning()
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

#Preview {
    VideoAnalysisView()
} 