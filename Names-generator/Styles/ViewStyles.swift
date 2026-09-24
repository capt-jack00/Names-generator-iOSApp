//
//  ViewStyles.swift
//  Names-generator
//

import SwiftUI

struct NameInputStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .textInputAutocapitalization(.words)
            .autocorrectionDisabled()
            .submitLabel(.done)
    }
}

struct HintTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.footnote)
            .foregroundStyle(.secondary)
    }
}

extension View {
    func nameInputStyle() -> some View {
        modifier(NameInputStyle())
    }

    func hintTextStyle() -> some View {
        modifier(HintTextStyle())
    }
}
