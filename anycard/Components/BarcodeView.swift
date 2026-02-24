import SwiftUI

struct BarcodeView: View {
    let code: String
    let type: CodeType
    
    var body: some View {
        if let image = BarcodeGenerator.shared.generate(code: code, type: type) {
            Image(uiImage: image)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
        } else {
            // Fallback if barcode generation fails
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.3))
                .overlay {
                    Text(String(localized: "barcode.invalid"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
        }
    }
}

#Preview("Code128") {
    BarcodeView(code: "1234567890", type: .code128)
        .frame(width: 200, height: 60)
        .padding()
}

#Preview("QR Code") {
    BarcodeView(code: "https://example.com", type: .qrCode)
        .frame(width: 100, height: 100)
        .padding()
}
