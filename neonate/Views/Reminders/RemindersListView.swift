import SwiftUI
import CoreData

struct RemindersListView: View {

    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var childProfileViewModel: ChildProfileViewModel

    @StateObject private var viewModel: ReminderViewModel
    @State private var showingAddReminder = false
    @State private var showingPermissionView = false
    @State private var reminderToEdit: ReminderSchedule?

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
    }

    private var remindersList: some View {
        List {

            if viewModel.notificationPermissionStatus != .authorized {
                permissionSection
            }

            if viewModel.reminders.isEmpty {
                emptyStateSection
                    .transition(.opacity)
            } else {
                remindersSection
                    .transition(.opacity)
            }

            infoSection
        }
        .listStyle(.insetGrouped)
        .animation(.easeInOut(duration: 0.3), value: viewModel.reminders.isEmpty)
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
            VStack(spacing: 20) {
                Spacer()
                    .frame(height: 20)

                Image(systemName: "bell.slash.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)

                VStack(spacing: 8) {
                    Text(String(localized: "no_reminders"))
                        .font(.headline)
                        .frame(maxWidth: .infinity)

                    Text(String(localized: "no_reminders_message"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 24)
                }
                .frame(maxWidth: .infinity)

                Button {
                    if viewModel.notificationPermissionStatus == .authorized {
                        showingAddReminder = true
                    } else {
                        showingPermissionView = true
                    }
                } label: {
                    Text(String(localized: "add_reminder"))
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .padding(.horizontal, 16)
                .padding(.top, 4)

                Spacer()
                    .frame(height: 20)
            }
            .frame(maxWidth: .infinity)
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
                            Task {
                                await viewModel.deleteReminder(reminder)
                            }
                        } label: {
                            Label("Удалить", systemImage: "trash")
                        }
                    }
                    .id(reminder.id)
            }
            .animation(.easeInOut(duration: 0.3), value: viewModel.reminders)
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
