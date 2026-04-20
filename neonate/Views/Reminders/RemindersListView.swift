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
        .navigationTitle("Напоминания")
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
        .alert("Удалить напоминание?", isPresented: $showingDeleteAlert) {
            Button("Отмена", role: .cancel) {
                reminderToDelete = nil
            }
            Button("Удалить", role: .destructive) {
                if let reminder = reminderToDelete {
                    deleteReminder(reminder)
                }
            }
        } message: {
            Text("Это действие нельзя отменить")
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

                    Text("Уведомления отключены")
                        .font(.headline)
                }

                Text("Для работы напоминаний необходимо разрешение на уведомления")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Button {
                    if viewModel.notificationPermissionStatus == .denied {
                        viewModel.openAppSettings()
                    } else {
                        showingPermissionView = true
                    }
                } label: {
                    Text(viewModel.notificationPermissionStatus == .denied ? "Открыть настройки" : "Разрешить уведомления")
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
                    Text("Нет напоминаний")
                        .font(.headline)

                    Text("Создайте напоминания для отслеживания времени кормления, сна и смены подгузников")
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
                    Label("Добавить напоминание", systemImage: "plus.circle.fill")
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
            Text("Активные напоминания (\(viewModel.activeRemindersCount))")
        }
    }

    private var infoSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                InfoRow(
                    icon: "info.circle.fill",
                    text: "Напоминания будут приходить на основе установленного интервала"
                )

                InfoRow(
                    icon: "arrow.clockwise",
                    text: "После добавления события напоминание автоматически перепланируется"
                )

                InfoRow(
                    icon: "hand.tap.fill",
                    text: "Нажмите на напоминание для редактирования или смахните для удаления"
                )
            }
        } header: {
            Text("Информация")
        }
    }

    private var noChildSelectedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.fill.questionmark")
                .font(.system(size: 80))
                .foregroundColor(.secondary)

            Text("Выберите ребенка")
                .font(.title)
                .fontWeight(.bold)

            Text("Для настройки напоминаний необходимо выбрать профиль ребенка")
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
