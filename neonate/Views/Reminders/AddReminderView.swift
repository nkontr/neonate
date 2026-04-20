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

                Section("Тип напоминания") {
                    Picker("Тип", selection: $selectedType) {
                        ForEach(ReminderManager.ReminderType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: type.icon)
                                Text(type.displayName)
                            }
                            .tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    Stepper("Часы: \(intervalHours)", value: $intervalHours, in: 0...24)
                    Stepper("Минуты: \(intervalMinutes)", value: $intervalMinutes, in: 0...55, step: 5)
                } header: {
                    Text("Интервал напоминания")
                } footer: {
                    Text("Напоминание будет приходить каждые \(totalIntervalText)")
                }

                if viewModel.notificationPermissionStatus != .authorized {
                    Section {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Уведомления отключены")
                                    .font(.headline)

                                Text("Для работы напоминаний необходимо разрешение на уведомления")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Новое напоминание")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Добавить") {
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
            return "0 минут"
        }

        var components: [String] = []

        if intervalHours > 0 {
            components.append("\(intervalHours) ч")
        }

        if intervalMinutes > 0 {
            components.append("\(intervalMinutes) мин")
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
