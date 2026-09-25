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
    @State private var isShowingSettings = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 12) {
                        Button {
                            isShowingSettings = true
                        } label: {
                            Image(systemName: "gearshape.fill")
                        }
                        .primaryActionStyle()
                        .accessibilityLabel("Settings")

                        Button {
                            // Random pick logic added in the next step.
                        } label: {
                            Label("Pick a random name", systemImage: "shuffle")
                        }
                        .primaryActionStyle()
                        .disabled(names.isEmpty)
                    }
                    .plainListRowStyle()

                    PickedNameCard(name: nil)
                        .plainListRowStyle()
                }

                Section {
                    HStack {
                        TextField("New name", text: $viewModel.newName)
                            .nameInputStyle()
                            .onSubmit(addName)
                        Button("Add", systemImage: "plus.circle.fill", action: addName)
                            .labelStyle(.iconOnly)
                            .font(.title2)
                            .disabled(!viewModel.canAdd(to: names))
                    }
                    if viewModel.isDuplicate(in: names) {
                        Text("This name already exists.")
                            .hintTextStyle()
                    }
                }

                Section("Names (\(names.count))") {
                    if names.isEmpty {
                        ContentUnavailableView(
                            "No names yet",
                            systemImage: "person.2",
                            description: Text("Add a name above to get started.")
                        )
                    } else {
                        ForEach(names) { entry in
                            NameRow(name: entry.value)
                        }
                        .onDelete(perform: deleteNames)
                    }
                }
            }
            .screenListStyle()
            .sheet(isPresented: $isShowingSettings) {
                SettingsView(nameCount: names.count)
            }
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
