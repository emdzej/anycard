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
                        description: "Most versatile 1D barcode. Supports letters, numbers, and symbols.",
                        usage: "General purpose, shipping labels, inventory"
                    )
                    
                    CodeTypeRow(
                        name: "EAN-13",
                        icon: "barcode",
                        description: "13-digit barcode standard used worldwide for retail products.",
                        usage: "European retail, product packaging, loyalty cards"
                    )
                } header: {
                    Text("1D Barcodes")
                } footer: {
                    Text("Linear barcodes that encode data in varying widths of lines.")
                }
                
                Section {
                    CodeTypeRow(
                        name: "QR Code",
                        icon: "qrcode",
                        description: "Square 2D code that can store large amounts of data. Very fast to scan.",
                        usage: "Mobile apps, websites, digital loyalty cards, payments"
                    )
                    
                    CodeTypeRow(
                        name: "PDF417",
                        icon: "rectangle.split.3x3",
                        description: "Stacked 2D barcode that can encode large data. Used in official documents.",
                        usage: "ID cards, driver's licenses, boarding passes"
                    )
                    
                    CodeTypeRow(
                        name: "Aztec",
                        icon: "square.grid.3x3.middle.filled",
                        description: "Compact 2D code that works well even when printed small or damaged.",
                        usage: "Transport tickets, airline boarding passes"
                    )
                } header: {
                    Text("2D Codes")
                } footer: {
                    Text("Two-dimensional codes that store more data and are easier to scan.")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Tip", systemImage: "lightbulb.fill")
                            .font(.headline)
                            .foregroundStyle(.yellow)
                        
                        Text("If you're unsure which type to use, scan your existing card with the camera — the app will detect the correct type automatically.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Code Types")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
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
                    .foregroundStyle(.accent)
                    .frame(width: 30)
                
                Text(name)
                    .font(.headline)
            }
            
            Text(description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 4) {
                Text("Common uses:")
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
