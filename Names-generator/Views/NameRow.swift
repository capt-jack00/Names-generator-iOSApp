//
//  NameRow.swift
//  Names-generator
//

import SwiftUI

struct NameRow: View {
    let name: String

    var body: some View {
        HStack(spacing: 12) {
            Text(name.prefix(1).uppercased())
                .initialBadgeStyle(color: BadgeStyle.color(for: name))
            Text(name)
        }
    }
}

#Preview {
    List {
        NameRow(name: "Anna")
        NameRow(name: "Bartek")
        NameRow(name: "Celina")
    }
}
