//
//  PickedNameCard.swift
//  Names-generator
//

import SwiftUI

struct PickedNameCard: View {
    let name: String?

    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: "sparkles")
                .font(.title2)
                .foregroundStyle(Color.accentColor)

            Text("Picked name")
                .pickerCaptionStyle()

            if let name {
                Text(name)
                    .pickedNameStyle()
            } else {
                Text("Tap the button above\nto pick a random name")
                    .pickerPlaceholderStyle()
            }
        }
        .pickerCardStyle()
    }
}

#Preview("Picked") {
    PickedNameCard(name: "Celina")
        .padding()
}

#Preview("Empty") {
    PickedNameCard(name: nil)
        .padding()
}
