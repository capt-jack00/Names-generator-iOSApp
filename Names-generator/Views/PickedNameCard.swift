//
//  PickedNameCard.swift
//  Names-generator
//

import SwiftUI

struct PickedNameCard: View {
    /// Display lines, e.g. "Anna" or "Monday: Anna".
    let lines: [String]

    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: "sparkles")
                .font(.title2)
                .foregroundStyle(Color.accentColor)

            Text("Picked name")
                .pickerCaptionStyle()

            if !lines.isEmpty {
                ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                    Text(line)
                        .pickedNameStyle()
                }

                ShareLink(item: PickResultFormatter.shareText(lines: lines)) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
                .shareButtonStyle()
            } else {
                Text("Tap the button above\nto pick a random name")
                    .pickerPlaceholderStyle()
            }
        }
        .pickerCardStyle()
    }
}

#Preview("Picked") {
    PickedNameCard(lines: ["Celina"])
        .padding()
}

#Preview("Labelled") {
    PickedNameCard(lines: ["Monday: Anna", "2: Bartek", "Wednesday: Celina"])
        .padding()
}

#Preview("Empty") {
    PickedNameCard(lines: [])
        .padding()
}
