import Foundation
import CoreData
import Combine

class FeedingEventRepository: BaseRepository<FeedingEvent> {

    func createFeedingEvent(
        childId: UUID,
        timestamp: Date = Date(),
        feedingType: String,
        duration: Int32? = nil,
        volume: Double? = nil,
        breast: String? = nil,
        notes: String? = nil
    ) async throws -> FeedingEvent {
        let event = create()
        event.id = UUID()
        event.childId = childId
        event.timestamp = timestamp
        event.feedingType = feedingType
        event.duration = duration ?? 0
        event.volume = volume ?? 0.0
        event.breast = breast
        event.notes = notes

        try await PersistenceController.shared.saveContext(context)
        return event
    }

    func updateFeedingEvent(
        _ event: FeedingEvent,
        timestamp: Date? = nil,
        feedingType: String? = nil,
        duration: Int32? = nil,
        volume: Double? = nil,
        breast: String? = nil,
        notes: String? = nil
    ) async throws {
        if let timestamp = timestamp { event.timestamp = timestamp }
        if let feedingType = feedingType { event.feedingType = feedingType }
        if let duration = duration { event.duration = duration }
        if let volume = volume { event.volume = volume }
        if let breast = breast { event.breast = breast }
        if let notes = notes { event.notes = notes }

        try await PersistenceController.shared.saveContext(context)
    }

    func deleteFeedingEvent(_ event: FeedingEvent) async throws {
        delete(event)
        try await PersistenceController.shared.saveContext(context)
    }

    func fetchFeedingEvents(for childId: UUID, ascending: Bool = false) -> [FeedingEvent] {
        let predicate = NSPredicate(format: "childId == %@", childId as CVarArg)
        let sortDescriptor = NSSortDescriptor(key: "timestamp", ascending: ascending)
        return fetch(sortedBy: [sortDescriptor], predicate: predicate)
    }

    func fetchFeedingEvents(for childId: UUID, from startDate: Date, to endDate: Date) -> [FeedingEvent] {
        let predicate = NSPredicate(
            format: "childId == %@ AND timestamp >= %@ AND timestamp <= %@",
            childId as CVarArg,
            startDate as CVarArg,
            endDate as CVarArg
        )
        let sortDescriptor = NSSortDescriptor(key: "timestamp", ascending: false)
        return fetch(sortedBy: [sortDescriptor], predicate: predicate)
    }

    func fetchFeedingEvents(for childId: UUID, type feedingType: String) -> [FeedingEvent] {
        let predicate = NSPredicate(format: "childId == %@ AND feedingType == %@", childId as CVarArg, feedingType)
        let sortDescriptor = NSSortDescriptor(key: "timestamp", ascending: false)
        return fetch(sortedBy: [sortDescriptor], predicate: predicate)
    }

    func fetchLastFeedingEvent(for childId: UUID) -> FeedingEvent? {
        let predicate = NSPredicate(format: "childId == %@", childId as CVarArg)
        let sortDescriptor = NSSortDescriptor(key: "timestamp", ascending: false)
        let events = fetch(sortedBy: [sortDescriptor], predicate: predicate)
        return events.first
    }

    func fetchTodayFeedingEvents(for childId: UUID) -> [FeedingEvent] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()

        return fetchFeedingEvents(for: childId, from: startOfDay, to: endOfDay)
    }

    func getTotalFeedingCount(for childId: UUID) -> Int {
        let predicate = NSPredicate(format: "childId == %@", childId as CVarArg)
        return fetch(with: predicate).count
    }

    func getAverageFeedingDuration(for childId: UUID) -> Double {
        let events = fetchFeedingEvents(for: childId)
        guard !events.isEmpty else { return 0.0 }

        let totalDuration = events.reduce(0.0) { $0 + Double($1.duration) }
        return totalDuration / Double(events.count)
    }

    func getTotalVolume(for childId: UUID, from startDate: Date, to endDate: Date) -> Double {
        let events = fetchFeedingEvents(for: childId, from: startDate, to: endDate)
        return events.reduce(0.0) { $0 + $1.volume }
    }

    func getTodayFeedingCount(for childId: UUID) -> Int {
        return fetchTodayFeedingEvents(for: childId).count
    }

    func getFeedingTypeStatistics(for childId: UUID) -> [String: Int] {
        let events = fetchFeedingEvents(for: childId)
        var statistics: [String: Int] = [:]

        for event in events {
            let type = event.feedingType ?? "Unknown"
            statistics[type, default: 0] += 1
        }

        return statistics
    }

    func getTimeSinceLastFeeding(for childId: UUID) -> Int? {
        guard let lastFeeding = fetchLastFeedingEvent(for: childId),
              let timestamp = lastFeeding.timestamp else {
            return nil
        }

        let interval = Date().timeIntervalSince(timestamp)
        return Int(interval / 60)
    }

    func fetchFeedingEvents(for childId: UUID, lastDays days: Int) -> [FeedingEvent] {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) ?? endDate

        return fetchFeedingEvents(for: childId, from: startDate, to: endDate)
    }
}
