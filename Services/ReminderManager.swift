import Foundation
import CoreData
import UserNotifications

class ReminderManager {

    static let shared = ReminderManager()

    private init() {}

    private let notificationService = NotificationService.shared
    private let reminderRepository = ReminderRepository(
        context: PersistenceController.shared.container.viewContext
    )

    enum ReminderType: String, CaseIterable {
        case feeding = "feeding"
        case sleep = "sleep"
        case diaper = "diaper"

        var displayName: String {
            switch self {
            case .feeding:
                return "Кормление"
            case .sleep:
                return "Сон"
            case .diaper:
                return "Подгузник"
            }
        }

        var icon: String {
            switch self {
            case .feeding:
                return "fork.knife"
            case .sleep:
                return "moon.zzz.fill"
            case .diaper:
                return "list.clipboard.fill"
            }
        }

        var notificationCategory: NotificationCategory {
            switch self {
            case .feeding:
                return .feedingReminder
            case .sleep:
                return .sleepReminder
            case .diaper:
                return .diaperReminder
            }
        }

        func notificationTitle(childName: String) -> String {
            switch self {
            case .feeding:
                return "Время кормления"
            case .sleep:
                return "Время сна"
            case .diaper:
                return "Время менять подгузник"
            }
        }

        func notificationBody(childName: String) -> String {
            switch self {
            case .feeding:
                return "Пора покормить \(childName)"
            case .sleep:
                return "Пора уложить \(childName) спать"
            case .diaper:
                return "Пора проверить подгузник у \(childName)"
            }
        }
    }

    func createReminder(
        type: ReminderType,
        intervalMinutes: Int,
        childId: UUID
    ) async throws -> ReminderSchedule {

        let reminder = try await reminderRepository.createReminderSchedule(
            childId: childId,
            reminderType: type.rawValue,
            intervalMinutes: Int32(intervalMinutes),
            isEnabled: true
        )

        await scheduleNextReminder(for: reminder)

        return reminder
    }

    func updateReminder(
        id: UUID,
        intervalMinutes: Int? = nil,
        enabled: Bool? = nil
    ) async throws {
        guard let reminder = reminderRepository.fetchReminder(by: id) else {
            throw NSError(
                domain: "ReminderManager",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "Напоминание не найдено"]
            )
        }

        cancelNotification(for: reminder)

        try await reminderRepository.updateReminderSchedule(
            reminder,
            intervalMinutes: intervalMinutes.map { Int32($0) },
            isEnabled: enabled
        )

        if reminder.isEnabled {
            await scheduleNextReminder(for: reminder)
        }
    }

    func deleteReminder(id: UUID) async throws {
        guard let reminder = reminderRepository.fetchReminder(by: id) else {
            throw NSError(
                domain: "ReminderManager",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "Напоминание не найдено"]
            )
        }

        cancelNotification(for: reminder)

        try await reminderRepository.deleteReminderSchedule(reminder)
    }

    func toggleReminder(_ reminder: ReminderSchedule, enabled: Bool) async throws {

        cancelNotification(for: reminder)

        try await reminderRepository.toggleReminder(reminder, enabled: enabled)

        if enabled {
            await scheduleNextReminder(for: reminder)
        }
    }

    func scheduleNextReminder(for reminder: ReminderSchedule) async {
        guard reminder.isEnabled else { return }

        let childName = await getChildName(for: reminder.childId ?? UUID())

        guard let reminderType = ReminderType(rawValue: reminder.reminderType ?? "") else {
            print("Неизвестный тип напоминания: \(reminder.reminderType ?? "")")
            return
        }

        let nextTriggerDate: Date
        if let lastTriggered = reminder.lastTriggered {

            nextTriggerDate = lastTriggered.addingTimeInterval(TimeInterval(reminder.intervalMinutes * 60))
        } else {

            nextTriggerDate = Date().addingTimeInterval(TimeInterval(reminder.intervalMinutes * 60))
        }

        let timeInterval: TimeInterval
        if nextTriggerDate > Date() {
            timeInterval = nextTriggerDate.timeIntervalSince(Date())
        } else {
            timeInterval = TimeInterval(reminder.intervalMinutes * 60)
        }

        let identifier = "reminder_\(reminder.id?.uuidString ?? UUID().uuidString)"
        notificationService.scheduleNotification(
            title: reminderType.notificationTitle(childName: childName),
            body: reminderType.notificationBody(childName: childName),
            timeInterval: timeInterval,
            identifier: identifier,
            category: reminderType.notificationCategory
        )

        print("Запланировано напоминание \(identifier) на \(Date().addingTimeInterval(timeInterval))")
    }

    func rescheduleAllReminders(for childId: UUID) async {
        let reminders = reminderRepository.fetchActiveReminders(for: childId)

        for reminder in reminders {

            cancelNotification(for: reminder)

            await scheduleNextReminder(for: reminder)
        }
    }

    func updateLastTriggeredAfterEvent(childId: UUID, type: ReminderType) async throws {
        let reminders = reminderRepository.fetchActiveReminders(for: childId, type: type.rawValue)

        for reminder in reminders {

            try await reminderRepository.updateLastTriggered(reminder, timestamp: Date())

            cancelNotification(for: reminder)

            await scheduleNextReminder(for: reminder)
        }
    }

    private func cancelNotification(for reminder: ReminderSchedule) {
        let identifier = "reminder_\(reminder.id?.uuidString ?? "")"
        notificationService.cancelNotification(withIdentifier: identifier)
    }

    private func getChildName(for childId: UUID) async -> String {
        let context = PersistenceController.shared.container.viewContext
        let fetchRequest: NSFetchRequest<ChildProfile> = ChildProfile.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", childId as CVarArg)

        do {
            let children = try context.fetch(fetchRequest)
            return children.first?.name ?? "малыша"
        } catch {
            print("Ошибка получения имени ребенка: \(error)")
            return "малыша"
        }
    }

    func fetchReminders(for childId: UUID) -> [ReminderSchedule] {
        return reminderRepository.fetchReminders(for: childId)
    }

    func fetchActiveReminders(for childId: UUID) -> [ReminderSchedule] {
        return reminderRepository.fetchActiveReminders(for: childId)
    }
}
