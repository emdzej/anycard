import SwiftUI
import SwiftData
import PhotosUI

struct EditCardView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var card: Card
    
    @State private var name: String
    @State private var code: String
    @State private var codeType: CodeType
    @State private var displayMode: DisplayMode
    @State private var notes: String
    @State private var backgroundColor: Color
    @State private var textColor: Color
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var customImage: Data?
    @State private var isProcessingImage = false
    @State private var showCodeTypeInfo = false
    
    init(card: Card) {
        self.card = card
        _name = State(initialValue: card.name)
        _code = State(initialValue: card.code)
        _codeType = State(initialValue: card.codeType)
        _displayMode = State(initialValue: card.displayMode)
        _notes = State(initialValue: card.notes ?? "")
        _backgroundColor = State(initialValue: Color(UIColor(hex: card.backgroundColor) ?? .systemGray6))
        _textColor = State(initialValue: Color(UIColor(hex: card.textColor) ?? .white))
        _customImage = State(initialValue: card.customImage)
    }
    
    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !code.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Live preview
                Section {
                    CardPreview(
                        card: Card(
                            name: name,
                            code: code,
                            codeType: codeType,
                            displayMode: displayMode,
                            backgroundColor: backgroundColor.toHex(),
                            textColor: textColor.toHex(),
                            customImage: customImage
                        ),
                        size: .medium
                    )
                    .frame(maxWidth: .infinity)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
                
                // Card details
                Section("Card Details") {
                    TextField("Card Name", text: $name)
                        .textContentType(.organizationName)
                    
                    TextField("Card number", text: $code)
                        .textContentType(.creditCardNumber)
                        .keyboardType(.asciiCapable)
                    
                    Toggle("Show as barcode", isOn: Binding(
                        get: { displayMode == .barcode },
                        set: { displayMode = $0 ? .barcode : .text }
                    ))
                    
                    if displayMode == .barcode {
                        HStack {
                            Picker("Code Type", selection: $codeType) {
                                ForEach(CodeType.allCases) { type in
                                    Text(type.rawValue).tag(type)
                                }
                            }
                            
                            Button {
                                showCodeTypeInfo = true
                            } label: {
                                Image(systemName: "info.circle")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                // Notes section
                Section("Notes") {
                    TextField("Optional notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                // Colors
                Section("Colors") {
                    ColorPicker("Background", selection: $backgroundColor, supportsOpacity: false)
                    ColorPicker("Text", selection: $textColor, supportsOpacity: false)
                    
                    // Preset themes
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(ColorTheme.allCases) { theme in
                                ThemeButton(theme: theme) {
                                    backgroundColor = theme.background
                                    textColor = theme.text
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
                
                // Custom image
                Section("Custom Image") {
                    if let imageData = customImage, let uiImage = UIImage(data: imageData) {
                        HStack {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            
                            Spacer()
                            
                            Button(role: .destructive) {
                                customImage = nil
                            } label: {
                                Label("Remove", systemImage: "trash")
                            }
                        }
                    }
                    
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Label(customImage == nil ? "Add Image" : "Change Image", systemImage: "photo")
                    }
                    .disabled(isProcessingImage)
                    
                    if isProcessingImage {
                        HStack {
                            ProgressView()
                            Text("Processing...")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Edit Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(!isValid)
                }
            }
            .onChange(of: selectedPhoto) { _, newValue in
                if let item = newValue {
                    processSelectedPhoto(item)
                }
            }
            .sheet(isPresented: $showCodeTypeInfo) {
                CodeTypeInfoView()
            }
        }
    }
    
    private func saveChanges() {
        card.name = name.trimmingCharacters(in: .whitespaces)
        card.code = code.trimmingCharacters(in: .whitespaces)
        card.codeType = codeType
        card.displayMode = displayMode
        card.notes = notes.trimmingCharacters(in: .whitespaces).isEmpty ? nil : notes.trimmingCharacters(in: .whitespaces)
        card.backgroundColor = backgroundColor.toHex()
        card.textColor = textColor.toHex()
        card.customImage = customImage
        card.updatedAt = Date()
        dismiss()
    }
    
    private func processSelectedPhoto(_ item: PhotosPickerItem) {
        isProcessingImage = true
        selectedPhoto = nil
        
        Task {
            do {
                guard let data = try await item.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) else {
                    isProcessingImage = false
                    return
                }
                
                // Resize and compress
                let resized = image.resized(toMaxDimension: 512)
                let compressed = resized.jpegData(compressionQuality: 0.8)
                
                await MainActor.run {
                    customImage = compressed
                    isProcessingImage = false
                }
            } catch {
                await MainActor.run {
                    isProcessingImage = false
                }
            }
        }
    }
}

// MARK: - Color Themes

enum ColorTheme: String, CaseIterable, Identifiable {
    case dark = "Dark"
    case light = "Light"
    case blue = "Blue"
    case green = "Green"
    case purple = "Purple"
    case orange = "Orange"
    
    var id: String { rawValue }
    
    var background: Color {
        switch self {
        case .dark: return Color(hex: "#1C1C1E")
        case .light: return Color(hex: "#F2F2F7")
        case .blue: return Color(hex: "#007AFF")
        case .green: return Color(hex: "#34C759")
        case .purple: return Color(hex: "#AF52DE")
        case .orange: return Color(hex: "#FF9500")
        }
    }
    
    var text: Color {
        switch self {
        case .dark, .blue, .green, .purple, .orange: return .white
        case .light: return Color(hex: "#1C1C1E")
        }
    }
}

struct ThemeButton: View {
    let theme: ColorTheme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Circle()
                    .fill(theme.background)
                    .frame(width: 40, height: 40)
                    .overlay {
                        Circle()
                            .strokeBorder(.secondary.opacity(0.3), lineWidth: 1)
                    }
                Text(theme.rawValue)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Color Extensions

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1
        )
    }
    
    func toHex() -> String {
        guard let components = UIColor(self).cgColor.components else {
            return "#000000"
        }
        
        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)
        
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

// MARK: - UIImage Extension

extension UIImage {
    func resized(toMaxDimension maxDimension: CGFloat) -> UIImage {
        let aspectRatio = size.width / size.height
        var newSize: CGSize
        
        if size.width > size.height {
            newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
        } else {
            newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
        }
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

#Preview {
    EditCardView(card: Card(name: "IKEA Family", code: "1234567890123", codeType: .ean13))
}
