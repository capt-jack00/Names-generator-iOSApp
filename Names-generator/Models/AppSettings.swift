//
//  AppSettings.swift
//  Names-generator
//

import Foundation

/// UserDefaults keys and defaults for user settings (used with @AppStorage).
enum AppSettings {
    static let fontSizeKey = "fontSize"
    static let pickCountKey = "pickCount"
    static let canRepeatNamesKey = "canRepeatNames"
    static let autoCapitalizeNamesKey = "autoCapitalizeNames"
    static let slotLabelsKey = "slotLabels"
    static let namesPerLabelKey = "namesPerLabel"

    static let defaultPickCount = 1
    static let defaultFontSize = 30
    static let defaultCanRepeatNames = false
    static let defaultAutoCapitalizeNames = true
    static let defaultNamesPerLabel = 1
    /// Names can repeat across labels, so the pick amount isn't limited by the name count.
    static let maxPickCount = 30

    /// Labels for picked names (e.g. week days). Can be longer than the current
    /// pick amount: labels beyond it are kept so they come back when the amount grows.
    static func loadSlotLabels(from defaults: UserDefaults = .standard) -> [String] {
        defaults.stringArray(forKey: slotLabelsKey) ?? []
    }

    static func saveSlotLabels(_ labels: [String], to defaults: UserDefaults = .standard) {
        defaults.set(labels, forKey: slotLabelsKey)
    }

    /// Allowed amount of labels ("Names to pick"). Names repeat when there aren't
    /// enough for every label, so only a fixed maximum applies.
    /// `nil` when there are too few names to pick any.
    static func pickCountRange(nameCount: Int) -> ClosedRange<Int>? {
        nameCount >= 2 ? 1...maxPickCount : nil
    }

    /// Allowed amount of names per label. A name can't be in two labels in a row,
    /// so two neighbouring labels need twice as many names: at most half the names.
    /// With a single label it must be lower than the number of names, like the pick amount used to be.
    /// `nil` when there are too few names to pick any.
    static func namesPerLabelRange(nameCount: Int, pickCount: Int) -> ClosedRange<Int>? {
        guard nameCount >= 2 else { return nil }
        return 1...(pickCount > 1 ? nameCount / 2 : nameCount - 1)
    }
}
