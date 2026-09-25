//
//  NameEntry.swift
//  Names-generator
//

import Foundation
import SwiftData

@Model
final class NameEntry {
    var value: String
    var createdAt: Date
    /// How many picks in a row this name has not been chosen. Drives the anti-streak weight.
    var picksSinceLastChosen: Int = 0

    init(value: String, createdAt: Date = .now) {
        self.value = value
        self.createdAt = createdAt
    }
}
