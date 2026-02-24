import SwiftUI

enum CardPreviewSize {
    case thumbnail
    case medium
    case large
    case fullscreen
    
    var width: CGFloat {
        switch self {
        case .thumbnail: return 160
        case .medium: return 280
        case .large: return 340
        case .fullscreen: return 340
        }
    }
    
    var height: CGFloat {
        switch self {
        case .thumbnail: return 100
        case .medium: return 175
        case .large: return 220
        case .fullscreen: return 260
        }
    }
    
    var barcodeHeight: CGFloat {
        switch self {
        case .thumbnail: return 0  // No barcode in thumbnail
        case .medium: return 70
        case .large: return 100
        case .fullscreen: return 130
        }
    }
    
    var fontSize: CGFloat {
        switch self {
        case .thumbnail: return 14
        case .medium: return 14
        case .large: return 16
        case .fullscreen: return 18
        }
    }
    
    var showBarcode: Bool {
        self != .thumbnail
    }
    
    var showCode: Bool {
        self != .thumbnail
    }
}

struct CardPreview: View {
    let card: Card
    let size: CardPreviewSize
    var forceShowBarcode: Bool = false  // For fullscreen mode
    
    var body: some View {
        VStack(spacing: size == .thumbnail ? 0 : 8) {
            // Card name
            Text(card.name)
                .font(.system(size: size.fontSize, weight: .semibold))
                .foregroundStyle(Color(card.textUIColor))
                .lineLimit(size == .thumbnail ? 2 : 1)
                .multilineTextAlignment(.center)
            
            if size.showBarcode {
                Spacer()
                
                // Barcode/QR or text based on displayMode
                if card.displayMode == .barcode || forceShowBarcode {
                    BarcodeView(code: card.code, type: card.codeType)
                        .frame(height: size.barcodeHeight)
                }
                
                // Code text
                if size.showCode {
                    Text(card.code)
                        .font(.system(size: size.fontSize - 2, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color(card.textUIColor))
                        .lineLimit(1)
                }
            }
        }
        .padding(size == .thumbnail ? 16 : 12)
        .frame(width: size.width, height: size.height)
        .background {
            // Custom image or solid color
            if let imageData = card.customImage, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .overlay {
                        // Dark overlay for readability
                        Color.black.opacity(0.4)
                    }
            } else {
                Color(card.backgroundUIColor)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
    }
}

#Preview("Thumbnail") {
    CardPreview(
        card: Card(name: "IKEA Family", code: "1234567890123", codeType: .code128),
        size: .thumbnail
    )
    .padding()
}

#Preview("Medium") {
    CardPreview(
        card: Card(name: "IKEA Family", code: "1234567890123", codeType: .qrCode),
        size: .medium
    )
    .padding()
}

#Preview("Large") {
    CardPreview(
        card: Card(name: "Lidl Plus", code: "9876543210", codeType: .code128),
        size: .large
    )
    .padding()
}

#Preview("Fullscreen") {
    CardPreview(
        card: Card(name: "Biedronka", code: "5901234567890", codeType: .ean13),
        size: .fullscreen
    )
    .padding()
}
