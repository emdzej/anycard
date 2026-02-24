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
        case .thumbnail: return 0
        case .medium: return 70
        case .large: return 100
        case .fullscreen: return 130
        }
    }
    
    var titleFontSize: CGFloat {
        switch self {
        case .thumbnail: return 14
        case .medium: return 14
        case .large: return 16
        case .fullscreen: return 18
        }
    }
    
    var codeFontSize: CGFloat {
        switch self {
        case .thumbnail: return 12
        case .medium: return 12
        case .large: return 14
        case .fullscreen: return 16
        }
    }
    
    var textOnlyCodeFontSize: CGFloat {
        switch self {
        case .thumbnail: return 16
        case .medium: return 28
        case .large: return 34
        case .fullscreen: return 40
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
    var forceShowBarcode: Bool = false
    
    private var isTextOnlyMode: Bool {
        card.displayMode == .text && !forceShowBarcode
    }
    
    var body: some View {
        Group {
            if isTextOnlyMode && size.showCode {
                textOnlyLayout
            } else {
                barcodeLayout
            }
        }
        .frame(width: size.width, height: size.height)
        .background {
            if let imageData = card.customImage, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .overlay {
                        Color.black.opacity(0.4)
                    }
            } else {
                Color(card.backgroundUIColor)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
    }
    
    // MARK: - Text Only Layout (centered, large font)
    
    private var textOnlyLayout: some View {
        VStack(spacing: 12) {
            Text(card.name)
                .font(.system(size: size.titleFontSize, weight: .semibold))
                .foregroundStyle(Color(card.textUIColor))
                .lineLimit(1)
            
            Spacer()
            
            Text(card.code)
                .font(.system(size: size.textOnlyCodeFontSize, weight: .bold, design: .monospaced))
                .foregroundStyle(Color(card.textUIColor))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            
            Spacer()
        }
        .padding(16)
    }
    
    // MARK: - Barcode Layout
    
    private var barcodeLayout: some View {
        VStack(spacing: size == .thumbnail ? 0 : 8) {
            Text(card.name)
                .font(.system(size: size.titleFontSize, weight: .semibold))
                .foregroundStyle(Color(card.textUIColor))
                .lineLimit(size == .thumbnail ? 2 : 1)
                .multilineTextAlignment(.center)
            
            if size.showBarcode {
                Spacer()
                
                BarcodeView(code: card.code, type: card.codeType)
                    .frame(height: size.barcodeHeight)
                
                if size.showCode {
                    Text(card.code)
                        .font(.system(size: size.codeFontSize, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color(card.textUIColor))
                        .lineLimit(1)
                }
            }
        }
        .padding(size == .thumbnail ? 16 : 12)
    }
}

#Preview("Thumbnail") {
    CardPreview(
        card: Card(name: "IKEA Family", code: "1234567890123", codeType: .code128),
        size: .thumbnail
    )
    .padding()
}

#Preview("Medium - Barcode") {
    CardPreview(
        card: Card(name: "IKEA Family", code: "1234567890123", codeType: .qrCode, displayMode: .barcode),
        size: .medium
    )
    .padding()
}

#Preview("Medium - Text Only") {
    CardPreview(
        card: Card(name: "IKEA Family", code: "1234567890123", codeType: .code128, displayMode: .text),
        size: .medium
    )
    .padding()
}

#Preview("Large - Text Only") {
    CardPreview(
        card: Card(name: "Lidl Plus", code: "9876543210", codeType: .code128, displayMode: .text),
        size: .large
    )
    .padding()
}

#Preview("Fullscreen - Text Only") {
    CardPreview(
        card: Card(name: "Biedronka", code: "5901234567890", codeType: .ean13, displayMode: .text),
        size: .fullscreen
    )
    .padding()
}
