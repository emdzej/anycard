import SwiftUI
import SwiftData

struct AddCardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var code = ""
    @State private var codeType: CodeType = .code128
    
    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !code.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Card Details") {
                    TextField("Card Name", text: $name)
                        .textContentType(.organizationName)
                    
                    TextField("Card Number / Code", text: $code)
                        .textContentType(.creditCardNumber)
                        .keyboardType(.asciiCapable)
                    
                    Picker("Code Type", selection: $codeType) {
                        ForEach(CodeType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                }
                
                Section("Preview") {
                    if isValid {
                        CardPreview(
                            card: Card(name: name, code: code, codeType: codeType),
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
        }
    }
    
    private func saveCard() {
        let card = Card(
            name: name.trimmingCharacters(in: .whitespaces),
            code: code.trimmingCharacters(in: .whitespaces),
            codeType: codeType
        )
        modelContext.insert(card)
        dismiss()
    }
}

#Preview {
    AddCardView()
        .modelContainer(for: Card.self, inMemory: true)
}
