import Foundation
import SwiftUI
import CoreData
import Combine
import UserNotifications

@MainActor
class ReminderViewModel: ObservableObject {

    @Published var reminders: [ReminderSchedule] = []
    @Published var notificationPermissionStatus: UNAuthorizationStatus = .notDetermined
    private var isLoading: Bool = false
    @Published var errorMessage: String?

    private let reminderManager = ReminderManager.shared
    private let notificationService = NotificationService.shared
    private let context: NSManagedObjectContext
    private var cancellables = Set<AnyCancellable>()

    var currentChildId: UUID?

    init(context: NSManagedObjectContext) {
        self.context = context
        checkNotificationPermission()
    }

    func checkNotificationPermission() {
        notificationService.checkAuthorizationStatus { [weak self] status in
            self?.notificationPermissionStatus = status
        }
    }

    func requestNotificationPermission() async {
        await withCheckedContinuation { continuation in
            notificationService.requestAuthorization { [weak self] granted, error in
                if let error = error {
                    self?.errorMessage = String(format: NSLocalizedString("reminder_error_request", comment: ""), error.localizedDescription)
                }

                self?.checkNotificationPermission()
                continuation.resume()
            }
        }
    }

    func openAppSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl)
            }
        }
    }

    func loadReminders(for childId: UUID) {
        currentChildId = childId
        reminders = reminderManager.fetchReminders(for: childId)
    }

    func refreshReminders() {
        guard let childId = currentChildId else { return }
        loadReminders(for: childId)
    }

    func createReminder(type: ReminderManager.ReminderType, intervalMinutes: Int) async {
        guard let childId = currentChildId else {
            errorMessage = String(localized: "reminder_error_no_child")
            return
        }

        if notificationPermissionStatus != .authorized {
            await requestNotificationPermission()
            if notificationPermissionStatus != .authorized {
                errorMessage = String(localized: "reminder_error_permission")
                return
            }
        }

        isLoading = true
        errorMessage = nil

        do {
            _ = try await reminderManager.createReminder(
                type: type,
                intervalMinutes: intervalMinutes,
                childId: childId
            )

            refreshReminders()
        } catch {
            errorMessage = String(format: NSLocalizedString("reminder_error_create", comment: ""), error.localizedDescription)
        }

        isLoading = false
    }

    func updateReminder(_ reminder: ReminderSchedule, intervalMinutes: Int) async {
        guard let reminderId = reminder.id else { return }

        isLoading = true
        errorMessage = nil

        do {
            try await reminderManager.updateReminder(
                id: reminderId,
                intervalMinutes: intervalMinutes
            )

            refreshReminders()
        } catch {
            errorMessage = "Ошибка обновления напоминания: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func deleteReminder(_ reminder: ReminderSchedule) async {
        guard let reminderId = reminder.id else { return }

        // Remove locally first — single instant UI update
        await MainActor.run {
            reminders.removeAll { $0.id == reminderId }
        }

        // Then delete from CoreData silently
        do {
            try await reminderManager.deleteReminder(id: reminderId)
        } catch {
            // If failed — restore by reloading
            errorMessage = "Ошибка удаления напоминания: \(error.localizedDescription)"
            refreshReminders()
        }
    }

    func toggleReminder(_ reminder: ReminderSchedule, enabled: Bool) async {
        do {
            try await reminderManager.toggleReminder(reminder, enabled: enabled)
            refreshReminders()
        } catch {
            errorMessage = "Ошибка переключения напоминания: \(error.localizedDescription)"
        }
    }

    func getReminderType(_ reminder: ReminderSchedule) -> ReminderManager.ReminderType? {
        guard let typeString = reminder.reminderType else { return nil }
        return ReminderManager.ReminderType(rawValue: typeString)
    }

    func getFormattedInterval(_ reminder: ReminderSchedule) -> String {
        let minutes = Int(reminder.intervalMinutes)

        if minutes < 60 {
            return String(format: String(localized: "minutes_short"), minutes)
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60

            if remainingMinutes == 0 {
                return String(format: String(localized: "hours_short"), hours)
            } else {
                let hoursStr = String(format: String(localized: "hours_short"), hours)
                let minutesStr = String(format: String(localized: "minutes_short"), remainingMinutes)
                return "\(hoursStr) \(minutesStr)"
            }
        }
    }

    var hasActiveReminders: Bool {
        return reminders.contains(where: { $0.isEnabled })
    }

    var activeRemindersCount: Int {
        return reminders.filter { $0.isEnabled }.count
    }

    func canCreateReminder(type: ReminderManager.ReminderType, intervalMinutes: Int) -> Bool {

        if intervalMinutes < 5 {
            errorMessage = String(localized: "reminder_error_min_interval")
            return false
        }

        if intervalMinutes > 1440 {
            errorMessage = String(localized: "reminder_error_max_interval")
            return false
        }

        return true
    }
}

#if DEBUG
extension ReminderViewModel {
    static var preview: ReminderViewModel {
        let viewModel = ReminderViewModel(context: PersistenceController.preview.container.viewContext)
        return viewModel
    }
}
#endif
