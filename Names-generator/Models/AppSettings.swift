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

    static let defaultPickCount = 1
    static let defaultCanRepeatNames = false
    static let defaultAutoCapitalizeNames = true

    /// Allowed amount of names to pick: at least 1 and lower than the number of names.
    /// `nil` when there are too few names to pick any.
    static func pickCountRange(nameCount: Int) -> ClosedRange<Int>? {
        nameCount >= 2 ? 1...(nameCount - 1) : nil
    }
}
