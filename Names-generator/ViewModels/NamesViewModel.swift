//
//  NamesViewModel.swift
//  Names-generator
//

import Foundation
import Observation
import SwiftData

@Observable
final class NamesViewModel {
    var newName = ""
    /// A new search starts from the first page of results again.
    var searchText = "" {
        didSet { visibleNameCount = Self.namesPageSize }
    }
    /// How many names the list shows; grows by `namesPageSize` with "Show more".
    private(set) var visibleNameCount = namesPageSize
    /// Picked names grouped by label, e.g. [["Anna", "Bartek"], ["Celina", "Dawid"]].
    var pickedNames: [[String]] = []

    var trimmedName: String {
        newName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Names starting with the search text, ignoring case and accents ("luk" finds "Łukasz").
    /// All names when the search is empty.
    func filteredNames(_ names: [NameEntry]) -> [NameEntry] {
        guard isSearching else { return names }
        let query = Self.searchKey(searchText.trimmingCharacters(in: .whitespacesAndNewlines))
        return names.filter { Self.searchKey($0.value).hasPrefix(query) }
    }

    /// Lowercased with letters folded to ASCII. Plain diacritic-insensitive
    /// comparison misses letters like "Ł", which have no separate accent mark.
    private static func searchKey(_ text: String) -> String {
        (text.applyingTransform(StringTransform("Latin-ASCII"), reverse: false) ?? text).lowercased()
    }

    static let namesPageSize = 10

    /// The first `visibleNameCount` names; the rest are behind "Show more".
    func visibleNames(_ names: [NameEntry]) -> [NameEntry] {
        Array(names.prefix(visibleNameCount))
    }

    func showMoreNames() {
        visibleNameCount += Self.namesPageSize
    }

    func showFewerNames() {
        visibleNameCount = Self.namesPageSize
    }

    func isDuplicate(in names: [NameEntry]) -> Bool {
        names.contains { $0.value.caseInsensitiveCompare(trimmedName) == .orderedSame }
    }

    func canAdd(to names: [NameEntry], allowDuplicates: Bool) -> Bool {
        !trimmedName.isEmpty && (allowDuplicates || !isDuplicate(in: names))
    }

    func addName(to names: [NameEntry], in context: ModelContext, allowDuplicates: Bool, autoCapitalize: Bool) {
        guard canAdd(to: names, allowDuplicates: allowDuplicates) else { return }
        let value = autoCapitalize ? Self.capitalizingWords(trimmedName) : trimmedName
        context.insert(NameEntry(value: value))
        newName = ""
    }

    /// Adds already filtered names (see `NameImporter.importableNames`). Each gets a slightly
    /// later date, so the list shows them newest first like names added one by one.
    func importNames(_ importedNames: [String], in context: ModelContext) {
        let start = Date.now
        for (offset, name) in importedNames.enumerated() {
            context.insert(NameEntry(value: name, createdAt: start.addingTimeInterval(Double(offset) * 0.001)))
        }
    }

    /// Uppercases the first letter of every word (split by spaces or hyphens) and
    /// leaves the rest untouched, so "anna-maria mcDonald" becomes "Anna-Maria McDonald".
    static func capitalizingWords(_ text: String) -> String {
        var result = ""
        var isWordStart = true
        for character in text {
            result += isWordStart ? character.uppercased() : String(character)
            isWordStart = character.isWhitespace || character == "-"
        }
        return result
    }

    /// Picks `namesPerLabel` different names for each of `labelCount` labels, favouring names
    /// that haven't been picked for a while. A name is never picked for two labels in a row
    /// and only repeats once every name has been used.
    func pickRandomNames(from names: [NameEntry], labelCount: Int, namesPerLabel: Int) {
        let picked = WeightedPicker.pickGroups(from: names, groupCount: labelCount, groupSize: namesPerLabel) {
            1 + $0.picksSinceLastChosen
        }
        let pickedIDs = Set(picked.joined().map(\.persistentModelID))

        for entry in names {
            entry.picksSinceLastChosen = pickedIDs.contains(entry.persistentModelID) ? 0 : entry.picksSinceLastChosen + 1
        }
        pickedNames = picked.map { $0.map(\.value) }
    }

    func deleteNames(at offsets: IndexSet, from names: [NameEntry], in context: ModelContext) {
        for index in offsets {
            context.delete(names[index])
        }
    }

    /// Deletes every name and clears the last pick, since its names no longer exist.
    func deleteAllNames(_ names: [NameEntry], in context: ModelContext) {
        for entry in names {
            context.delete(entry)
        }
        pickedNames = []
    }
}
