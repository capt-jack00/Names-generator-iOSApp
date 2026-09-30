//
//  SettingsView.swift
//  Names-generator
//

import SwiftUI

struct SettingsView: View {
    let nameCount: Int

    @Environment(\.dismiss) private var dismiss

    @AppStorage(AppSettings.fontSizeKey) private var fontSize = AppSettings.defaultFontSize
    @AppStorage(AppSettings.pickCountKey) private var pickCount = AppSettings.defaultPickCount
    @AppStorage(AppSettings.namesPerLabelKey) private var namesPerLabel = AppSettings.defaultNamesPerLabel
    @AppStorage(AppSettings.canRepeatNamesKey) private var canRepeatNames = AppSettings.defaultCanRepeatNames
    @AppStorage(AppSettings.autoCapitalizeNamesKey) private var autoCapitalizeNames = AppSettings.defaultAutoCapitalizeNames

    @State private var slotLabels = AppSettings.loadSlotLabels()
    @State private var isShowingLabels = false

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
                    // Also removes labels beyond the pick amount; the change is saved by onChange below.
                    Button {
                        slotLabels.removeAll()
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
                    //TODO: Allow the number to be typed in by numpad
                    Stepper(value: $fontSize, in: 10...40) {
                        LabeledContent("Font size", value: "\(fontSize)")
                    }
                }
            }
            .settingsFormStyle()
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear(perform: clampPickCount)
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
