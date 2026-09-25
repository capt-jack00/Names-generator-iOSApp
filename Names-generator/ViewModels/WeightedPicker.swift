//
//  WeightedPicker.swift
//  Names-generator
//

import Foundation

/// Weighted random picking ("anti-streak"): items that haven't been picked
/// for a while get a proportionally higher chance.
enum WeightedPicker {
    /// Picks `count` distinct items. Each draw chooses an item with probability
    /// weight / total weight of the items still left, then removes it.
    static func pick<Item>(
        from items: [Item],
        count: Int,
        weight: (Item) -> Int,
        using generator: inout some RandomNumberGenerator
    ) -> [Item] {
        var remaining = items.map { (item: $0, weight: max(1, weight($0))) }
        var picked: [Item] = []

        for _ in 0..<min(count, items.count) {
            let totalWeight = remaining.reduce(0) { $0 + $1.weight }
            var roll = Int.random(in: 0..<totalWeight, using: &generator)
            let index = remaining.firstIndex { candidate in
                roll -= candidate.weight
                return roll < 0
            }!
            picked.append(remaining.remove(at: index).item)
        }
        return picked
    }

    static func pick<Item>(from items: [Item], count: Int, weight: (Item) -> Int) -> [Item] {
        var generator = SystemRandomNumberGenerator()
        return pick(from: items, count: count, weight: weight, using: &generator)
    }
}
