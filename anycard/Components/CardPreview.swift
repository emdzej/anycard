import SwiftUI

enum CardPreviewSize {
    case thumbnail
    case medium
    case large
    
    var width: CGFloat {
        switch self {
        case .thumbnail: return 160
        case .medium: return 280
        case .large: return 340
        }
    }
    
    var height: CGFloat {
        switch self {
        case .thumbnail: return 100
        case .medium: return 175
        case .large: return 210
        }
    }
    
    var barcodeHeight: CGFloat {
        switch self {
        case .thumbnail: return 40
        case .medium: return 60
        case .large: return 80
        }
    }
    
    var fontSize: CGFloat {
        switch self {
        case .thumbnail: return 12
        case .medium: return 14
        case .large: return 16
        }
    }
}

struct CardPreview: View {
    let card: Card
    let size: CardPreviewSize
    
    var body: some View {
        VStack(spacing: 8) {
            // Card name
            Text(card.name)
                .font(.system(size: size.fontSize, weight: .semibold))
                .foregroundStyle(Color(card.textUIColor))
                .lineLimit(1)
            
            Spacer()
            
            // Barcode/QR
            BarcodeView(code: card.code, type: card.codeType)
                .frame(height: size.barcodeHeight)
            
            // Code text
            Text(card.code)
                .font(.system(size: size.fontSize - 2, weight: .medium, design: .monospaced))
                .foregroundStyle(Color(card.textUIColor))
                .lineLimit(1)
        }
        .padding(12)
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
