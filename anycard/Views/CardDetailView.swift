import SwiftUI

struct CardDetailView: View {
    @Bindable var card: Card
    @State private var showEditSheet = false
    @State private var showFullscreen = false
    @State private var detailsExpanded = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Card preview - tappable for fullscreen
                CardPreview(card: card, size: .large)
                    .onTapGesture {
                        if card.displayMode == .barcode {
                            showFullscreen = true
                        }
                    }
                    .overlay(alignment: .topTrailing) {
                        if card.displayMode == .barcode {
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.7))
                                .padding(8)
                        }
                    }
                
                // Collapsible details
                DisclosureGroup(isExpanded: $detailsExpanded) {
                    VStack(alignment: .leading, spacing: 12) {
                        DetailRow(title: "Card number", value: card.code)
                        DetailRow(title: "Code type", value: card.codeType.rawValue)
                        DetailRow(title: "Display mode", value: card.displayMode.rawValue)
                        DetailRow(title: "Added", value: card.createdAt.formatted(date: .abbreviated, time: .shortened))
                        if card.updatedAt != card.createdAt {
                            DetailRow(title: "Modified", value: card.updatedAt.formatted(date: .abbreviated, time: .shortened))
                        }
                    }
                    .padding(.top, 8)
                } label: {
                    Text("Card Details")
                        .font(.headline)
                }
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Notes section
                if let notes = card.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.headline)
                        Text(notes)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                // Placeholder for "Add to Wallet" button
                Button {
                    // TODO: Implement when Developer Account is available
                } label: {
                    Label("Add to Apple Wallet", systemImage: "wallet.pass")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(true)
                
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
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showEditSheet = true
                } label: {
                    Text("Edit")
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            EditCardView(card: card)
        }
        .fullScreenCover(isPresented: $showFullscreen) {
            FullscreenScanView(card: card) {
                showFullscreen = false
            }
        }
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
        CardDetailView(card: Card(
            name: "IKEA Family",
            code: "1234567890123",
            codeType: .ean13,
            notes: "VIP member since 2024\nExpires: December 2025"
        ))
    }
}
