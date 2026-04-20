import Foundation
import SwiftUI
import CoreData
import Combine

@MainActor
class FeedingViewModel: ObservableObject {

    @Published var feedingEvents: [FeedingEvent] = []

    @Published var isLoading: Bool = false

    @Published var error: Error?

    @Published var showError: Bool = false

    @Published var todayCount: Int = 0
    @Published var todayVolume: Double = 0.0
    @Published var lastFeedingTime: Date?

    private let repository: FeedingEventRepository
    private let reminderManager = ReminderManager.shared
    private var cancellables = Set<AnyCancellable>()

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.repository = FeedingEventRepository(context: context)
    }

    func loadFeedingEvents(for childId: UUID) {
        isLoading = true
        feedingEvents = repository.fetchFeedingEvents(for: childId, ascending: false)
        loadStatistics(for: childId)
        isLoading = false
    }

    func addFeeding(
        childId: UUID,
        timestamp: Date = Date(),
        feedingType: String,
        duration: Int32? = nil,
        volume: Double? = nil,
        breast: String? = nil,
        notes: String? = nil
    ) async {
        isLoading = true

        do {
            _ = try await repository.createFeedingEvent(
                childId: childId,
                timestamp: timestamp,
                feedingType: feedingType,
                duration: duration,
                volume: volume,
                breast: breast,
                notes: notes
            )

            loadFeedingEvents(for: childId)

            try await reminderManager.updateLastTriggeredAfterEvent(
                childId: childId,
                type: .feeding
            )

            if #available(iOS 16.0, *) {
                AppIntentsManager.shared.donateLogFeedingIntent(
                    feedingType: feedingType,
                    duration: duration,
                    volume: volume,
                    breast: breast
                )
            }

        } catch {
            self.error = error
            self.showError = true
        }

        isLoading = false
    }

    func deleteFeeding(_ event: FeedingEvent, childId: UUID) async {
        isLoading = true

        do {
            try await repository.deleteFeedingEvent(event)
            loadFeedingEvents(for: childId)

        } catch {
            self.error = error
            self.showError = true
        }

        isLoading = false
    }

    func getFeedingsToday(for childId: UUID) -> [FeedingEvent] {
        return repository.fetchTodayFeedingEvents(for: childId)
    }

    func getFeedingsForLastDays(childId: UUID, days: Int) -> [FeedingEvent] {
        return repository.fetchFeedingEvents(for: childId, lastDays: days)
    }

    func getStatistics(for childId: UUID) -> FeedingStatistics {
        let todayEvents = getFeedingsToday(for: childId)
        let weekEvents = getFeedingsForLastDays(childId: childId, days: 7)

        let todayCount = todayEvents.count
        let todayVolume = todayEvents.reduce(0.0) { $0 + $1.volume }
        let todayDuration = todayEvents.reduce(0) { $0 + Int($1.duration) }

        let weekCount = weekEvents.count
        let weekVolume = weekEvents.reduce(0.0) { $0 + $1.volume }
        let averageDuration = repository.getAverageFeedingDuration(for: childId)

        let lastFeeding = repository.fetchLastFeedingEvent(for: childId)
        let timeSinceLastFeeding = repository.getTimeSinceLastFeeding(for: childId)

        return FeedingStatistics(
            todayCount: todayCount,
            todayVolume: todayVolume,
            todayDuration: todayDuration,
            weekCount: weekCount,
            weekVolume: weekVolume,
            averageDuration: averageDuration,
            lastFeedingTime: lastFeeding?.timestamp,
            timeSinceLastFeeding: timeSinceLastFeeding
        )
    }

    func getFeedingTypeStatistics(for childId: UUID) -> [String: Int] {
        return repository.getFeedingTypeStatistics(for: childId)
    }

    private func loadStatistics(for childId: UUID) {
        todayCount = repository.getTodayFeedingCount(for: childId)

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()
        todayVolume = repository.getTotalVolume(for: childId, from: startOfDay, to: endOfDay)

        lastFeedingTime = repository.fetchLastFeedingEvent(for: childId)?.timestamp
    }
}

struct FeedingStatistics {
    let todayCount: Int
    let todayVolume: Double
    let todayDuration: Int
    let weekCount: Int
    let weekVolume: Double
    let averageDuration: Double
    let lastFeedingTime: Date?
    let timeSinceLastFeeding: Int?
}
