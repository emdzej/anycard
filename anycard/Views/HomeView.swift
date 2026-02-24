import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Card.updatedAt, order: .reverse) private var cards: [Card]
    
    @AppStorage("cardLayout") private var cardLayout: CardLayout = .grid
    
    @State private var showingAddCard = false
    @State private var showingSettings = false
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationStack {
            Group {
                if cards.isEmpty {
                    emptyState
                } else {
                    switch cardLayout {
                    case .grid:
                        cardGrid
                    case .stack:
                        cardStack
                    }
                }
            }
            .navigationTitle("My Cards")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddCard = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddCard) {
                AddCardView()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }
    
    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Cards", systemImage: "creditcard")
        } description: {
            Text("Add your first loyalty card to get started.")
        } actions: {
            Button("Add Card") {
                showingAddCard = true
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    private var cardGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(cards) { card in
                    NavigationLink(value: card) {
                        CardPreview(card: card, size: .thumbnail)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            deleteCard(card)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .padding()
        }
        .navigationDestination(for: Card.self) { card in
            CardDetailView(card: card)
        }
    }
    
    private var cardStack: some View {
        ScrollView {
            LazyVStack(spacing: -60) {  // Negative spacing for overlap
                ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                    GeometryReader { geo in
                        let minY = geo.frame(in: .named("scroll")).minY
                        let scale = calculateScale(minY: minY)
                        
                        NavigationLink(value: card) {
                            CardPreview(card: card, size: .medium)
                                .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                        }
                        .buttonStyle(.plain)
                        .scaleEffect(scale, anchor: .top)
                        .contextMenu {
                            Button(role: .destructive) {
                                deleteCard(card)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    .frame(height: 175)  // CardPreview medium height
                    .zIndex(Double(cards.count - index))  // First card highest z-index
                }
            }
            .padding()
            .padding(.bottom, 80)  // Extra padding at bottom for last card
        }
        .coordinateSpace(name: "scroll")
        .navigationDestination(for: Card.self) { card in
            CardDetailView(card: card)
        }
    }
    
    /// Calculate scale based on card position - cards near top are larger
    private func calculateScale(minY: CGFloat) -> CGFloat {
        let targetY: CGFloat = 100  // Position where card should be fully scaled
        let maxScale: CGFloat = 1.08
        let minScale: CGFloat = 1.0
        
        // Cards at or above target position get max scale
        if minY <= targetY {
            return maxScale
        }
        
        // Gradually decrease scale as card moves down
        let distance = minY - targetY
        let fadeDistance: CGFloat = 150
        let progress = min(distance / fadeDistance, 1.0)
        
        return maxScale - (progress * (maxScale - minScale))
    }
    
    private func deleteCard(_ card: Card) {
        withAnimation {
            modelContext.delete(card)
        }
    }
}

#Preview("Grid") {
    HomeView()
        .modelContainer(for: Card.self, inMemory: true)
}

#Preview("Stack") {
    HomeView()
        .modelContainer(for: Card.self, inMemory: true)
        .onAppear {
            UserDefaults.standard.set("Stack", forKey: "cardLayout")
        }
}
