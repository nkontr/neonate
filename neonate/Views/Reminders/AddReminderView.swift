import SwiftUI

struct AddReminderView: View {

    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: ReminderViewModel

    @State private var selectedType: ReminderManager.ReminderType = .feeding
    @State private var intervalHours: Int = 3
    @State private var intervalMinutes: Int = 0
    @State private var isSaving: Bool = false

    var body: some View {
        NavigationView {
            Form {

                Section(String(localized: "reminder_type_section")) {
                    Picker(String(localized: "reminder_type_label"), selection: $selectedType) {
                        ForEach(ReminderManager.ReminderType.allCases, id: \.self) { type in
                            Label(type.displayName, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section {
                    Stepper(String(format: NSLocalizedString("reminder_hours", comment: ""), intervalHours), value: $intervalHours, in: 0...24)
                    Stepper(String(format: NSLocalizedString("reminder_minutes", comment: ""), intervalMinutes), value: $intervalMinutes, in: 0...55, step: 5)
                } header: {
                    Text(String(localized: "reminder_interval_section"))
                } footer: {
                    Text(String(format: NSLocalizedString("reminder_interval_footer", comment: ""), totalIntervalText))
                }

                if viewModel.notificationPermissionStatus != .authorized {
                    Section {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(String(localized: "notifications_disabled"))
                                    .font(.headline)

                                Text(String(localized: "notifications_required"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle(String(localized: "reminder_new_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "cancel")) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "reminder_add_button")) {
                        saveReminder()
                    }
                    .disabled(!isValid || isSaving)
                }
            }
            .disabled(isSaving)
        }
    }

    private var totalIntervalMinutes: Int {
        return (intervalHours * 60) + intervalMinutes
    }

    private var totalIntervalText: String {
        if totalIntervalMinutes == 0 {
            return String(localized: "zero_minutes")
        }

        var components: [String] = []

        if intervalHours > 0 {
            let hoursStr = String(format: NSLocalizedString("hours_short", comment: ""), intervalHours)
            components.append(hoursStr)
        }

        if intervalMinutes > 0 {
            let minsStr = String(format: NSLocalizedString("minutes_short", comment: ""), intervalMinutes)
            components.append(minsStr)
        }

        return components.joined(separator: " ")
    }

    private var isValid: Bool {
        return totalIntervalMinutes >= 5
    }

    private func saveReminder() {
        guard viewModel.canCreateReminder(
            type: selectedType,
            intervalMinutes: totalIntervalMinutes
        ) else {
            return
        }

        isSaving = true

        Task {
            await viewModel.createReminder(
                type: selectedType,
                intervalMinutes: totalIntervalMinutes
            )

            isSaving = false

            if viewModel.errorMessage == nil {
                dismiss()
            }
        }
    }
}

#if DEBUG
struct AddReminderView_Previews: PreviewProvider {
    static var previews: some View {
        AddReminderView(viewModel: ReminderViewModel.preview)
    }
}
#endif
