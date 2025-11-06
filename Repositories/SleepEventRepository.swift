import Foundation
import CoreData
import Combine

class SleepEventRepository: BaseRepository<SleepEvent> {

    func createSleepEvent(
        childId: UUID,
        startTime: Date = Date(),
        endTime: Date? = nil,
        quality: String? = nil,
        location: String? = nil,
        notes: String? = nil
    ) async throws -> SleepEvent {
        let event = create()
        event.id = UUID()
        event.childId = childId
        event.startTime = startTime
        event.endTime = endTime
        event.quality = quality
        event.location = location
        event.notes = notes

        if let endTime = endTime {
            let duration = endTime.timeIntervalSince(startTime)
            event.duration = Int32(duration / 60)
        } else {
            event.duration = 0
        }

        try await PersistenceController.shared.saveContext(context)
        return event
    }

    func updateSleepEvent(
        _ event: SleepEvent,
        startTime: Date? = nil,
        endTime: Date? = nil,
        quality: String? = nil,
        location: String? = nil,
        notes: String? = nil
    ) async throws {
        if let startTime = startTime { event.startTime = startTime }
        if let endTime = endTime { event.endTime = endTime }
        if let quality = quality { event.quality = quality }
        if let location = location { event.location = location }
        if let notes = notes { event.notes = notes }

        if let start = event.startTime, let end = event.endTime {
            let duration = end.timeIntervalSince(start)
            event.duration = Int32(duration / 60)
        }

        try await PersistenceController.shared.saveContext(context)
    }

    func endSleep(_ event: SleepEvent, endTime: Date = Date()) async throws {
        event.endTime = endTime

        if let startTime = event.startTime {
            let duration = endTime.timeIntervalSince(startTime)
            event.duration = Int32(duration / 60)
        }

        try await PersistenceController.shared.saveContext(context)
    }

    func deleteSleepEvent(_ event: SleepEvent) async throws {
        delete(event)
        try await PersistenceController.shared.saveContext(context)
    }

    func fetchSleepEvents(for childId: UUID, ascending: Bool = false) -> [SleepEvent] {
        let predicate = NSPredicate(format: "childId == %@", childId as CVarArg)
        let sortDescriptor = NSSortDescriptor(key: "startTime", ascending: ascending)
        return fetch(sortedBy: [sortDescriptor], predicate: predicate)
    }

    func fetchSleepEvents(for childId: UUID, from startDate: Date, to endDate: Date) -> [SleepEvent] {
        let predicate = NSPredicate(
            format: "childId == %@ AND startTime >= %@ AND startTime <= %@",
            childId as CVarArg,
            startDate as CVarArg,
            endDate as CVarArg
        )
        let sortDescriptor = NSSortDescriptor(key: "startTime", ascending: false)
        return fetch(sortedBy: [sortDescriptor], predicate: predicate)
    }

    func fetchLastSleepEvent(for childId: UUID) -> SleepEvent? {
        let predicate = NSPredicate(format: "childId == %@", childId as CVarArg)
        let sortDescriptor = NSSortDescriptor(key: "startTime", ascending: false)
        let events = fetch(sortedBy: [sortDescriptor], predicate: predicate)
        return events.first
    }

    func fetchActiveSleep(for childId: UUID) -> SleepEvent? {
        let predicate = NSPredicate(format: "childId == %@ AND endTime == nil", childId as CVarArg)
        let sortDescriptor = NSSortDescriptor(key: "startTime", ascending: false)
        let events = fetch(sortedBy: [sortDescriptor], predicate: predicate)
        return events.first
    }

    func fetchTodaySleepEvents(for childId: UUID) -> [SleepEvent] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()

        return fetchSleepEvents(for: childId, from: startOfDay, to: endOfDay)
    }

    func fetchSleepEvents(for childId: UUID, quality: String) -> [SleepEvent] {
        let predicate = NSPredicate(format: "childId == %@ AND quality == %@", childId as CVarArg, quality)
        let sortDescriptor = NSSortDescriptor(key: "startTime", ascending: false)
        return fetch(sortedBy: [sortDescriptor], predicate: predicate)
    }

    func fetchSleepEvents(for childId: UUID, location: String) -> [SleepEvent] {
        let predicate = NSPredicate(format: "childId == %@ AND location == %@", childId as CVarArg, location)
        let sortDescriptor = NSSortDescriptor(key: "startTime", ascending: false)
        return fetch(sortedBy: [sortDescriptor], predicate: predicate)
    }

    func getTotalSleepCount(for childId: UUID) -> Int {
        let predicate = NSPredicate(format: "childId == %@", childId as CVarArg)
        return fetch(with: predicate).count
    }

    func getAverageSleepDuration(for childId: UUID) -> Double {
        let events = fetchSleepEvents(for: childId).filter { $0.endTime != nil }
        guard !events.isEmpty else { return 0.0 }

        let totalDuration = events.reduce(0.0) { $0 + Double($1.duration) }
        return totalDuration / Double(events.count)
    }

    func getTotalSleepTime(for childId: UUID, from startDate: Date, to endDate: Date) -> Int {
        let events = fetchSleepEvents(for: childId, from: startDate, to: endDate)
        return events.reduce(0) { $0 + Int($1.duration) }
    }

    func getTodayTotalSleepTime(for childId: UUID) -> Int {
        let events = fetchTodaySleepEvents(for: childId)
        return events.reduce(0) { $0 + Int($1.duration) }
    }

    func isCurrentlySleeping(for childId: UUID) -> Bool {
        return fetchActiveSleep(for: childId) != nil
    }

    func getTimeSinceLastSleep(for childId: UUID) -> Int? {
        guard let lastSleep = fetchLastSleepEvent(for: childId) else {
            return nil
        }

        if lastSleep.endTime == nil {
            return 0
        }

        guard let endTime = lastSleep.endTime else {
            return nil
        }

        let interval = Date().timeIntervalSince(endTime)
        return Int(interval / 60)
    }

    func getSleepQualityStatistics(for childId: UUID) -> [String: Int] {
        let events = fetchSleepEvents(for: childId)
        var statistics: [String: Int] = [:]

        for event in events {
            let quality = event.quality ?? "Не указано"
            statistics[quality, default: 0] += 1
        }

        return statistics
    }

    func getSleepLocationStatistics(for childId: UUID) -> [String: Int] {
        let events = fetchSleepEvents(for: childId)
        var statistics: [String: Int] = [:]

        for event in events {
            let location = event.location ?? "Не указано"
            statistics[location, default: 0] += 1
        }

        return statistics
    }

    func fetchSleepEvents(for childId: UUID, lastDays days: Int) -> [SleepEvent] {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) ?? endDate

        return fetchSleepEvents(for: childId, from: startDate, to: endDate)
    }
}
