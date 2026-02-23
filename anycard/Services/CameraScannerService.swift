import AVFoundation
import UIKit

/// Delegate for receiving scanned barcode results
protocol BarcodeScannerDelegate: AnyObject {
    func barcodeScanner(_ scanner: CameraScannerService, didScan code: String, type: CodeType)
    func barcodeScanner(_ scanner: CameraScannerService, didFailWithError error: Error)
}

/// Service for scanning barcodes using device camera
final class CameraScannerService: NSObject, @unchecked Sendable {
    weak var delegate: BarcodeScannerDelegate?
    
    private let captureSession = AVCaptureSession()
    private let metadataOutput = AVCaptureMetadataOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    private(set) var isRunning = false
    
    /// Supported barcode types for scanning
    private let supportedTypes: [AVMetadataObject.ObjectType] = [
        .code128,
        .ean13,
        .ean8,
        .upce,
        .qr,
        .pdf417,
        .aztec,
        .dataMatrix
    ]
    
    override init() {
        super.init()
        setupSession()
    }
    
    // MARK: - Setup
    
    private func setupSession() {
        captureSession.beginConfiguration()
        
        // Add video input
        guard let videoDevice = AVCaptureDevice.default(for: .video),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            return
        }
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        }
        
        // Add metadata output
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: .main)
            metadataOutput.metadataObjectTypes = supportedTypes
        }
        
        captureSession.commitConfiguration()
    }
    
    // MARK: - Public API
    
    /// Create preview layer for displaying camera feed
    func createPreviewLayer(for view: UIView) -> AVCaptureVideoPreviewLayer {
        let layer = AVCaptureVideoPreviewLayer(session: captureSession)
        layer.videoGravity = .resizeAspectFill
        layer.frame = view.bounds
        self.previewLayer = layer
        return layer
    }
    
    /// Start scanning
    func start() {
        guard !isRunning else { return }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.startRunning()
            DispatchQueue.main.async {
                self?.isRunning = true
            }
        }
    }
    
    /// Stop scanning
    func stop() {
        guard isRunning else { return }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.stopRunning()
            DispatchQueue.main.async {
                self?.isRunning = false
            }
        }
    }
    
    /// Toggle flashlight
    func toggleFlashlight() -> Bool {
        guard let device = AVCaptureDevice.default(for: .video),
              device.hasTorch else {
            return false
        }
        
        do {
            try device.lockForConfiguration()
            device.torchMode = device.torchMode == .on ? .off : .on
            device.unlockForConfiguration()
            return device.torchMode == .on
        } catch {
            return false
        }
    }
    
    /// Check if camera permission is granted
    static func checkPermission() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
        default:
            return false
        }
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate

extension CameraScannerService: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let stringValue = metadataObject.stringValue else {
            return
        }
        
        // Convert AVMetadataObject.ObjectType to our CodeType
        let codeType = mapToCodeType(metadataObject.type)
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Stop scanning and notify delegate
        stop()
        delegate?.barcodeScanner(self, didScan: stringValue, type: codeType)
    }
    
    private func mapToCodeType(_ avType: AVMetadataObject.ObjectType) -> CodeType {
        switch avType {
        case .code128:
            return .code128
        case .ean13, .ean8, .upce:
            return .ean13
        case .qr:
            return .qrCode
        case .pdf417:
            return .pdf417
        case .aztec:
            return .aztec
        default:
            return .code128
        }
    }
}
