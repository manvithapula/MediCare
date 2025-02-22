import SwiftUI
import AVFoundation
import Vision
import CoreML

struct PillScannerView: View {
    @StateObject private var viewModel = PillScannerViewModel()
    
    var body: some View {
        ZStack {
            // Camera preview
            CameraPreview(session: viewModel.session)
                .ignoresSafeArea()
            
            // Scanning overlay
            VStack {
                Spacer()
                
                // Scanning frame
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(.white, lineWidth: 2)
                    .frame(width: 300, height: 300)
                    .overlay {
                        if viewModel.isScanning {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                        }
                    }
                
                // Results view
                if let result = viewModel.scanResult {
                    PillResultView(result: result)
                        .transition(.move(edge: .bottom))
                }
                
                Spacer()
                
                // Capture button
                Button(action: viewModel.captureImage) {
                    Circle()
                        .fill(.white)
                        .frame(width: 70, height: 70)
                        .overlay {
                            Circle()
                                .stroke(.white.opacity(0.2), lineWidth: 2)
                                .frame(width: 80, height: 80)
                        }
                }
                .disabled(viewModel.isScanning)
                .padding(.bottom, 30)
            }
        }
        .navigationTitle("Pill Scanner")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.checkCameraPermission()
        }
        .alert("Camera Access Required", isPresented: $viewModel.showPermissionAlert) {
            Button("Go to Settings", role: .none) {
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please allow camera access to use the pill scanner")
        }
    }
}

// Camera preview using UIViewRepresentable
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            previewLayer.frame = uiView.bounds
        }
    }
}

// Result view for displaying identified pill information
struct PillResultView: View {
    let result: PillScanResult
    
    var body: some View {
        VStack(spacing: 12) {
            Text(result.name)
                .font(.title2)
                .bold()
            
            Text(result.description)
                .font(.body)
                .multilineTextAlignment(.center)
            
            if let confidence = result.confidence {
                Text("Confidence: \(Int(confidence * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .padding()
    }
}

// View Model for handling camera and ML operations
class PillScannerViewModel: ObservableObject {
    @Published var isScanning = false
    @Published var scanResult: PillScanResult?
    @Published var showPermissionAlert = false
    
    let session = AVCaptureSession()
    private let output = AVCapturePhotoOutput()
    private var model: VNCoreMLModel?
    
    init() {
        setupModel()
    }
    
    private func setupModel() {
        // Load your trained CoreML model here
        do {
            let config = MLModelConfiguration()
            let pillClassifier = try PillClassifier(configuration: config) // Replace with your model name
            model = try VNCoreMLModel(for: pillClassifier.model)
        } catch {
            print("Failed to load model: \(error)")
        }
    }
    
    func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    DispatchQueue.main.async {
                        self?.setupCamera()
                    }
                }
            }
        default:
            showPermissionAlert = true
        }
    }
    
    private func setupCamera() {
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) && session.canAddOutput(output) {
                session.addInput(input)
                session.addOutput(output)
                
                DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                    self?.session.startRunning()
                }
            }
        } catch {
            print("Failed to setup camera: \(error)")
        }
    }
    
    func captureImage() {
        guard !isScanning else { return }
        
        isScanning = true
        
        let settings = AVCapturePhotoSettings()
        output.capturePhoto(with: settings, delegate: self)
    }
    
    private func processImage(_ image: CVPixelBuffer) {
        guard let model = model else {
            isScanning = false
            return
        }
        
        let request = VNCoreMLRequest(model: model) { [weak self] request, error in
            guard let results = request.results as? [VNClassificationObservation],
                  let topResult = results.first else {
                DispatchQueue.main.async {
                    self?.isScanning = false
                }
                return
            }
            
            DispatchQueue.main.async {
                self?.scanResult = PillScanResult(
                    name: topResult.identifier,
                    description: self?.getPillDescription(topResult.identifier) ?? "",
                    confidence: topResult.confidence
                )
                self?.isScanning = false
            }
        }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: image)
        
        do {
            try handler.perform([request])
        } catch {
            print("Failed to process image: \(error)")
            DispatchQueue.main.async {
                self.isScanning = false
            }
        }
    }
    
    private func getPillDescription(_ identifier: String) -> String {
        // Add your pill database/lookup logic here
        // This should return information about the identified pill
        return "Description for \(identifier)"
    }
}

// Conform to photo capture delegate
extension PillScannerViewModel: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Photo capture error: \(error)")
            isScanning = false
            return
        }
        
        guard let pixelBuffer = photo.previewPixelBuffer else {
            isScanning = false
            return
        }
        
        processImage(pixelBuffer)
    }
}

// Result model
struct PillScanResult {
    let name: String
    let description: String
    let confidence: Float?
}
