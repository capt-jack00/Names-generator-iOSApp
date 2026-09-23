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

    init(value: String, createdAt: Date = .now) {
        self.value = value
        self.createdAt = createdAt
    }
}
