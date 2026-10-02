//
//  SettingsView.swift
//  Names-generator
//

import SwiftUI

struct SettingsView: View {
    let nameCount: Int
    /// Deletes every name; called after the user confirms.
    var onClearNames: () -> Void = {}

    @Environment(\.dismiss) private var dismiss

    @AppStorage(AppSettings.fontSizeKey) private var fontSize = AppSettings.defaultFontSize
    @AppStorage(AppSettings.pickCountKey) private var pickCount = AppSettings.defaultPickCount
    @AppStorage(AppSettings.namesPerLabelKey) private var namesPerLabel = AppSettings.defaultNamesPerLabel
    @AppStorage(AppSettings.canRepeatNamesKey) private var canRepeatNames = AppSettings.defaultCanRepeatNames
    @AppStorage(AppSettings.autoCapitalizeNamesKey) private var autoCapitalizeNames = AppSettings.defaultAutoCapitalizeNames

    @State private var slotLabels = AppSettings.loadSlotLabels()
    @State private var isShowingLabels = false
    @State private var isConfirmingClearNames = false
    @State private var isConfirmingClearLabels = false
    /// Typed font size; saved (clamped) when the field loses focus.
    @State private var fontSizeText = ""
    @FocusState private var isFontSizeFocused: Bool

    private var pickCountRange: ClosedRange<Int>? {
        AppSettings.pickCountRange(nameCount: nameCount)
    }

    private var namesPerLabelRange: ClosedRange<Int>? {
        AppSettings.namesPerLabelRange(nameCount: nameCount, pickCount: pickCount)
    }

    private var pickCountFooter: String {
        if let pickCountRange {
            "Names repeat only when there aren't enough (\(nameCount)) for every label, and never in two labels in a row. Maximum: \(pickCountRange.upperBound)."
        } else {
            "Add at least 2 names to change this."
        }
    }

    private var namesPerLabelFooter: String {
        guard let namesPerLabelRange else { return "Add at least 2 names to change this." }
        let rule = pickCount > 1
            ? "A name can't be picked for two labels in a row, so this can be at most half the names (\(nameCount))."
            : "Must be lower than the number of names (\(nameCount))."
        return "How many names are picked for each label, e.g. \"Monday: Anna, Bartek\". \(rule) Maximum: \(namesPerLabelRange.upperBound)."
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Stepper(value: $pickCount, in: pickCountRange ?? 1...1) {
                        LabeledContent("Names to pick", value: "\(pickCount)")
                    }
                    .disabled(pickCountRange == nil)
                    
                } footer: {
                    Text(pickCountFooter)
                }

                Section {
                    Button {
                        isConfirmingClearNames = true
                    } label: {
                        Label("Clear names", systemImage: "xmark.circle")
                    }
                    .primaryActionStyle()
                    .plainListRowStyle()
                    .disabled(nameCount == 0)
                }

                Section {
                    DisclosureGroup(isExpanded: $isShowingLabels) {
                        ForEach(0..<pickCount, id: \.self) { index in
                            LabeledContent("Name \(index + 1)") {
                                TextField("e.g. Monday", text: labelBinding(at: index))
                                    .slotLabelFieldStyle()
                            }
                        }
                    } label: {
                        LabeledContent("Labels", value: "\(pickCount)")
                    }
                } footer: {
                    Text("Optional. Each picked name is shown next to its label, e.g. \"Monday: Anna\".")
                }

                Section {
                    Stepper(value: $namesPerLabel, in: namesPerLabelRange ?? 1...1) {
                        LabeledContent("Names per label", value: "\(namesPerLabel)")
                    }
                    .disabled(namesPerLabelRange == nil)
                } footer: {
                    Text(namesPerLabelFooter)
                }

                Section {
                    Button {
                        isConfirmingClearLabels = true
                    } label: {
                        Label("Clear labels", systemImage: "trash")
                    }
                    .primaryActionStyle()
                    .disabled(slotLabels.allSatisfy(\.isEmpty))
                    .plainListRowStyle()
                }

