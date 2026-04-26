import SwiftUI
import CoreData

struct RemindersListView: View {

    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var childProfileViewModel: ChildProfileViewModel

    @StateObject private var viewModel: ReminderViewModel
    @State private var showingAddReminder = false
    @State private var showingPermissionView = false
    @State private var reminderToEdit: ReminderSchedule?
    @State private var reminderToDelete: ReminderSchedule?
    @State private var showingDeleteAlert = false

    init(context: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: ReminderViewModel(context: context))
    }

    var body: some View {
        Group {
            if let selectedChild = childProfileViewModel.selectedChild {
                remindersList
                    .onAppear {
                        viewModel.loadReminders(for: selectedChild.id!)
                        checkPermissions()
                    }
                    .refreshable {
                        viewModel.refreshReminders()
                    }
            } else {
                noChildSelectedView
            }
        }
        .navigationTitle(String(localized: "reminders_title"))
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if childProfileViewModel.selectedChild != nil {
                    Button {
                        if viewModel.notificationPermissionStatus == .authorized {
                            showingAddReminder = true
                        } else {
                            showingPermissionView = true
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddReminder) {
            AddReminderView(viewModel: viewModel)
        }
        .sheet(item: $reminderToEdit) { reminder in
            EditReminderView(viewModel: viewModel, reminder: reminder)
        }
        .sheet(isPresented: $showingPermissionView) {
            NotificationPermissionView(viewModel: viewModel)
        }
        .alert(String(localized: "delete_reminder"), isPresented: $showingDeleteAlert) {
            Button(String(localized: "cancel"), role: .cancel) {
                reminderToDelete = nil
            }
            Button(String(localized: "action_delete"), role: .destructive) {
                if let reminder = reminderToDelete {
                    deleteReminder(reminder)
                }
            }
        } message: {
            Text(String(localized: "delete_reminder_message"))
        }
    }

    private var remindersList: some View {
        List {

            if viewModel.notificationPermissionStatus != .authorized {
                permissionSection
            }

            if viewModel.reminders.isEmpty {
                emptyStateSection
            } else {
                remindersSection
            }

            infoSection
        }
        .listStyle(.insetGrouped)
    }

    private var permissionSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)

                    Text(String(localized: "notifications_disabled"))
                        .font(.headline)
                }

                Text(String(localized: "notifications_required"))
                    .font(.caption)
                    .foregroundColor(.secondary)

                Button {
                    if viewModel.notificationPermissionStatus == .denied {
                        viewModel.openAppSettings()
                    } else {
                        showingPermissionView = true
                    }
                } label: {
                    Text(viewModel.notificationPermissionStatus == .denied ? String(localized: "open_settings") : String(localized: "allow_notifications"))
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                .padding(.top, 4)
            }
            .padding(.vertical, 8)
        }
    }

    private var emptyStateSection: some View {
        Section {
            VStack(spacing: 16) {
                Image(systemName: "bell.slash.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.secondary)

                VStack(spacing: 8) {
                    Text(String(localized: "no_reminders"))
                        .font(.headline)

                    Text(String(localized: "no_reminders_message"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                Button {
                    if viewModel.notificationPermissionStatus == .authorized {
                        showingAddReminder = true
                    } else {
                        showingPermissionView = true
                    }
                } label: {
                    Label(String(localized: "add_reminder"), systemImage: "plus.circle.fill")
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
        }
    }

    private var remindersSection: some View {
        Section {
            ForEach(viewModel.reminders, id: \.id) { reminder in
                ReminderRow(reminder: reminder, viewModel: viewModel)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        reminderToEdit = reminder
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            reminderToDelete = reminder
                            showingDeleteAlert = true
                        } label: {
                            Label("Удалить", systemImage: "trash")
                        }
                    }
            }
        } header: {
            Text(String(format: NSLocalizedString("active_reminders", comment: ""), viewModel.activeRemindersCount))
        }
    }

    private var infoSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                InfoRow(
                    icon: "info.circle.fill",
                    text: String(localized: "reminder_info_interval")
                )

                InfoRow(
                    icon: "arrow.clockwise",
                    text: String(localized: "reminder_info_reschedule")
                )

                InfoRow(
                    icon: "hand.tap.fill",
                    text: String(localized: "reminder_info_edit")
                )
            }
        } header: {
            Text(String(localized: "reminder_info_title"))
        }
    }

    private var noChildSelectedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.fill.questionmark")
                .font(.system(size: 80))
                .foregroundColor(.secondary)

            Text(String(localized: "select_child_title"))
                .font(.title)
                .fontWeight(.bold)

            Text(String(localized: "select_child_message"))
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }

    private func checkPermissions() {
        viewModel.checkNotificationPermission()
    }

    private func deleteReminder(_ reminder: ReminderSchedule) {
        Task {
            await viewModel.deleteReminder(reminder)
            reminderToDelete = nil
        }
    }
}

struct InfoRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)

            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#if DEBUG
struct RemindersListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            RemindersListView(context: PersistenceController.preview.container.viewContext)
                .environmentObject(ChildProfileViewModel(context: PersistenceController.preview.container.viewContext))
        }
    }
}
#endif
