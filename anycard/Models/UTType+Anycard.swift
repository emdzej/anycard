import UniformTypeIdentifiers

extension UTType {
    /// Custom UTType for anycard export files
    static var anycard: UTType {
        UTType(exportedAs: "com.emdzej.anycard.backup", conformingTo: .json)
    }
}
