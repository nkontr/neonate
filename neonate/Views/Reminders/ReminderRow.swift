import SwiftUI

struct ReminderRow: View {

    let reminder: ReminderSchedule
    @ObservedObject var viewModel: ReminderViewModel

    var body: some View {
        HStack(spacing: 12) {

            Image(systemName: viewModel.getReminderType(reminder)?.icon ?? "bell")
                .font(.title3)
                .foregroundColor(reminder.isEnabled ? .blue : .gray)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.getReminderType(reminder)?.displayName ?? "")
                    .font(.headline)
                    .foregroundColor(reminder.isEnabled ? .primary : .secondary)

                Text(String(format: NSLocalizedString("reminder_every", comment: ""), viewModel.getFormattedInterval(reminder)))
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if let lastTriggered = reminder.lastTriggered {
                    Text(String(format: NSLocalizedString("reminder_last", comment: ""), formatDate(lastTriggered)))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { reminder.isEnabled },
                set: { newValue in
                    Task {
                        await viewModel.toggleReminder(reminder, enabled: newValue)
                    }
                }
            ))
            .labelsHidden()
        }
        .padding(.vertical, 8)
        .frame(minHeight: 60, alignment: .center)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#if DEBUG
struct ReminderRow_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let reminder = ReminderSchedule(context: context)
        reminder.id = UUID()
        reminder.reminderType = "feeding"
        reminder.intervalMinutes = 180
        reminder.isEnabled = true
        reminder.lastTriggered = Date().addingTimeInterval(-3600)

        return List {
            ReminderRow(
                reminder: reminder,
                viewModel: ReminderViewModel.preview
            )
        }
        .listStyle(.insetGrouped)
    }
}
#endif
