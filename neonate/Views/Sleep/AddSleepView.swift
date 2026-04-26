import SwiftUI

struct AddSleepView: View {

    @Environment(\.dismiss) private var dismiss

    @ObservedObject var viewModel: SleepViewModel
    @ObservedObject var childViewModel: ChildProfileViewModel

    @State private var startTime: Date = Date().addingTimeInterval(-3600)
    @State private var endTime: Date = Date()
    @State private var quality: String = String(localized: "sleep_quality_good")
    @State private var location: String = String(localized: "sleep_location_crib")
    @State private var notes: String = ""

    var qualityOptions: [String] {
        [
            String(localized: "sleep_quality_excellent"),
            String(localized: "sleep_quality_good"),
            String(localized: "sleep_quality_normal"),
            String(localized: "sleep_quality_restless")
        ]
    }

    var locationOptions: [String] {
        [
            String(localized: "sleep_location_crib"),
            String(localized: "sleep_location_stroller"),
            String(localized: "sleep_location_arms"),
            String(localized: "sleep_location_car")
        ]
    }

    var body: some View {
        NavigationView {
            Form {
                Section(String(localized: "form_time_label")) {
                    DatePicker(String(localized: "sleep_start"), selection: $startTime)
                    DatePicker(String(localized: "sleep_end"), selection: $endTime)

                    HStack {
                        Text(String(localized: "form_duration"))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(calculateDuration())
                            .fontWeight(.medium)
                    }
                }

                Section(String(localized: "form_quality")) {
                    Picker(String(localized: "form_quality"), selection: $quality) {
                        ForEach(qualityOptions, id: \.self) { option in
                            Text(option)
                        }
                    }
                }

                Section(String(localized: "form_location")) {
                    Picker(String(localized: "sleep_location"), selection: $location) {
                        ForEach(locationOptions, id: \.self) { option in
                            Text(option)
                        }
                    }
                }

                Section(String(localized: "form_notes")) {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
            }
            .navigationTitle(String(localized: "sleep_add"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "save")) { saveSleep() }
                        .disabled(endTime <= startTime)
                }
            }
        }
    }

    private func calculateDuration() -> String {
        let duration = endTime.timeIntervalSince(startTime)
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        return String(localized: "duration_short_format").replacingOccurrences(of: "%d", with: "\(hours)").replacingOccurrences(of: "%d", with: "\(minutes)")
    }

    private func saveSleep() {
        guard let childId = childViewModel.selectedChild?.id else { return }
        Task {
            await viewModel.addSleep(
                childId: childId,
                startTime: startTime,
                endTime: endTime,
                quality: quality,
                location: location,
                notes: notes.isEmpty ? nil : notes
            )
            dismiss()
        }
    }
}
