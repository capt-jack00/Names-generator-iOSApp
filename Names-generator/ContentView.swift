//
//  ContentView.swift
//  Names-generator
//
//  Created by Dominik Bednorz on 23/09/2026.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \NameEntry.createdAt, order: .reverse) private var names: [NameEntry]

    @State private var newName = ""

    private var trimmedName: String {
        newName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isDuplicate: Bool {
        names.contains { $0.value.caseInsensitiveCompare(trimmedName) == .orderedSame }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        TextField("New name", text: $newName)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                            .submitLabel(.done)
                            .onSubmit(addName)
                        Button("Add", action: addName)
                            .disabled(trimmedName.isEmpty || isDuplicate)
                    }
                    if isDuplicate {
                        Text("This name already exists.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Names (\(names.count))") {
                    ForEach(names) { entry in
                        Text(entry.value)
                    }
                    .onDelete(perform: deleteNames)
                }
            }
            .navigationTitle("Names")
        }
    }

    private func addName() {
        guard !trimmedName.isEmpty, !isDuplicate else { return }
        modelContext.insert(NameEntry(value: trimmedName))
        newName = ""
    }

    private func deleteNames(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(names[index])
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: NameEntry.self, inMemory: true)
}
