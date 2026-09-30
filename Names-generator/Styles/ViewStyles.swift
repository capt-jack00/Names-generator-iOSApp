//
//  ViewStyles.swift
//  Names-generator
//

import SwiftUI

struct NameInputStyle: ViewModifier {
    var autoCapitalize = true

    func body(content: Content) -> some View {
        content
            .textInputAutocapitalization(autoCapitalize ? .words : .never)
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
    func nameInputStyle(autoCapitalize: Bool = true) -> some View {
        modifier(NameInputStyle(autoCapitalize: autoCapitalize))
    }

    func hintTextStyle() -> some View {
        modifier(HintTextStyle())
    }
}

/// Main screen list without a navigation bar, so content starts right below the status bar.
struct ScreenListStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .toolbar(.hidden, for: .navigationBar)
            .contentMargins(.top, 8, for: .scrollContent)
            .listSectionSpacing(16)
    }
}

/// Settings form without the large default gap below the navigation bar.
struct SettingsFormStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .contentMargins(.top, 8, for: .scrollContent)
    }
}

/// Text field for a pick label (e.g. "Monday"), right-aligned like iOS Settings values.
struct SlotLabelFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .nameInputStyle()
            .multilineTextAlignment(.trailing)
    }
}

/// Number-pad text field for a numeric setting, right-aligned like iOS Settings values.
struct NumberFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .keyboardType(.numberPad)
            .multilineTextAlignment(.trailing)
    }
}

/// Search text field: no capitalization or autocorrection, keyboard shows "Search".
struct SearchInputStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .submitLabel(.search)
    }
}

// MARK: - Random pick

struct PickerCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.vertical, 28)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity)
            // Same colour as list rows, so the card matches the rest of the screen (adapts to dark mode).
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
    }
}

struct PickerCaptionStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.caption.weight(.semibold))
            .textCase(.uppercase)
            .tracking(1.2)
            .foregroundStyle(.secondary)
    }
}

struct PickedNameStyle: ViewModifier {
    /// Set by the user in Settings; re-renders the card when it changes.
    @AppStorage(AppSettings.fontSizeKey) private var fontSize = AppSettings.defaultFontSize

    func body(content: Content) -> some View {
        content
            .font(.system(size: CGFloat(fontSize), weight: .bold, design: .rounded))
            .foregroundStyle(.primary)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.5)
            .contentTransition(.opacity)
    }
}

struct PickerPlaceholderStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(.title3, design: .rounded).weight(.medium))
            .foregroundStyle(.tertiary)
            .multilineTextAlignment(.center)
    }
}

struct ShareButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.subheadline.weight(.semibold))
            .buttonStyle(.bordered)
            .buttonBorderShape(.capsule)
            .controlSize(.small)
            .padding(12)
    }
}

/// Stretches a label (icon + title) across the full button width.
struct FullWidthLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 8) {
            configuration.icon
            configuration.title
        }
        .frame(maxWidth: .infinity)
    }
}

struct PrimaryActionStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.headline)
            .labelStyle(FullWidthLabelStyle())
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .controlSize(.large)
    }
}

/// Clears the default list row chrome so a custom card can sit on the list background.
struct PlainListRowStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
    }
}

// MARK: - Name rows

enum BadgeStyle {
    static let palette: [Color] = [.red, .orange, .green, .teal, .blue, .indigo, .purple, .pink]
    static let size: CGFloat = 34

    /// Stable colour per name (String.hashValue changes between launches).
    static func color(for name: String) -> Color {
        let sum = name.lowercased().unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return palette[sum % palette.count]
    }
}

struct InitialBadgeStyle: ViewModifier {
    let color: Color

    func body(content: Content) -> some View {
        content
            .font(.system(.subheadline, design: .rounded).weight(.bold))
            .foregroundStyle(.white)
            .frame(width: BadgeStyle.size, height: BadgeStyle.size)
            .background(Circle().fill(color.gradient))
    }
}

extension View {
    func screenListStyle() -> some View {
        modifier(ScreenListStyle())
    }

    func settingsFormStyle() -> some View {
        modifier(SettingsFormStyle())
    }

    func slotLabelFieldStyle() -> some View {
        modifier(SlotLabelFieldStyle())
    }

    func numberFieldStyle() -> some View {
        modifier(NumberFieldStyle())
    }

    func searchInputStyle() -> some View {
        modifier(SearchInputStyle())
    }

    func pickerCardStyle() -> some View {
        modifier(PickerCardStyle())
    }

    func pickerCaptionStyle() -> some View {
        modifier(PickerCaptionStyle())
    }

    func pickedNameStyle() -> some View {
        modifier(PickedNameStyle())
    }

    func pickerPlaceholderStyle() -> some View {
        modifier(PickerPlaceholderStyle())
    }

    func shareButtonStyle() -> some View {
        modifier(ShareButtonStyle())
    }

    func primaryActionStyle() -> some View {
        modifier(PrimaryActionStyle())
    }

    func plainListRowStyle() -> some View {
        modifier(PlainListRowStyle())
    }

    func initialBadgeStyle(color: Color) -> some View {
        modifier(InitialBadgeStyle(color: color))
    }
}
