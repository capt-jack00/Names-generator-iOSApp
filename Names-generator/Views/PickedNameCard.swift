//
//  PickedNameCard.swift
//  Names-generator
//

import SwiftUI

struct PickedNameCard: View {
    let names: [String]

    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: "sparkles")
                .font(.title2)
                .foregroundStyle(Color.accentColor)

            Text("Picked name")
                .pickerCaptionStyle()

            if !names.isEmpty {
                ForEach(Array(names.enumerated()), id: \.offset) { _, name in
                    Text(name)
                        .pickedNameStyle()
                }
            } else {
                Text("Tap the button above\nto pick a random name")
                    .pickerPlaceholderStyle()
            }
        }
        .pickerCardStyle()
    }
}

#Preview("Picked") {
    PickedNameCard(names: ["Celina"])
        .padding()
}

#Preview("Empty") {
    PickedNameCard(names: [])
        .padding()
}
