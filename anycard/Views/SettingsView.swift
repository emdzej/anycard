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
    
    var localizedName: String {
        switch self {
        case .grid: return String(localized: "layout.grid")
        case .stack: return String(localized: "layout.stack")
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
                    Picker(String(localized: "settings.cardLayout"), selection: $cardLayout) {
                        ForEach(CardLayout.allCases) { layout in
                            Label(layout.localizedName, systemImage: layout.icon)
                                .tag(layout)
                        }
                    }
                } header: {
                    Text(String(localized: "settings.appearance"))
                } footer: {
                    Text(String(localized: "settings.cardLayout.footer"))
                }
                
                Section {
                    Button {
                        exportAllCards()
                    } label: {
                        Label(String(localized: "settings.export"), systemImage: "square.and.arrow.up")
                    }
                    .disabled(cards.isEmpty)
                    
                    Button {
                        showImporter = true
                    } label: {
                        Label(String(localized: "settings.import"), systemImage: "square.and.arrow.down")
                    }
                } header: {
                    Text(String(localized: "settings.backup"))
                } footer: {
                    Text(String(localized: "settings.backup.footer"))
                }
                
                Section {
                    HStack {
                        Text(String(localized: "settings.cards"))
                        Spacer()
                        Text("\(cards.count)")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text(String(localized: "settings.version"))
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text(String(localized: "settings.info"))
                }
            }
            .navigationTitle(String(localized: "settings.title"))
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
            .alert(String(localized: "import.complete"), isPresented: $showImportAlert) {
                Button(String(localized: "button.ok"), role: .cancel) {}
            } message: {
                if let result = importResult {
                    let importedText = String(localized: "import.result")
                        .replacingOccurrences(of: "%d", with: "\(result.imported)")
                    let skippedText = result.skipped > 0 
                        ? String(localized: "import.skipped").replacingOccurrences(of: "%d", with: "\(result.skipped)")
                        : ""
                    Text(importedText + skippedText)
                }
            }
            .alert(String(localized: "error.title"), isPresented: $showError) {
                Button(String(localized: "button.ok"), role: .cancel) {}
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
            errorMessage = String(localized: "error.fileAccess")
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
