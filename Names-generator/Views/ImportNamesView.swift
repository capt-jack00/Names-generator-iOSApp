//
//  ImportNamesView.swift
//  Names-generator
//

import SwiftUI

/// Chooses what to import from a .sql file: the table, the name column(s) and how many names.
struct ImportNamesView: View {
    let file: NameImportFile
    let existingNames: [NameEntry]
    let onImport: ([String]) -> Void

    @Environment(\.dismiss) private var dismiss

    @AppStorage(AppSettings.canRepeatNamesKey) private var canRepeatNames = AppSettings.defaultCanRepeatNames
    @AppStorage(AppSettings.autoCapitalizeNamesKey) private var autoCapitalizeNames = AppSettings.defaultAutoCapitalizeNames

    @State private var tableIndex: Int
    @State private var selectedColumns: Set<Int>
    @State private var importsAll = true
    /// Typed amount; clamped when the field loses focus.
    @State private var amountText = ""
    @FocusState private var isAmountFocused: Bool

    private static let previewCount = 5

    init(file: NameImportFile, existingNames: [NameEntry], onImport: @escaping ([String]) -> Void) {
        self.file = file
        self.existingNames = existingNames
        self.onImport = onImport
        let tableIndex = NameImporter.suggestedTableIndex(in: file.tables)
        _tableIndex = State(initialValue: tableIndex)
        _selectedColumns = State(initialValue: Set(NameImporter.suggestedColumns(in: file.tables[tableIndex].columns)))
    }

    private var table: SQLTable {
        file.tables[tableIndex]
    }

    /// Every name the chosen columns would add, before the amount is applied.
    private var availableNames: [String] {
        NameImporter.importableNames(
            from: NameImporter.rawNames(from: table, columns: selectedColumns),
            existing: existingNames,
            allowDuplicates: canRepeatNames,
            autoCapitalize: autoCapitalizeNames
        )
    }

    private func namesToImport(from available: [String]) -> [String] {
        if importsAll { return available }
        return Array(available.prefix(Int(amountText) ?? 0))
    }

    var body: some View {
        let available = availableNames
        let toImport = namesToImport(from: available)

        NavigationStack {
            Form {
                tableSection
                columnsSection
                amountSection(availableCount: available.count)
                previewSection(toImport)
            }
            .settingsFormStyle()
            .navigationTitle("Import names")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Import") {
                        onImport(toImport)
                        dismiss()
                    }
                    .disabled(toImport.isEmpty)
                }
                // The number pad has no return key.
                ToolbarItemGroup(placement: .keyboard) {
                    if isAmountFocused {
                        Spacer()
                        Button("Done") { isAmountFocused = false }
                    }
                }
            }
            .onChange(of: tableIndex) {
                selectedColumns = Set(NameImporter.suggestedColumns(in: table.columns))
            }
            .onChange(of: importsAll) {
                if !importsAll { amountText = "\(available.count)" }
            }
            .onChange(of: isAmountFocused) { if !isAmountFocused { commitAmount(max: available.count) } }
            // The number pad doesn't stop pasted text or a hardware keyboard, so drop anything but digits.
            .onChange(of: amountText) {
                let digits = amountText.filter { $0.isASCII && $0.isNumber }
                if digits != amountText { amountText = digits }
            }
        }
    }

    private var tableSection: some View {
        Section {
            if file.tables.count > 1 {
                Picker("Table", selection: $tableIndex) {
                    ForEach(file.tables.indices, id: \.self) { index in
                        Text("\(file.tables[index].name) (\(file.tables[index].rows.count))").tag(index)
                    }
                }
            } else {
                LabeledContent("Table", value: "\(table.name) (\(table.rows.count))")
            }
        } header: {
            Text(file.fileName)
        } footer: {
            if file.tables.count > 1 {
                Text("This file has \(file.tables.count) tables. Choose the one with names. The number of rows is in brackets.")
            }
        }
    }

    private var columnsSection: some View {
        Section {
            ForEach(table.columns.indices, id: \.self) { index in
                Toggle(isOn: columnBinding(at: index)) {
                    Text(table.columns[index])
                    if let sample = NameImporter.sampleValue(in: table, column: index) {
                        Text(sample)
                    }
                }
            }
        } header: {
            Text("Columns")
        } footer: {
            Text("Choose the column with names. Several columns are joined with a space, e.g. first and last name: \"Anna Nowak\".")
        }
    }

    private func amountSection(availableCount: Int) -> some View {
        Section {
            Toggle("Import all", isOn: $importsAll)
            if !importsAll {
                Stepper(value: amountBinding(max: availableCount), in: 1...max(availableCount, 1)) {
                    LabeledContent("Names to import") {
                        TextField("\(availableCount)", text: $amountText)
                            .numberFieldStyle()
                            .focused($isAmountFocused)
                    }
                }
            }
        } footer: {
            Text(amountFooter(availableCount: availableCount))
        }
    }

    private func previewSection(_ toImport: [String]) -> some View {
        Section {
            if toImport.isEmpty {
                Text("Nothing to import.")
                    .hintTextStyle()
            } else {
                ForEach(Array(toImport.prefix(Self.previewCount).enumerated()), id: \.offset) { _, name in
                    Text(name)
                }
            }
        } header: {
            Text("Preview")
        } footer: {
            if toImport.count > Self.previewCount {
                Text("And \(toImport.count - Self.previewCount) more.")
            }
        }
    }

    private func amountFooter(availableCount: Int) -> String {
        let skipped = canRepeatNames ? "Empty values are skipped." : "Empty values and names already on the list are skipped."
        return "\(availableCount) names can be imported, starting from the top of the table. \(skipped)"
    }

    private func columnBinding(at index: Int) -> Binding<Bool> {
        Binding(
            get: { selectedColumns.contains(index) },
            set: { isOn in
                if isOn {
                    selectedColumns.insert(index)
                } else {
                    selectedColumns.remove(index)
                }
            }
        )
    }

    private func amountBinding(max: Int) -> Binding<Int> {
        Binding(
            get: { min(Swift.max(Int(amountText) ?? 1, 1), Swift.max(max, 1)) },
            set: { amountText = "\($0)" }
        )
    }

    /// Clamps the typed amount to 1...available. Empty or invalid input becomes the maximum.
    private func commitAmount(max: Int) {
        let typed = Int(amountText) ?? max
        amountText = "\(min(Swift.max(typed, 1), max))"
    }
}

#Preview {
    ImportNamesView(
        file: NameImportFile(fileName: "people.sql", tables: [
            SQLTable(name: "people", columns: ["id", "first_name", "last_name"], rows: [
                ["1", "anna", "Nowak"], ["2", "Bartek", nil], ["3", "Celina", "Kowalska"],
            ]),
            SQLTable(name: "cities", columns: ["id", "city"], rows: [["1", "Kraków"]]),
        ]),
        existingNames: []
    ) { _ in }
}
