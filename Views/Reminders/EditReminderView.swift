import SwiftUI

struct EditReminderView: View {

    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: ReminderViewModel

    let reminder: ReminderSchedule

    @State private var intervalHours: Int = 0
    @State private var intervalMinutes: Int = 0
    @State private var isSaving: Bool = false

    var body: some View {
        NavigationView {
            Form {

                Section("Тип напоминания") {
                    if let type = viewModel.getReminderType(reminder) {
                        HStack {
                            Image(systemName: type.icon)
                                .foregroundColor(.blue)

                            Text(type.displayName)
                                .font(.headline)

                            Spacer()

                            Text("Нельзя изменить")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section {
                    Stepper("Часы: \(intervalHours)", value: $intervalHours, in: 0...24)
                    Stepper("Минуты: \(intervalMinutes)", value: $intervalMinutes, in: 0...55, step: 5)
                } header: {
                    Text("Интервал напоминания")
                } footer: {
                    Text("Напоминание будет приходить каждые \(totalIntervalText)")
                }

                if let lastTriggered = reminder.lastTriggered {
                    Section("Информация") {
                        HStack {
                            Text("Последнее срабатывание")
                            Spacer()
                            Text(formatDate(lastTriggered))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Редактировать")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        saveChanges()
                    }
                    .disabled(!isValid || isSaving)
                }
            }
            .disabled(isSaving)
            .onAppear {
                setupInitialValues()
            }
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

    private func setupInitialValues() {
        let totalMinutes = Int(reminder.intervalMinutes)
        intervalHours = totalMinutes / 60
        intervalMinutes = totalMinutes % 60
    }

    private func saveChanges() {
        isSaving = true

        Task {
            await viewModel.updateReminder(
                reminder,
                intervalMinutes: totalIntervalMinutes
            )

            isSaving = false

            if viewModel.errorMessage == nil {
                dismiss()
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#if DEBUG
struct EditReminderView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let reminder = ReminderSchedule(context: context)
        reminder.id = UUID()
        reminder.reminderType = "feeding"
        reminder.intervalMinutes = 180
        reminder.isEnabled = true
        reminder.lastTriggered = Date().addingTimeInterval(-3600)

        return EditReminderView(
            viewModel: ReminderViewModel.preview,
            reminder: reminder
        )
    }
}
#endif
