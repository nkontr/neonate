import Foundation
import CoreData
import Combine

class DiaperEventRepository: BaseRepository<DiaperEvent> {

    func createDiaperEvent(
        childId: UUID,
        timestamp: Date = Date(),
        diaperType: String,
        notes: String? = nil
    ) async throws -> DiaperEvent {
        let event = create()
        event.id = UUID()
        event.childId = childId
        event.timestamp = timestamp
        event.diaperType = diaperType
        event.notes = notes

        try await PersistenceController.shared.saveContext(context)
        return event
    }

    func updateDiaperEvent(
        _ event: DiaperEvent,
        timestamp: Date? = nil,
        diaperType: String? = nil,
        notes: String? = nil
    ) async throws {
        if let timestamp = timestamp { event.timestamp = timestamp }
        if let diaperType = diaperType { event.diaperType = diaperType }
        if let notes = notes { event.notes = notes }

        try await PersistenceController.shared.saveContext(context)
    }

    func deleteDiaperEvent(_ event: DiaperEvent) async throws {
        delete(event)
        try await PersistenceController.shared.saveContext(context)
    }

    func fetchDiaperEvents(for childId: UUID, ascending: Bool = false) -> [DiaperEvent] {
        let predicate = NSPredicate(format: "childId == %@", childId as CVarArg)
        let sortDescriptor = NSSortDescriptor(key: "timestamp", ascending: ascending)
        return fetch(sortedBy: [sortDescriptor], predicate: predicate)
    }

    func fetchDiaperEvents(for childId: UUID, from startDate: Date, to endDate: Date) -> [DiaperEvent] {
        let predicate = NSPredicate(
            format: "childId == %@ AND timestamp >= %@ AND timestamp <= %@",
            childId as CVarArg,
            startDate as CVarArg,
            endDate as CVarArg
        )
        let sortDescriptor = NSSortDescriptor(key: "timestamp", ascending: false)
        return fetch(sortedBy: [sortDescriptor], predicate: predicate)
    }

    func fetchDiaperEvents(for childId: UUID, type diaperType: String) -> [DiaperEvent] {
        let predicate = NSPredicate(format: "childId == %@ AND diaperType == %@", childId as CVarArg, diaperType)
        let sortDescriptor = NSSortDescriptor(key: "timestamp", ascending: false)
        return fetch(sortedBy: [sortDescriptor], predicate: predicate)
    }

    func fetchLastDiaperEvent(for childId: UUID) -> DiaperEvent? {
        let predicate = NSPredicate(format: "childId == %@", childId as CVarArg)
        let sortDescriptor = NSSortDescriptor(key: "timestamp", ascending: false)
        let events = fetch(sortedBy: [sortDescriptor], predicate: predicate)
        return events.first
    }

    func fetchTodayDiaperEvents(for childId: UUID) -> [DiaperEvent] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()

        return fetchDiaperEvents(for: childId, from: startOfDay, to: endOfDay)
    }

    func fetchDiaperEvents(for childId: UUID, lastHours hours: Int) -> [DiaperEvent] {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .hour, value: -hours, to: endDate) ?? endDate

        return fetchDiaperEvents(for: childId, from: startDate, to: endDate)
    }

    func getTotalDiaperCount(for childId: UUID) -> Int {
        let predicate = NSPredicate(format: "childId == %@", childId as CVarArg)
        return fetch(with: predicate).count
    }

    func getTodayDiaperCount(for childId: UUID) -> Int {
        return fetchTodayDiaperEvents(for: childId).count
    }

    func getDiaperTypeStatistics(for childId: UUID) -> [String: Int] {
        let events = fetchDiaperEvents(for: childId)
        var statistics: [String: Int] = [:]

        for event in events {
            let type = event.diaperType ?? "Unknown"
            statistics[type, default: 0] += 1
        }

        return statistics
    }

    func getAverageDiaperChangesPerDay(for childId: UUID, lastDays days: Int) -> Double {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) ?? endDate

        let events = fetchDiaperEvents(for: childId, from: startDate, to: endDate)

        guard days > 0 else { return 0.0 }
        return Double(events.count) / Double(days)
    }

    func getTimeSinceLastDiaperChange(for childId: UUID) -> Int? {
        guard let lastChange = fetchLastDiaperEvent(for: childId),
              let timestamp = lastChange.timestamp else {
            return nil
        }

        let interval = Date().timeIntervalSince(timestamp)
        return Int(interval / 60)
    }

    func getWetDiaperCount(for childId: UUID, from startDate: Date, to endDate: Date) -> Int {
        let events = fetchDiaperEvents(for: childId, from: startDate, to: endDate)
        return events.filter { $0.diaperType == "Мокрый" || $0.diaperType == "Оба" }.count
    }

    func getDirtyDiaperCount(for childId: UUID, from startDate: Date, to endDate: Date) -> Int {
        let events = fetchDiaperEvents(for: childId, from: startDate, to: endDate)
        return events.filter { $0.diaperType == "Грязный" || $0.diaperType == "Оба" }.count
    }

    func fetchDiaperEvents(for childId: UUID, lastDays days: Int) -> [DiaperEvent] {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) ?? endDate

        return fetchDiaperEvents(for: childId, from: startDate, to: endDate)
    }

    func getDiaperChangePatternByHour(for childId: UUID) -> [Int: Int] {
        let calendar = Calendar.current
        let events = fetchDiaperEvents(for: childId, lastDays: 30)
        var pattern: [Int: Int] = [:]

        for event in events {
            guard let timestamp = event.timestamp else { continue }
            let hour = calendar.component(.hour, from: timestamp)
            pattern[hour, default: 0] += 1
        }

        return pattern
    }
}
