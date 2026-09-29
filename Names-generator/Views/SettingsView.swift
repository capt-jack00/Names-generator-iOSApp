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
    @AppStorage(AppSettings.canRepeatNamesKey) private var canRepeatNames = AppSettings.defaultCanRepeatNames
    @AppStorage(AppSettings.autoCapitalizeNamesKey) private var autoCapitalizeNames = AppSettings.defaultAutoCapitalizeNames

    @State private var slotLabels = AppSettings.loadSlotLabels()
    @State private var isShowingLabels = false
    // UI only for now: not saved and not used when picking.
    @State private var namesPerLabel = 1

    private var pickCountRange: ClosedRange<Int>? {
        AppSettings.pickCountRange(nameCount: nameCount)
    }

    private var pickCountFooter: String {
        if let pickCountRange {
            "Must be lower than the number of names (\(nameCount)). Maximum: \(pickCountRange.upperBound)."
        } else {
            "Add at least 2 names to change this."
        }
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
                    Stepper(value: $namesPerLabel, in: 1...10) {
                        LabeledContent("Names per label", value: "\(namesPerLabel)")
                    }
                } footer: {
                    Text("How many names are picked for each label, e.g. \"Monday: Anna, Bartek\".")
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

    /// Keeps the stored value valid after names were deleted.
    private func clampPickCount() {
        guard let pickCountRange else {
            pickCount = AppSettings.defaultPickCount
            return
        }
        pickCount = min(max(pickCount, pickCountRange.lowerBound), pickCountRange.upperBound)
    }
}

#Preview("5 names") {
    SettingsView(nameCount: 20)
}

#Preview("1 name") {
    SettingsView(nameCount: 1)
}
