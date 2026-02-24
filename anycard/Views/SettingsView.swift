import SwiftUI
import SwiftData
import UniformTypeIdentifiers

/// Card layout style on home screen
enum CardLayout: String, CaseIterable, Identifiable, RawRepresentable {
    case grid = "Grid"
    case stack = "Stack"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .grid: return "square.grid.2x2"
        case .stack: return "rectangle.stack"
        }
    }
}

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var cards: [Card]
    
    @AppStorage("cardLayout") private var cardLayout: CardLayout = .grid
    
    @State private var showExporter = false
    @State private var showImporter = false
    @State private var exportData: Data?
    @State private var showImportAlert = false
    @State private var importResult: ImportResult?
    @State private var showError = false
    @State private var errorMessage = ""
    
    private let exportService = CardExportService()
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Card Layout", selection: $cardLayout) {
                        ForEach(CardLayout.allCases) { layout in
                            Label(layout.rawValue, systemImage: layout.icon)
                                .tag(layout)
                        }
                    }
                } header: {
                    Text("Appearance")
                } footer: {
                    Text("Grid shows cards in a 2-column layout. Stack shows cards overlapping like Apple Wallet.")
                }
                
                Section {
                    Button {
                        exportAllCards()
                    } label: {
                        Label("Export All Cards", systemImage: "square.and.arrow.up")
                    }
                    .disabled(cards.isEmpty)
                    
                    Button {
                        showImporter = true
                    } label: {
                        Label("Import Cards", systemImage: "square.and.arrow.down")
                    }
                } header: {
                    Text("Backup & Restore")
                } footer: {
                    Text("Export creates a .anycard file you can use to backup or transfer your cards.")
                }
                
                Section {
                    HStack {
                        Text("Cards")
                        Spacer()
                        Text("\(cards.count)")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Info")
                }
            }
            .navigationTitle("Settings")
            .fileExporter(
                isPresented: $showExporter,
                document: AnycardDocument(data: exportData ?? Data()),
                contentType: .anycard,
                defaultFilename: exportService.generateFilename()
            ) { result in
                switch result {
                case .success:
                    break // Success
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
            .fileImporter(
                isPresented: $showImporter,
                allowedContentTypes: [.anycard, .json],
                allowsMultipleSelection: false
            ) { result in
                handleImport(result)
            }
            .alert("Import Complete", isPresented: $showImportAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                if let result = importResult {
                    Text("Imported \(result.imported) cards.\(result.skipped > 0 ? " Skipped \(result.skipped) duplicates." : "")")
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func exportAllCards() {
        do {
            exportData = try exportService.export(cards: Array(cards))
            showExporter = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            importFromURL(url)
        case .failure(let error):
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func importFromURL(_ url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            errorMessage = "Cannot access file"
            showError = true
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        do {
            let data = try Data(contentsOf: url)
            let importedCards = try exportService.importCards(from: data)
            
            // Check for duplicates
            let existingCodes = Set(cards.map { $0.code })
            var imported = 0
            var skipped = 0
            
            for card in importedCards {
                if existingCodes.contains(card.code) {
                    skipped += 1
                } else {
                    modelContext.insert(card)
                    imported += 1
                }
            }
            
            importResult = ImportResult(imported: imported, skipped: skipped)
            showImportAlert = true
            
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

struct ImportResult {
    let imported: Int
    let skipped: Int
}

// MARK: - Document for FileExporter

struct AnycardDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.anycard, .json] }
    
    let data: Data
    
    init(data: Data) {
        self.data = data
    }
    
    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: Card.self, inMemory: true)
}
