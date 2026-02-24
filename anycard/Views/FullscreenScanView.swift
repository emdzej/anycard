import SwiftUI

struct FullscreenScanView: View {
    let card: Card
    let onDismiss: () -> Void
    
    @State private var originalBrightness: CGFloat = 0.5
    
    var body: some View {
        ZStack {
            // Dark overlay
            Color.black.opacity(0.85)
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                // Card with large barcode
                CardPreview(card: card, size: .fullscreen, forceShowBarcode: true)
                
                Spacer()
                
                // Hint
                Text("Tap anywhere to close")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.bottom, 40)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onDismiss()
        }
        .onAppear {
            // Save current brightness and set to max
            originalBrightness = UIScreen.main.brightness
            UIScreen.main.brightness = 1.0
        }
        .onDisappear {
            // Restore original brightness
            UIScreen.main.brightness = originalBrightness
        }
    }
}

#Preview {
    FullscreenScanView(
        card: Card(name: "IKEA Family", code: "1234567890123", codeType: .code128)
    ) {
        print("Dismissed")
    }
}
