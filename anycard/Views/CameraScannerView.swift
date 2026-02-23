import SwiftUI
import AVFoundation

struct CameraScannerView: View {
    @Environment(\.dismiss) private var dismiss
    
    let onScan: (String, CodeType) -> Void
    
    @State private var hasPermission = false
    @State private var isFlashlightOn = false
    @State private var showPermissionAlert = false
    
    var body: some View {
        ZStack {
            if hasPermission {
                CameraPreviewView(onScan: handleScan, isFlashlightOn: $isFlashlightOn)
                    .ignoresSafeArea()
                
                // Overlay
                scannerOverlay
            } else {
                permissionDeniedView
            }
        }
        .task {
            hasPermission = await CameraScannerService.checkPermission()
            if !hasPermission {
                showPermissionAlert = true
            }
        }
        .alert("Camera Access Required", isPresented: $showPermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {
                dismiss()
            }
        } message: {
            Text("Please allow camera access in Settings to scan barcodes.")
        }
    }
    
    private var scannerOverlay: some View {
        VStack {
            // Top bar
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .padding()
                        .background(.ultraThinMaterial, in: Circle())
                }
                
                Spacer()
                
                Button {
                    isFlashlightOn.toggle()
                } label: {
                    Image(systemName: isFlashlightOn ? "flashlight.on.fill" : "flashlight.off.fill")
                        .font(.title2)
                        .foregroundStyle(isFlashlightOn ? .yellow : .white)
                        .padding()
                        .background(.ultraThinMaterial, in: Circle())
                }
            }
            .padding()
            
            Spacer()
            
            // Scanning frame
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white, lineWidth: 3)
                .frame(width: 280, height: 180)
                .overlay(alignment: .topLeading) {
                    cornerBracket(rotation: 0)
                }
                .overlay(alignment: .topTrailing) {
                    cornerBracket(rotation: 90)
                }
                .overlay(alignment: .bottomTrailing) {
                    cornerBracket(rotation: 180)
                }
                .overlay(alignment: .bottomLeading) {
                    cornerBracket(rotation: 270)
                }
            
            Spacer()
            
            // Instructions
            Text("Position barcode within frame")
                .font(.headline)
                .foregroundStyle(.white)
                .padding()
                .background(.ultraThinMaterial, in: Capsule())
                .padding(.bottom, 50)
        }
    }
    
    private func cornerBracket(rotation: Double) -> some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 25))
            path.addLine(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 25, y: 0))
        }
        .stroke(.white, style: StrokeStyle(lineWidth: 4, lineCap: .round))
        .frame(width: 25, height: 25)
        .rotationEffect(.degrees(rotation))
        .padding(8)
    }
    
    private var permissionDeniedView: some View {
        ContentUnavailableView {
            Label("Camera Access Required", systemImage: "camera.fill")
        } description: {
            Text("Allow camera access to scan barcodes from your loyalty cards.")
        } actions: {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    private func handleScan(code: String, type: CodeType) {
        onScan(code, type)
        dismiss()
    }
}

// MARK: - Camera Preview UIViewRepresentable

struct CameraPreviewView: UIViewRepresentable {
    let onScan: (String, CodeType) -> Void
    @Binding var isFlashlightOn: Bool
    
    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.delegate = context.coordinator
        return view
    }
    
    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        if isFlashlightOn != uiView.isFlashlightOn {
            uiView.setFlashlight(isFlashlightOn)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onScan: onScan)
    }
    
    class Coordinator: NSObject, BarcodeScannerDelegate {
        let onScan: (String, CodeType) -> Void
        
        init(onScan: @escaping (String, CodeType) -> Void) {
            self.onScan = onScan
        }
        
        func barcodeScanner(_ scanner: CameraScannerService, didScan code: String, type: CodeType) {
            onScan(code, type)
        }
        
        func barcodeScanner(_ scanner: CameraScannerService, didFailWithError error: Error) {
            print("Scanner error: \(error)")
        }
    }
}

class CameraPreviewUIView: UIView {
    weak var delegate: BarcodeScannerDelegate? {
        didSet {
            scannerService.delegate = delegate
        }
    }
    
    private let scannerService = CameraScannerService()
    private(set) var isFlashlightOn = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCamera()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.sublayers?.first?.frame = bounds
    }
    
    private func setupCamera() {
        let previewLayer = scannerService.createPreviewLayer(for: self)
        layer.addSublayer(previewLayer)
        scannerService.start()
    }
    
    func setFlashlight(_ on: Bool) {
        isFlashlightOn = scannerService.toggleFlashlight()
    }
    
    deinit {
        scannerService.stop()
    }
}

#Preview {
    CameraScannerView { code, type in
        print("Scanned: \(code) (\(type))")
    }
}
