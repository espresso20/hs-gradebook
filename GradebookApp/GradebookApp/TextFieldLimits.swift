import SwiftUI

// MARK: - Character Limit Standards

struct CharacterLimits {
    // Short identifiers (years, codes)
    static let shortIdentifier = 30
    
    // Names and titles (subjects, students, assignments, books, etc.)
    static let title = 50
    
    // Medium text (descriptions, short notes)
    static let description = 250
    
    // Long text (notes, detailed descriptions)
    static let notes = 1000
}

// MARK: - TextField Extension

extension View {
    /// Limits the text length and provides visual feedback when approaching limit
    func characterLimit(_ limit: Int, text: Binding<String>) -> some View {
        self.onChange(of: text.wrappedValue) { oldValue, newValue in
            if newValue.count > limit {
                text.wrappedValue = String(newValue.prefix(limit))
            }
        }
    }
}
