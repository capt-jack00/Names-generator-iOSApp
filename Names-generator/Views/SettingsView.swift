//
//  SettingsView.swift
//  Names-generator
//

import SwiftUI

struct SettingsView: View {
    let nameCount: Int

    @Environment(\.dismiss) private var dismiss

    @AppStorage(AppSettings.pickCountKey) private var pickCount = AppSettings.defaultPickCount
    @AppStorage(AppSettings.canRepeatNamesKey) private var canRepeatNames = AppSettings.defaultCanRepeatNames
    @AppStorage(AppSettings.autoCapitalizeNamesKey) private var autoCapitalizeNames = AppSettings.defaultAutoCapitalizeNames

    // UI only for now: labels are not saved yet.
    @State private var slotLabels: [String] = []
    @State private var isShowingLabels = false

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
                        ForEach(slotLabels.indices, id: \.self) { index in
                            LabeledContent("Name \(index + 1)") {
                                TextField("e.g. Monday", text: $slotLabels[index])
                                    .slotLabelFieldStyle()
                            }
                        }
                    } label: {
                        LabeledContent("Labels", value: "\(slotLabels.count)")
                    }
                } footer: {
                    Text("Optional. Each picked name is shown next to its label, e.g. \"Monday: Anna\".")
                }

                Section {
                    Toggle("Can repeat names", isOn: $canRepeatNames)
                    Toggle("Auto-capitalize names", isOn: $autoCapitalizeNames)
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
            .onAppear {
                clampPickCount()
                resizeSlotLabels()
            }
            .onChange(of: pickCount) { resizeSlotLabels() }
        }
    }

    /// One label per picked name; keeps already typed labels when the amount changes.
    private func resizeSlotLabels() {
        if slotLabels.count < pickCount {
            slotLabels += Array(repeating: "", count: pickCount - slotLabels.count)
        } else if slotLabels.count > pickCount {
            slotLabels.removeLast(slotLabels.count - pickCount)
        }
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
