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

    @AppStorage(AppSettings.pickCountKey) private var pickCount = AppSettings.defaultPickCount
    @AppStorage(AppSettings.namesPerLabelKey) private var namesPerLabel = AppSettings.defaultNamesPerLabel
    @AppStorage(AppSettings.canRepeatNamesKey) private var canRepeatNames = AppSettings.defaultCanRepeatNames
    @AppStorage(AppSettings.autoCapitalizeNamesKey) private var autoCapitalizeNames = AppSettings.defaultAutoCapitalizeNames

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

                        Button(action: pickRandomNames) {
                            Label("Pick a random name", systemImage: "shuffle")
                        }
                        .primaryActionStyle()
                        .disabled(names.isEmpty)
                    }
                    .plainListRowStyle()

                    // Labels are re-read on every render, so edits in Settings apply when the sheet closes.
                    PickedNameCard(lines: PickResultFormatter.lines(
                        groups: viewModel.pickedNames,
                        labels: AppSettings.loadSlotLabels()
                    ))
                        .plainListRowStyle()
                }

                Section {
                    HStack {
                        TextField("New name", text: $viewModel.newName)
                            .nameInputStyle(autoCapitalize: autoCapitalizeNames)
                            .onSubmit(addName)
                        Button("Add", systemImage: "plus.circle.fill", action: addName)
                            .labelStyle(.iconOnly)
                            .font(.title2)
                            .disabled(!viewModel.canAdd(to: names, allowDuplicates: canRepeatNames))
                    }
                    if !canRepeatNames && viewModel.isDuplicate(in: names) {
                        Text("This name already exists.")
                            .hintTextStyle()
                    }
                }

                Section(namesHeader) {
                    if names.isEmpty {
                        ContentUnavailableView(
                            "No names yet",
                            systemImage: "person.2",
                            description: Text("Add a name above to get started.")
                        )
                    } else {
                        SearchField(prompt: "Search names", text: $viewModel.searchText)
                        if filteredNames.isEmpty {
                            ContentUnavailableView.search(text: viewModel.searchText)
                        } else {
                            ForEach(filteredNames) { entry in
                                NameRow(name: entry.value)
                            }
                            .onDelete(perform: deleteNames)
                        }
                    }
                }
            }
            .screenListStyle()
            .sheet(isPresented: $isShowingSettings) {
                SettingsView(nameCount: names.count)
            }
        }
    }

    /// Search only filters the list; picking still uses all names.
    private var filteredNames: [NameEntry] {
        viewModel.filteredNames(names)
    }

    private var namesHeader: String {
        viewModel.isSearching ? "Names (\(filteredNames.count) of \(names.count))" : "Names (\(names.count))"
    }

    private func addName() {
        viewModel.addName(to: names, in: modelContext, allowDuplicates: canRepeatNames, autoCapitalize: autoCapitalizeNames)
    }

    private func pickRandomNames() {
        // Stored amounts can be too high if names were deleted since they were set.
        let labelCount = min(pickCount, AppSettings.pickCountRange(nameCount: names.count)?.upperBound ?? 1)
        let maxPerLabel = AppSettings.namesPerLabelRange(nameCount: names.count, pickCount: labelCount)?.upperBound ?? 1
        withAnimation {
            viewModel.pickRandomNames(from: names, labelCount: labelCount, namesPerLabel: min(namesPerLabel, maxPerLabel))
        }
    }

    /// Offsets refer to the visible (filtered) rows.
    private func deleteNames(at offsets: IndexSet) {
        viewModel.deleteNames(at: offsets, from: filteredNames, in: modelContext)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: NameEntry.self, inMemory: true)
}
