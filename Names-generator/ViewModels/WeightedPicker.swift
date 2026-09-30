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

    /// Picks `groupCount` groups of `groupSize` distinct items (e.g. names per label).
    /// - An item is never in two groups in a row.
    /// - Every item is used once before any item repeats (a "round"); repeats only
    ///   happen when there are more slots than items.
    /// Always fills every group when there are at least `2 × groupSize` items
    /// (or `groupSize` items for a single group).
    static func pickGroups<Item>(
        from items: [Item],
        groupCount: Int,
        groupSize: Int,
        weight: (Item) -> Int,
        using generator: inout some RandomNumberGenerator
    ) -> [[Item]] {
        var unused = Set(items.indices)
        var previous: Set<Int> = []
        var groups: [[Item]] = []

        func draw(_ count: Int, excluding excluded: Set<Int>) -> [Int] {
            let candidates = items.indices.filter { unused.contains($0) && !excluded.contains($0) }
            return pick(from: candidates, count: count, weight: { weight(items[$0]) }, using: &generator)
        }

        for _ in 0..<groupCount {
            var group = draw(groupSize, excluding: previous)
            if group.count < groupSize {
                // Not enough unused items left: start a new round with everything not already in this group.
                unused = Set(items.indices).subtracting(group)
                group += draw(groupSize - group.count, excluding: previous)
            }
            unused.subtract(group)
            previous = Set(group)
            groups.append(group.map { items[$0] })
        }
        return groups
    }

    static func pickGroups<Item>(from items: [Item], groupCount: Int, groupSize: Int, weight: (Item) -> Int) -> [[Item]] {
        var generator = SystemRandomNumberGenerator()
        return pickGroups(from: items, groupCount: groupCount, groupSize: groupSize, weight: weight, using: &generator)
    }
}
