import SwiftUI

struct CardDetailView: View {
    let card: Card
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                CardPreview(card: card, size: .large)
                
                VStack(alignment: .leading, spacing: 16) {
                    DetailRow(title: "Card Name", value: card.name)
                    DetailRow(title: "Code", value: card.code)
                    DetailRow(title: "Code Type", value: card.codeType.rawValue)
                    DetailRow(title: "Added", value: card.createdAt.formatted(date: .abbreviated, time: .shortened))
                }
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                
                // Placeholder for "Add to Wallet" button
                Button {
                    // TODO: Implement when Developer Account is available
                } label: {
                    Label("Add to Apple Wallet", systemImage: "wallet.pass")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(true) // Disabled until PassKit signing is available
                
                Text("Apple Wallet integration requires Apple Developer Program membership.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(card.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body)
        }
    }
}

#Preview {
    NavigationStack {
        CardDetailView(card: Card(name: "IKEA Family", code: "1234567890123", codeType: .ean13))
    }
}
