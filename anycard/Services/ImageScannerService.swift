import UIKit
import Vision

/// Result of image barcode scanning
struct ImageScanResult {
    let code: String
    let type: CodeType
}

/// Service for scanning barcodes from images using Vision framework
final class ImageScannerService {
    
    enum ScanError: LocalizedError {
        case noBarcodesFound
        case imageProcessingFailed
        
        var errorDescription: String? {
            switch self {
            case .noBarcodesFound:
                return "No barcodes found in image"
            case .imageProcessingFailed:
                return "Failed to process image"
            }
        }
    }
    
    /// Scan barcode from UIImage
    /// - Parameter image: Image to scan
    /// - Returns: Scan result with code and type
    func scan(image: UIImage) async throws -> ImageScanResult {
        guard let cgImage = image.cgImage else {
            throw ScanError.imageProcessingFailed
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNDetectBarcodesRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let results = request.results as? [VNBarcodeObservation],
                      let firstBarcode = results.first,
                      let payload = firstBarcode.payloadStringValue else {
                    continuation.resume(throwing: ScanError.noBarcodesFound)
                    return
                }
                
                let codeType = self.mapToCodeType(firstBarcode.symbology)
                let result = ImageScanResult(code: payload, type: codeType)
                continuation.resume(returning: result)
            }
            
            // Configure supported symbologies
            request.symbologies = [
                .code128,
                .ean13,
                .ean8,
                .upce,
                .qr,
                .pdf417,
                .aztec,
                .dataMatrix
            ]
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    /// Scan barcode from image Data
    func scan(imageData: Data) async throws -> ImageScanResult {
        guard let image = UIImage(data: imageData) else {
            throw ScanError.imageProcessingFailed
        }
        return try await scan(image: image)
    }
    
    // MARK: - Private
    
    private func mapToCodeType(_ symbology: VNBarcodeSymbology) -> CodeType {
        switch symbology {
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
