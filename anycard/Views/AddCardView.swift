import SwiftUI
import SwiftData
import PhotosUI

struct AddCardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var code = ""
    @State private var codeType: CodeType = .code128
    @State private var displayMode: DisplayMode = .barcode
    @State private var notes = ""
    @State private var backgroundColor: Color = Color(hex: "#1C1C1E")
    @State private var textColor: Color = .white
    @State private var customImage: Data?
    
    @State private var showCameraScanner = false
    @State private var showCodeTypeInfo = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImagePhoto: PhotosPickerItem?
    @State private var isProcessingImage = false
    @State private var isProcessingCustomImage = false
    @State private var scanError: String?
    @State private var showScanError = false
    
    private let imageScanner = ImageScannerService()
    
    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !code.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Scan section
                Section {
                    Button {
                        showCameraScanner = true
                    } label: {
                        Label(String(localized: "scan.camera"), systemImage: "camera.fill")
                    }
                    
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Label(String(localized: "scan.image"), systemImage: "photo.fill")
                    }
                    .disabled(isProcessingImage)
                    
                    if isProcessingImage {
                        HStack {
                            ProgressView()
                            Text(String(localized: "scan.processing"))
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text(String(localized: "section.scan"))
                }
                
                // Manual entry section
                Section(String(localized: "section.details")) {
                    TextField(String(localized: "card.name"), text: $name)
                        .textContentType(.organizationName)
                    
                    TextField(String(localized: "card.number"), text: $code)
                        .textContentType(.creditCardNumber)
                        .keyboardType(.asciiCapable)
                    
                    Toggle(String(localized: "card.showScanCode"), isOn: Binding(
                        get: { displayMode == .barcode },
                        set: { displayMode = $0 ? .barcode : .text }
                    ))
                    
                    if displayMode == .barcode {
                        let availableTypes = {
                            var types = CodeType.compatibleTypes(for: code)
                            // Always include current type to avoid Picker warning
                            if !types.contains(codeType) {
                                types.append(codeType)
                            }
                            return types
                        }()
                        
                        HStack {
                            Picker(String(localized: "card.codeType"), selection: $codeType) {
                                ForEach(availableTypes) { type in
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
                        .onChange(of: code) { _, newCode in
                            // Auto-switch to compatible type if current becomes invalid
                            if !codeType.isCompatible(with: newCode) {
                                if let firstCompatible = CodeType.compatibleTypes(for: newCode).first {
                                    codeType = firstCompatible
                                }
                            }
                        }
                    }
                }
                
                // Notes section
                Section(String(localized: "card.notes")) {
                    TextField(String(localized: "card.notes.placeholder"), text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                // Colors section
                Section(String(localized: "section.colors")) {
                    ColorPicker(String(localized: "color.background"), selection: $backgroundColor, supportsOpacity: false)
                    ColorPicker(String(localized: "color.text"), selection: $textColor, supportsOpacity: false)
                    
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
                
                // Custom image section
                Section(String(localized: "section.customImage")) {
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
                                Label(String(localized: "image.remove"), systemImage: "trash")
                            }
                        }
                    }
                    
                    PhotosPicker(selection: $selectedImagePhoto, matching: .images) {
                        Label(customImage == nil ? String(localized: "image.add") : String(localized: "image.change"), systemImage: "photo")
                    }
                    .disabled(isProcessingCustomImage)
                    
                    if isProcessingCustomImage {
                        HStack {
                            ProgressView()
                            Text(String(localized: "scan.processing"))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                // Preview section
                Section(String(localized: "section.preview")) {
                    if isValid {
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
                    } else {
                        Text(String(localized: "preview.empty"))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle(String(localized: "card.add.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "button.cancel")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "button.save")) {
                        saveCard()
                    }
                    .disabled(!isValid)
                }
            }
            .fullScreenCover(isPresented: $showCameraScanner) {
                CameraScannerView { scannedCode, scannedType in
                    code = scannedCode
                    codeType = scannedType
                }
            }
            .onChange(of: selectedPhoto) { _, newValue in
                if let item = newValue {
                    processSelectedPhoto(item)
                }
            }
            .onChange(of: selectedImagePhoto) { _, newValue in
                if let item = newValue {
                    processCustomImage(item)
                }
            }
            .alert(String(localized: "error.scan"), isPresented: $showScanError) {
                Button(String(localized: "button.ok"), role: .cancel) {}
            } message: {
                Text(scanError ?? "Unknown error")
            }
            .sheet(isPresented: $showCodeTypeInfo) {
                CodeTypeInfoView()
            }
        }
    }
    
    private func saveCard() {
        let card = Card(
            name: name.trimmingCharacters(in: .whitespaces),
            code: code.trimmingCharacters(in: .whitespaces),
            codeType: codeType,
            displayMode: displayMode,
            notes: notes.trimmingCharacters(in: .whitespaces).isEmpty ? nil : notes.trimmingCharacters(in: .whitespaces),
            backgroundColor: backgroundColor.toHex(),
            textColor: textColor.toHex(),
            customImage: customImage
        )
        modelContext.insert(card)
        dismiss()
    }
    
    private func processSelectedPhoto(_ item: PhotosPickerItem) {
        isProcessingImage = true
        selectedPhoto = nil
        
        Task {
            do {
                guard let data = try await item.loadTransferable(type: Data.self) else {
                    throw ImageScannerService.ScanError.imageProcessingFailed
                }
                
                let result = try await imageScanner.scan(imageData: data)
                
                await MainActor.run {
                    code = result.code
                    codeType = result.type
                    isProcessingImage = false
                }
            } catch {
                await MainActor.run {
                    scanError = error.localizedDescription
                    showScanError = true
                    isProcessingImage = false
                }
            }
        }
    }
    
    private func processCustomImage(_ item: PhotosPickerItem) {
        isProcessingCustomImage = true
        selectedImagePhoto = nil
        
        Task {
            do {
                guard let data = try await item.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) else {
                    isProcessingCustomImage = false
                    return
                }
                
                // Resize and compress
                let resized = image.resized(toMaxDimension: 512)
                let compressed = resized.jpegData(compressionQuality: 0.8)
                
                await MainActor.run {
                    customImage = compressed
                    isProcessingCustomImage = false
                }
            } catch {
                await MainActor.run {
                    isProcessingCustomImage = false
                }
            }
        }
    }
}

#Preview {
    AddCardView()
        .modelContainer(for: Card.self, inMemory: true)
}
