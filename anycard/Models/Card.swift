import Foundation
import SwiftData
import UIKit

/// Display mode for card number
enum DisplayMode: String, Codable, CaseIterable, Identifiable {
    case barcode = "Barcode/QR"
    case text = "Text only"
    
    var id: String { rawValue }
}

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
    
    /// Check if a code string is compatible with this code type
    func isCompatible(with code: String) -> Bool {
        let trimmed = code.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return true }  // Empty is always OK (not validating yet)
        
        switch self {
        case .ean13:
            // EAN-13: exactly 13 digits (or 12 digits, checksum will be added)
            let digitsOnly = trimmed.filter { $0.isNumber }
            return digitsOnly.count == trimmed.count && (trimmed.count == 12 || trimmed.count == 13)
            
        case .code128:
            // Code 128: ASCII printable characters (32-126)
            return trimmed.allSatisfy { char in
                guard let ascii = char.asciiValue else { return false }
                return ascii >= 32 && ascii <= 126
            }
            
        case .qrCode, .pdf417, .aztec:
            // 2D codes accept virtually anything
            return true
        }
    }
    
    /// Returns compatible code types for a given code string
    static func compatibleTypes(for code: String) -> [CodeType] {
        allCases.filter { $0.isCompatible(with: code) }
    }
}

/// Loyalty card model
@Model
final class Card {
    var id: UUID
    var name: String
    var code: String
    var codeType: CodeType
    var displayMode: DisplayMode
    var notes: String?
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
        displayMode: DisplayMode = .barcode,
        notes: String? = nil,
        backgroundColor: String = "#1C1C1E",
        textColor: String = "#FFFFFF",
        customImage: Data? = nil
    ) {
        self.id = id
        self.name = name
        self.code = code
        self.codeType = codeType
        self.displayMode = displayMode
        self.notes = notes
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
