import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

/// Service for generating barcode/QR code images
final class BarcodeGenerator {
    static let shared = BarcodeGenerator()
    
    private let context = CIContext()
    
    private init() {}
    
    /// Generate a barcode or QR code image
    /// - Parameters:
    ///   - code: The string to encode
    ///   - type: The type of code to generate
    ///   - size: Optional target size (defaults based on code type)
    /// - Returns: Generated UIImage or nil if generation fails
    func generate(code: String, type: CodeType, size: CGSize? = nil) -> UIImage? {
        guard let filter = CIFilter(name: type.ciFilterName) else {
            return nil
        }
        
        // Prepare input data
        guard let data = prepareData(code: code, type: type) else {
            return nil
        }
        
        // Configure filter
        filter.setValue(data, forKey: "inputMessage")
        
        // Additional configuration for specific types
        configureFilter(filter, type: type)
        
        // Get output image
        guard let outputImage = filter.outputImage else {
            return nil
        }
        
        // Scale the image
        let targetSize = size ?? defaultSize(for: type)
        let scaledImage = scaleImage(outputImage, to: targetSize, is2D: type.is2D)
        
        // Convert to UIImage
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    // MARK: - Private Helpers
    
    private func prepareData(code: String, type: CodeType) -> Data? {
        switch type {
        case .qrCode, .pdf417, .aztec:
            // These support UTF-8
            return code.data(using: .utf8)
        case .code128, .ean13:
            // These use ASCII/ISO-8859-1
            return code.data(using: .isoLatin1)
        }
    }
    
    private func configureFilter(_ filter: CIFilter, type: CodeType) {
        switch type {
        case .qrCode:
            // L = 7%, M = 15%, Q = 25%, H = 30% error correction
            filter.setValue("M", forKey: "inputCorrectionLevel")
        case .aztec:
            // Compact vs full-range mode
            filter.setValue(23.0, forKey: "inputCorrectionLevel")
        case .pdf417:
            // Configure PDF417 specific options if needed
            break
        case .code128, .ean13:
            // No additional configuration needed
            break
        }
    }
    
    private func defaultSize(for type: CodeType) -> CGSize {
        switch type {
        case .code128, .ean13:
            return CGSize(width: 300, height: 100)
        case .qrCode, .aztec:
            return CGSize(width: 200, height: 200)
        case .pdf417:
            return CGSize(width: 300, height: 150)
        }
    }
    
    private func scaleImage(_ image: CIImage, to targetSize: CGSize, is2D: Bool) -> CIImage {
        let scaleX = targetSize.width / image.extent.width
        let scaleY = targetSize.height / image.extent.height
        
        // For 2D codes, use uniform scaling to maintain aspect ratio
        let scale = is2D ? min(scaleX, scaleY) : max(scaleX, scaleY)
        
        // Use nearest neighbor interpolation to keep barcode sharp
        return image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
    }
}
