//
//  SearchField.swift
//  Names-generator
//

import SwiftUI

/// Search bar for use inside a list row, where the system `.searchable` bar can't go.
struct SearchField: View {
    let prompt: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField(prompt, text: $text)
                .searchInputStyle()
            if !text.isEmpty {
                Button("Clear search", systemImage: "xmark.circle.fill") {
                    text = ""
                }
                .labelStyle(.iconOnly)
                .foregroundStyle(.secondary)
                // Keeps a row tap from triggering the button.
                .buttonStyle(.borderless)
            }
        }
    }
}

#Preview {
    @Previewable @State var text = "An"
    List {
        SearchField(prompt: "Search names", text: $text)
    }
}
