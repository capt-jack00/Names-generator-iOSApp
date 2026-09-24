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

    @State private var viewModel = NamesViewModel()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        TextField("New name", text: $viewModel.newName)
                            .nameInputStyle()
                            .onSubmit(addName)
                        Button("Add", action: addName)
                            .disabled(!viewModel.canAdd(to: names))
                    }
                    if viewModel.isDuplicate(in: names) {
                        Text("This name already exists.")
                            .hintTextStyle()
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
        viewModel.addName(to: names, in: modelContext)
    }

    private func deleteNames(at offsets: IndexSet) {
        viewModel.deleteNames(at: offsets, from: names, in: modelContext)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: NameEntry.self, inMemory: true)
}
