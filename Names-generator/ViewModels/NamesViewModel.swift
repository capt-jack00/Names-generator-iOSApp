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
    /// Picked names grouped by label, e.g. [["Anna", "Bartek"], ["Celina", "Dawid"]].
    var pickedNames: [[String]] = []

    var trimmedName: String {
        newName.trimmingCharacters(in: .whitespacesAndNewlines)
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
}
