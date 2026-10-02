//
//  NameImporter.swift
//  Names-generator
//

import Foundation

/// A .sql file read for importing, shown in the import sheet.
nonisolated struct NameImportFile: Identifiable, Sendable {
    let id = UUID()
    let fileName: String
    let tables: [SQLTable]

    /// Reads and parses the file off the main thread, since dumps can be large.
    @concurrent
    static func load(from url: URL) async throws -> NameImportFile {
        // Files picked outside the app's sandbox need security-scoped access.
        let isAccessing = url.startAccessingSecurityScopedResource()
        defer { if isAccessing { url.stopAccessingSecurityScopedResource() } }
        let data = try Data(contentsOf: url)
        return NameImportFile(fileName: url.lastPathComponent, tables: try SQLDumpParser.parse(data))
    }
}

/// Turns table rows into names: guesses which table and columns hold names
/// and filters values the same way adding a name by hand does.
enum NameImporter {
    /// Column names compared without case, accents, spaces, "_" or "-": "Full_Name" → "fullname".
    private static let fullNameColumns = ["fullname", "name", "displayname", "personname", "imienazwisko", "nazwa"]
    private static let firstNameColumns = ["firstname", "givenname", "forename", "imie"]
    private static let lastNameColumns = ["lastname", "surname", "familyname", "nazwisko"]

    /// Columns that most likely hold names: a full name column, otherwise first + last name,
    /// otherwise the first column containing "name". Empty when nothing looks like a name.
    static func suggestedColumns(in columns: [String]) -> [Int] {
        let keys = columns.map { columnKey($0) }
        if let index = fullNameColumns.lazy.compactMap({ keys.firstIndex(of: $0) }).first {
            return [index]
        }
        let first = keys.firstIndex { firstNameColumns.contains($0) }
        let last = keys.firstIndex { lastNameColumns.contains($0) }
        let firstAndLast = [first, last].compactMap { $0 }
        if !firstAndLast.isEmpty {
            return firstAndLast.sorted()
        }
        return keys.firstIndex { $0.contains("name") }.map { [$0] } ?? []
    }

    /// The first table with a name-like column, otherwise the first table.
    static func suggestedTableIndex(in tables: [SQLTable]) -> Int {
        tables.firstIndex { !suggestedColumns(in: $0.columns).isEmpty } ?? 0
    }

    /// One name per row: the chosen columns' values joined with a space in column order
    /// ("Anna" + "Nowak" → "Anna Nowak"). Empty values and NULLs are left out.
    static func rawNames(from table: SQLTable, columns: Set<Int>) -> [String] {
        let ordered = columns.sorted()
        return table.rows.map { row in
            ordered
                .compactMap { $0 < row.count ? row[$0]?.trimmingCharacters(in: .whitespacesAndNewlines) : nil }
                .filter { !$0.isEmpty }
                .joined(separator: " ")
        }
    }

    /// Names that would be added, in file order: empty ones are skipped and, unless duplicates
    /// are allowed, so are names already on the list or earlier in the import (ignoring case).
    static func importableNames(
        from rawNames: [String],
        existing: [NameEntry],
        allowDuplicates: Bool,
        autoCapitalize: Bool
    ) -> [String] {
        var seen = Set(existing.map { $0.value.lowercased() })
        var result: [String] = []
        for rawName in rawNames where !rawName.isEmpty {
            let name = autoCapitalize ? NamesViewModel.capitalizingWords(rawName) : rawName
            if !allowDuplicates {
                guard seen.insert(name.lowercased()).inserted else { continue }
            }
            result.append(name)
        }
        return result
    }

    /// First value in the column that isn't empty, shown as an example under the column name.
    static func sampleValue(in table: SQLTable, column: Int) -> String? {
        table.rows.lazy
            .compactMap { column < $0.count ? $0[column]?.trimmingCharacters(in: .whitespacesAndNewlines) : nil }
            .first { !$0.isEmpty }
    }

    private static func columnKey(_ column: String) -> String {
        let folded = column.applyingTransform(StringTransform("Latin-ASCII"), reverse: false) ?? column
        return folded.lowercased().filter { $0.isLetter || $0.isNumber }
    }
}
