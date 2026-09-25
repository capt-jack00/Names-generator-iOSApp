//
//  AppSettings.swift
//  Names-generator
//

import Foundation

/// UserDefaults keys and defaults for user settings (used with @AppStorage).
enum AppSettings {
    static let pickCountKey = "pickCount"
    static let canRepeatNamesKey = "canRepeatNames"
    static let autoCapitalizeNamesKey = "autoCapitalizeNames"
    static let slotLabelsKey = "slotLabels"

    static let defaultPickCount = 1
    static let defaultCanRepeatNames = false
    static let defaultAutoCapitalizeNames = true

    /// Labels for picked names (e.g. week days). Can be longer than the current
    /// pick amount: labels beyond it are kept so they come back when the amount grows.
    static func loadSlotLabels(from defaults: UserDefaults = .standard) -> [String] {
        defaults.stringArray(forKey: slotLabelsKey) ?? []
    }

    static func saveSlotLabels(_ labels: [String], to defaults: UserDefaults = .standard) {
        defaults.set(labels, forKey: slotLabelsKey)
    }

    /// Allowed amount of names to pick: at least 1 and lower than the number of names.
    /// `nil` when there are too few names to pick any.
    static func pickCountRange(nameCount: Int) -> ClosedRange<Int>? {
        nameCount >= 2 ? 1...(nameCount - 1) : nil
    }
}
