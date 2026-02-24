import SwiftUI

struct CodeTypeInfoView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    CodeTypeRow(
                        name: "Code 128",
                        icon: "barcode",
                        description: String(localized: "codeType.code128.desc"),
                        usage: String(localized: "codeType.code128.usage")
                    )
                    
                    CodeTypeRow(
                        name: "EAN-13",
                        icon: "barcode",
                        description: String(localized: "codeType.ean13.desc"),
                        usage: String(localized: "codeType.ean13.usage")
                    )
                } header: {
                    Text(String(localized: "codeType.1d"))
                } footer: {
                    Text(String(localized: "codeType.1d.footer"))
                }
                
                Section {
                    CodeTypeRow(
                        name: "QR Code",
                        icon: "qrcode",
                        description: String(localized: "codeType.qr.desc"),
                        usage: String(localized: "codeType.qr.usage")
                    )
                    
                    CodeTypeRow(
                        name: "PDF417",
                        icon: "rectangle.split.3x3",
                        description: String(localized: "codeType.pdf417.desc"),
                        usage: String(localized: "codeType.pdf417.usage")
                    )
                    
                    CodeTypeRow(
                        name: "Aztec",
                        icon: "square.grid.3x3.middle.filled",
                        description: String(localized: "codeType.aztec.desc"),
                        usage: String(localized: "codeType.aztec.usage")
                    )
                } header: {
                    Text(String(localized: "codeType.2d"))
                } footer: {
                    Text(String(localized: "codeType.2d.footer"))
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label(String(localized: "codeType.tip.title"), systemImage: "lightbulb.fill")
                            .font(.headline)
                            .foregroundStyle(.yellow)
                        
                        Text(String(localized: "codeType.tip.text"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle(String(localized: "codeType.info.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "button.done")) {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct CodeTypeRow: View {
    let name: String
    let icon: String
    let description: String
    let usage: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.tint)
                    .frame(width: 30)
                
                Text(name)
                    .font(.headline)
            }
            
            Text(description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 4) {
                Text(String(localized: "codeType.common"))
                    .font(.caption)
                    .fontWeight(.medium)
                Text(usage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    CodeTypeInfoView()
}
