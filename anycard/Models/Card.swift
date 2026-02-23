import Foundation
import SwiftData
import UIKit

/// Supported barcode/QR code types
enum CodeType: String, Codable, CaseIterable, Identifiable {
    case code128 = "Code 128"
    case ean13 = "EAN-13"
    case qrCode = "QR Code"
    case pdf417 = "PDF417"
    case aztec = "Aztec"
    
    var id: String { rawValue }
    
    /// CoreImage filter name for this code type
    var ciFilterName: String {
        switch self {
        case .code128: return "CICode128BarcodeGenerator"
        case .ean13: return "CIEAN13BarcodeGenerator"
        case .qrCode: return "CIQRCodeGenerator"
        case .pdf417: return "CIPDF417BarcodeGenerator"
        case .aztec: return "CIAztecCodeGenerator"
        }
    }
    
    /// Whether this is a 2D code (QR, Aztec, PDF417) vs 1D barcode
    var is2D: Bool {
        switch self {
        case .code128, .ean13: return false
        case .qrCode, .pdf417, .aztec: return true
        }
    }
}

/// Loyalty card model
@Model
final class Card {
    var id: UUID
    var name: String
    var code: String
    var codeType: CodeType
    var backgroundColor: String  // hex color
    var textColor: String        // hex color
    @Attribute(.externalStorage) var customImage: Data?
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        code: String,
        codeType: CodeType = .code128,
        backgroundColor: String = "#1C1C1E",
        textColor: String = "#FFFFFF",
        customImage: Data? = nil
    ) {
        self.id = id
        self.name = name
        self.code = code
        self.codeType = codeType
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.customImage = customImage
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Color Helpers

extension Card {
    var backgroundUIColor: UIColor {
        UIColor(hex: backgroundColor) ?? .systemGray6
    }
    
    var textUIColor: UIColor {
        UIColor(hex: textColor) ?? .white
    }
}

extension UIColor {
    convenience init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgb & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}
