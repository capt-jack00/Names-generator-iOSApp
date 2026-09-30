//
//  PickResultFormatter.swift
//  Names-generator
//

import Foundation

/// Turns picked names into display lines like "Monday: Anna, Bartek" using the labels from Settings.
enum PickResultFormatter {
    /// One line per label; names picked for the same label are joined with ", ".
    /// - If no label is typed for any picked slot, names are shown as they are.
    /// - Otherwise every line gets its slot's label; empty labels fall back to
    ///   the slot number, e.g. ["Monday: Anna, Bartek", "2: Celina, Dawid"].
    static func lines(groups: [[String]], labels: [String]) -> [String] {
        let names = groups.map { $0.joined(separator: ", ") }
        let slotLabels = names.indices.map { index in
            index < labels.count ? labels[index].trimmingCharacters(in: .whitespacesAndNewlines) : ""
        }
        guard slotLabels.contains(where: { !$0.isEmpty }) else { return names }

        return names.enumerated().map { index, name in
            let label = slotLabels[index].isEmpty ? String(index + 1) : slotLabels[index]
            return "\(label): \(name)"
        }
    }

    /// Plain text for sharing, one line per picked name.
    static func shareText(lines: [String]) -> String {
        lines.joined(separator: "\n")
    }
}