                Section {
                    Toggle("Can repeat names", isOn: $canRepeatNames)
                    Toggle("Auto-capitalize names", isOn: $autoCapitalizeNames)
                    Stepper(value: $fontSize, in: AppSettings.fontSizeRange) {
                        LabeledContent("Font size") {
                            TextField("\(fontSize)", text: $fontSizeText)
                                .numberFieldStyle()
                                .focused($isFontSizeFocused)
                        }
                    }
                }
            }
            .settingsFormStyle()
            .alert("Confirm deletion", isPresented: $isConfirmingClearNames) {
                Button("Confirm deletion", role: .destructive, action: onClearNames)
            } message: {
                Text("Are you sure you want to delete all your names? This action is permament and can't be undone unless you keep a copy of your names somewhere!")
            }
            .alert("Confirm deletion", isPresented: $isConfirmingClearLabels) {
                // Also removes labels beyond the pick amount; the change is saved by onChange below.
                Button("Confirm deletion", role: .destructive) { slotLabels.removeAll() }
            } message: {
                Text("Are you sure you want to delete all your labels? This action is permament and can't be undone unless you keep a copy of your labels somewhere!")
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
                // The number pad has no return key.
                ToolbarItemGroup(placement: .keyboard) {
                    if isFontSizeFocused {
                        Spacer()
                        Button("Done") { isFontSizeFocused = false }
                    }
                }
            }
            .onAppear {
                clampPickCount()
                fontSizeText = "\(fontSize)"
            }
            .onDisappear(perform: commitFontSize)
            .onChange(of: isFontSizeFocused) { if !isFontSizeFocused { commitFontSize() } }
            // Keeps the field in sync when the stepper is used.
            .onChange(of: fontSize) { fontSizeText = "\(fontSize)" }
            // The number pad doesn't stop pasted text or a hardware keyboard, so drop anything but digits.
            .onChange(of: fontSizeText) {
                let digits = fontSizeText.filter { $0.isASCII && $0.isNumber }
                if digits != fontSizeText { fontSizeText = digits }
            }
            // Going from 1 label to more lowers the maximum names per label.
            .onChange(of: pickCount, clampNamesPerLabel)
            .onChange(of: slotLabels) { AppSettings.saveSlotLabels(slotLabels) }
        }
    }

    /// Label for slot `index`. Slots without a stored label read as empty; the list
    /// grows on first edit. Labels beyond the pick amount are never removed.
    private func labelBinding(at index: Int) -> Binding<String> {
        Binding(
            get: { index < slotLabels.count ? slotLabels[index] : "" },
            set: { newValue in
                if index >= slotLabels.count {
                    slotLabels += Array(repeating: "", count: index - slotLabels.count + 1)
                }
                slotLabels[index] = newValue
            }
        )
    }

    /// Keeps the stored values valid after names were deleted.
    private func clampPickCount() {
        if let pickCountRange {
            pickCount = min(max(pickCount, pickCountRange.lowerBound), pickCountRange.upperBound)
        } else {
            pickCount = AppSettings.defaultPickCount
        }
        clampNamesPerLabel()
    }

    /// Saves the typed font size, clamped to the allowed range. Empty or invalid input restores the current size.
    private func commitFontSize() {
        if let typed = Int(fontSizeText) {
            let range = AppSettings.fontSizeRange
            fontSize = min(max(typed, range.lowerBound), range.upperBound)
        }
        fontSizeText = "\(fontSize)"
    }

    private func clampNamesPerLabel() {
        guard let namesPerLabelRange else {
            namesPerLabel = AppSettings.defaultNamesPerLabel
            return
        }
        namesPerLabel = min(max(namesPerLabel, namesPerLabelRange.lowerBound), namesPerLabelRange.upperBound)
    }
}

#Preview("5 names") {
    SettingsView(nameCount: 20)
}

#Preview("1 name") {
    SettingsView(nameCount: 1)
}
