import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Card.createdAt, order: .reverse) private var cards: [Card]
    
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
            LazyVStack(spacing: -70) {  // Negative spacing for overlap
                ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                    NavigationLink(value: card) {
                        CardPreview(card: card, size: .large)
                            .frame(maxWidth: .infinity)
                            .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                    }
                    .buttonStyle(.plain)
                    .zIndex(Double(index))  // Last cards have higher z-index (names visible)
                    .contextMenu {
                        Button(role: .destructive) {
                            deleteCard(card)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical)
            .padding(.bottom, 80)  // Extra padding at bottom for last card
        }
        .navigationDestination(for: Card.self) { card in
            CardDetailView(card: card)
        }
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
