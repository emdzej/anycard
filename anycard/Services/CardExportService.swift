import Foundation

/// Export format for anycard cards
struct CardExport: Codable {
    let version: Int
    let appVersion: String
    let exportedAt: Date
    let cards: [CardData]
    
    init(cards: [Card]) {
        self.version = 1
        self.appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        self.exportedAt = Date()
        self.cards = cards.map { CardData(from: $0) }
    }
}

/// Serializable card data
struct CardData: Codable {
    let id: UUID
    let name: String
    let code: String
    let codeType: String
    let displayMode: String
    let notes: String?
    let backgroundColor: String
    let textColor: String
    let customImage: Data?
    let createdAt: Date
    
    init(from card: Card) {
        self.id = card.id
        self.name = card.name
        self.code = card.code
        self.codeType = card.codeType.rawValue
        self.displayMode = card.displayMode.rawValue
        self.notes = card.notes
        self.backgroundColor = card.backgroundColor
        self.textColor = card.textColor
        self.customImage = card.customImage
        self.createdAt = card.createdAt
    }
    
    func toCard() -> Card {
        let type = CodeType.allCases.first { $0.rawValue == codeType } ?? .code128
        let mode = DisplayMode.allCases.first { $0.rawValue == displayMode } ?? .barcode
        return Card(
            id: id,
            name: name,
            code: code,
            codeType: type,
            displayMode: mode,
            notes: notes,
            backgroundColor: backgroundColor,
            textColor: textColor,
            customImage: customImage
        )
    }
}

/// Service for importing and exporting cards
final class CardExportService {
    
    enum ExportError: LocalizedError {
        case encodingFailed
        case decodingFailed
        case invalidFormat
        case unsupportedVersion(Int)
        
        var errorDescription: String? {
            switch self {
            case .encodingFailed:
                return "Failed to encode cards"
            case .decodingFailed:
                return "Failed to decode cards"
            case .invalidFormat:
                return "Invalid file format"
            case .unsupportedVersion(let version):
                return "Unsupported file version: \(version)"
            }
        }
    }
    
    /// Export cards to JSON data
    func export(cards: [Card]) throws -> Data {
        let export = CardExport(cards: cards)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        guard let data = try? encoder.encode(export) else {
            throw ExportError.encodingFailed
        }
        
        return data
    }
    
    /// Import cards from JSON data
    func importCards(from data: Data) throws -> [Card] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        guard let export = try? decoder.decode(CardExport.self, from: data) else {
            throw ExportError.decodingFailed
        }
        
        // Check version compatibility
        guard export.version == 1 else {
            throw ExportError.unsupportedVersion(export.version)
        }
        
        return export.cards.map { $0.toCard() }
    }
    
    /// Generate filename for export
    func generateFilename() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let timestamp = formatter.string(from: Date())
        return "anycard_backup_\(timestamp).anycard"
    }
}
