import Foundation
import CoreData
import Combine

class ReminderRepository: BaseRepository<ReminderSchedule> {

    func createReminderSchedule(
        childId: UUID,
        reminderType: String,
        intervalMinutes: Int32,
        isEnabled: Bool = true
    ) async throws -> ReminderSchedule {
        let reminder = create()
        reminder.id = UUID()
        reminder.childId = childId
        reminder.reminderType = reminderType
        reminder.intervalMinutes = intervalMinutes
        reminder.isEnabled = isEnabled
        reminder.lastTriggered = nil

        try await PersistenceController.shared.saveContext(context)
        return reminder
    }

    func updateReminderSchedule(
        _ reminder: ReminderSchedule,
        reminderType: String? = nil,
        intervalMinutes: Int32? = nil,
        isEnabled: Bool? = nil
    ) async throws {
        if let reminderType = reminderType { reminder.reminderType = reminderType }
        if let intervalMinutes = intervalMinutes { reminder.intervalMinutes = intervalMinutes }
        if let isEnabled = isEnabled { reminder.isEnabled = isEnabled }

        try await PersistenceController.shared.saveContext(context)
    }

    func toggleReminder(_ reminder: ReminderSchedule, enabled: Bool) async throws {
        reminder.isEnabled = enabled
        try await PersistenceController.shared.saveContext(context)
    }

    func updateLastTriggered(_ reminder: ReminderSchedule, timestamp: Date = Date()) async throws {
        reminder.lastTriggered = timestamp
        try await PersistenceController.shared.saveContext(context)
    }

    func deleteReminderSchedule(_ reminder: ReminderSchedule) async throws {
        delete(reminder)
        try await PersistenceController.shared.saveContext(context)
    }

    func fetchReminders(for childId: UUID) -> [ReminderSchedule] {
        let predicate = NSPredicate(format: "childId == %@", childId as CVarArg)
        let sortDescriptor = NSSortDescriptor(key: "reminderType", ascending: true)
        return fetch(sortedBy: [sortDescriptor], predicate: predicate)
    }

    func fetchActiveReminders(for childId: UUID) -> [ReminderSchedule] {
        let predicate = NSPredicate(format: "childId == %@ AND isEnabled == YES", childId as CVarArg)
        let sortDescriptor = NSSortDescriptor(key: "reminderType", ascending: true)
        return fetch(sortedBy: [sortDescriptor], predicate: predicate)
    }

    func fetchReminders(for childId: UUID, type reminderType: String) -> [ReminderSchedule] {
        let predicate = NSPredicate(format: "childId == %@ AND reminderType == %@", childId as CVarArg, reminderType)
        let sortDescriptor = NSSortDescriptor(key: "intervalMinutes", ascending: true)
        return fetch(sortedBy: [sortDescriptor], predicate: predicate)
    }

    func fetchActiveReminders(for childId: UUID, type reminderType: String) -> [ReminderSchedule] {
        let predicate = NSPredicate(
            format: "childId == %@ AND reminderType == %@ AND isEnabled == YES",
            childId as CVarArg,
            reminderType
        )
        let sortDescriptor = NSSortDescriptor(key: "intervalMinutes", ascending: true)
        return fetch(sortedBy: [sortDescriptor], predicate: predicate)
    }

    func fetchReminder(by id: UUID) -> ReminderSchedule? {
        let predicate = NSPredicate(format: "id == %@", id as CVarArg)
        return fetch(with: predicate).first
    }

    func shouldTrigger(_ reminder: ReminderSchedule) -> Bool {
        guard reminder.isEnabled else { return false }

        guard let lastTriggered = reminder.lastTriggered else {
            return true
        }

        let intervalSeconds = TimeInterval(reminder.intervalMinutes * 60)
        let nextTriggerTime = lastTriggered.addingTimeInterval(intervalSeconds)

        return Date() >= nextTriggerTime
    }

    func getTimeUntilNextTrigger(_ reminder: ReminderSchedule) -> Int? {
        guard reminder.isEnabled else { return nil }

        guard let lastTriggered = reminder.lastTriggered else {
            return 0
        }

        let intervalSeconds = TimeInterval(reminder.intervalMinutes * 60)
        let nextTriggerTime = lastTriggered.addingTimeInterval(intervalSeconds)
        let timeRemaining = nextTriggerTime.timeIntervalSince(Date())

        if timeRemaining <= 0 {
            return 0
        }

        return Int(timeRemaining / 60)
    }

    func fetchRemindersDueToTrigger(for childId: UUID) -> [ReminderSchedule] {
        let activeReminders = fetchActiveReminders(for: childId)
        return activeReminders.filter { shouldTrigger($0) }
    }

    func getActiveReminderCount(for childId: UUID) -> Int {
        return fetchActiveReminders(for: childId).count
    }

    func getReminderTypeStatistics(for childId: UUID) -> [String: Int] {
        let reminders = fetchReminders(for: childId)
        var statistics: [String: Int] = [:]

        for reminder in reminders {
            let type = reminder.reminderType ?? "Unknown"
            statistics[type, default: 0] += 1
        }

        return statistics
    }

    func getAverageReminderInterval(for childId: UUID) -> Double {
        let reminders = fetchReminders(for: childId)
        guard !reminders.isEmpty else { return 0.0 }

        let totalInterval = reminders.reduce(0.0) { $0 + Double($1.intervalMinutes) }
        return totalInterval / Double(reminders.count)
    }

    func enableAllReminders(for childId: UUID) async throws {
        let reminders = fetchReminders(for: childId)
        for reminder in reminders {
            reminder.isEnabled = true
        }
        try await PersistenceController.shared.saveContext(context)
    }

    func disableAllReminders(for childId: UUID) async throws {
        let reminders = fetchReminders(for: childId)
        for reminder in reminders {
            reminder.isEnabled = false
        }
        try await PersistenceController.shared.saveContext(context)
    }

    func resetAllTriggers(for childId: UUID) async throws {
        let reminders = fetchReminders(for: childId)
        for reminder in reminders {
            reminder.lastTriggered = nil
        }
        try await PersistenceController.shared.saveContext(context)
    }
}
