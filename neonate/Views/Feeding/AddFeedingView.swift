import SwiftUI

struct AddFeedingView: View {

    @Environment(\.dismiss) private var dismiss

    @ObservedObject var viewModel: FeedingViewModel
    @ObservedObject var childViewModel: ChildProfileViewModel

    @State private var feedingType: String = String(localized: "feeding_type_breast_feeding")
    @State private var timestamp: Date = Date()
    @State private var duration: String = ""
    @State private var volume: String = ""
    @State private var breast: String = String(localized: "feeding_breast_left")
    @State private var notes: String = ""

    var feedingTypes: [String] {
        [
            String(localized: "feeding_type_breast_feeding"),
            String(localized: "feeding_type_bottle_feeding"),
            String(localized: "feeding_type_complementary_feeding")
        ]
    }

    var breastOptions: [String] {
        [
            String(localized: "feeding_breast_left"),
            String(localized: "feeding_breast_right"),
            String(localized: "feeding_breast_both")
        ]
    }

    var body: some View {
        NavigationView {
            Form {
                Section(String(localized: "feeding_type")) {
                    Picker(String(localized: "form_type"), selection: $feedingType) {
                        ForEach(feedingTypes, id: \.self) { type in
                            Text(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section(String(localized: "form_time_label")) {
                    DatePicker(String(localized: "form_feeding_time"), selection: $timestamp)
                }

                if feedingType == String(localized: "feeding_type_breast_feeding") {
                    Section(String(localized: "feeding_breast")) {
                        Picker(String(localized: "feeding_breast"), selection: $breast) {
                            ForEach(breastOptions, id: \.self) { option in
                                Text(option)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    Section(String(localized: "form_duration")) {
                        TextField(String(localized: "unit_minutes"), text: $duration)
                            .keyboardType(.numberPad)
                    }
                } else {
                    Section(String(localized: "feeding_volume")) {
                        TextField(String(localized: "placeholder_volume_ml"), text: $volume)
                            .keyboardType(.numberPad)
                    }
                }

                Section(String(localized: "form_notes")) {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
            }
            .navigationTitle(String(localized: "feeding_new"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "save")) { saveFeeding() }
                }
            }
        }
    }

    private func saveFeeding() {
        guard let childId = childViewModel.selectedChild?.id else { return }

        Task {
            await viewModel.addFeeding(
                childId: childId,
                timestamp: timestamp,
                feedingType: feedingType,
                duration: Int32(duration) ?? 0,
                volume: Double(volume) ?? 0,
                breast: feedingType == String(localized: "feeding_type_breast_feeding") ? breast : nil,
                notes: notes.isEmpty ? nil : notes
            )
            dismiss()
        }
    }
}
