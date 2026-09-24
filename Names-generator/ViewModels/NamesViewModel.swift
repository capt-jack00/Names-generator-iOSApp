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

    var trimmedName: String {
        newName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func isDuplicate(in names: [NameEntry]) -> Bool {
        names.contains { $0.value.caseInsensitiveCompare(trimmedName) == .orderedSame }
    }

    func canAdd(to names: [NameEntry]) -> Bool {
        !trimmedName.isEmpty && !isDuplicate(in: names)
    }

    func addName(to names: [NameEntry], in context: ModelContext) {
        guard canAdd(to: names) else { return }
        context.insert(NameEntry(value: trimmedName))
        newName = ""
    }

    func deleteNames(at offsets: IndexSet, from names: [NameEntry], in context: ModelContext) {
        for index in offsets {
            context.delete(names[index])
        }
    }
}
