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
    
    @State private var showCameraScanner = false
    @State private var showCodeTypeInfo = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var isProcessingImage = false
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
                        Label("Scan with Camera", systemImage: "camera.fill")
                    }
                    
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Label("Scan from Image", systemImage: "photo.fill")
                    }
                    .disabled(isProcessingImage)
                    
                    if isProcessingImage {
                        HStack {
                            ProgressView()
                            Text("Processing image...")
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Scan Barcode")
                }
                
                // Manual entry section
                Section("Card Details") {
                    TextField("Card Name", text: $name)
                        .textContentType(.organizationName)
                    
                    TextField("Card number", text: $code)
                        .textContentType(.creditCardNumber)
                        .keyboardType(.asciiCapable)
                    
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
                    
                    Toggle("Show as barcode", isOn: Binding(
                        get: { displayMode == .barcode },
                        set: { displayMode = $0 ? .barcode : .text }
                    ))
                }
                
                // Notes section
                Section("Notes") {
                    TextField("Optional notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                // Preview section
                Section("Preview") {
                    if isValid {
                        CardPreview(
                            card: Card(
                                name: name,
                                code: code,
                                codeType: codeType,
                                displayMode: displayMode
                            ),
                            size: .medium
                        )
                        .frame(maxWidth: .infinity)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                    } else {
                        Text("Enter card details to see preview")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle("Add Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
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
            .alert("Scan Error", isPresented: $showScanError) {
                Button("OK", role: .cancel) {}
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
            notes: notes.trimmingCharacters(in: .whitespaces).isEmpty ? nil : notes.trimmingCharacters(in: .whitespaces)
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
}

#Preview {
    AddCardView()
        .modelContainer(for: Card.self, inMemory: true)
}
