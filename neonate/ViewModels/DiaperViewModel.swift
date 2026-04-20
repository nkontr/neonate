import Foundation
import SwiftUI
import CoreData
import Combine

@MainActor
class DiaperViewModel: ObservableObject {

    @Published var diaperEvents: [DiaperEvent] = []

    @Published var isLoading: Bool = false

    @Published var error: Error?

    @Published var showError: Bool = false

    private let repository: DiaperEventRepository
    private let reminderManager = ReminderManager.shared
    private var cancellables = Set<AnyCancellable>()

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.repository = DiaperEventRepository(context: context)
    }

    func loadDiaperEvents(for childId: UUID) {
        isLoading = true
        diaperEvents = repository.fetchDiaperEvents(for: childId, ascending: false)
        isLoading = false
    }

    func addDiaperChange(
        childId: UUID,
        timestamp: Date = Date(),
        diaperType: String,
        notes: String? = nil
    ) async {
        isLoading = true

        do {
            _ = try await repository.createDiaperEvent(
                childId: childId,
                timestamp: timestamp,
                diaperType: diaperType,
                notes: notes
            )

            loadDiaperEvents(for: childId)

            try await reminderManager.updateLastTriggeredAfterEvent(
                childId: childId,
                type: .diaper
            )

            if #available(iOS 16.0, *) {
                AppIntentsManager.shared.donateLogDiaperIntent(
                    diaperType: diaperType,
                    timestamp: timestamp
                )
            }

        } catch {
            self.error = error
            self.showError = true
        }

        isLoading = false
    }

    func deleteDiaperChange(_ event: DiaperEvent, childId: UUID) async {
        isLoading = true

        do {
            try await repository.deleteDiaperEvent(event)
            loadDiaperEvents(for: childId)

        } catch {
            self.error = error
            self.showError = true
        }

        isLoading = false
    }

    func getEventsToday(for childId: UUID) -> [DiaperEvent] {
        return repository.fetchTodayDiaperEvents(for: childId)
    }

    func getEventsForLastHours(childId: UUID, hours: Int) -> [DiaperEvent] {
        return repository.fetchDiaperEvents(for: childId, lastHours: hours)
    }

    func getEventsForLastDays(childId: UUID, days: Int) -> [DiaperEvent] {
        return repository.fetchDiaperEvents(for: childId, lastDays: days)
    }

    func getStatistics(for childId: UUID) -> DiaperStatistics {
        let todayCount = repository.getTodayDiaperCount(for: childId)
        let todayEvents = getEventsToday(for: childId)

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()

        let wetCount = repository.getWetDiaperCount(for: childId, from: startOfDay, to: endOfDay)
        let dirtyCount = repository.getDirtyDiaperCount(for: childId, from: startOfDay, to: endOfDay)

        let lastChange = repository.fetchLastDiaperEvent(for: childId)
        let timeSinceLastChange = repository.getTimeSinceLastDiaperChange(for: childId)

        let weekEvents = getEventsForLastDays(childId: childId, days: 7)
        let averagePerDay = repository.getAverageDiaperChangesPerDay(for: childId, lastDays: 7)

        let typeStatistics = repository.getDiaperTypeStatistics(for: childId)

        return DiaperStatistics(
            todayCount: todayCount,
            todayWetCount: wetCount,
            todayDirtyCount: dirtyCount,
            weekCount: weekEvents.count,
            averagePerDay: averagePerDay,
            lastChangeTime: lastChange?.timestamp,
            timeSinceLastChange: timeSinceLastChange,
            typeStatistics: typeStatistics
        )
    }

    func getTypeStatistics(for childId: UUID) -> [String: Int] {
        return repository.getDiaperTypeStatistics(for: childId)
    }

    func getChangePatternByHour(for childId: UUID) -> [Int: Int] {
        return repository.getDiaperChangePatternByHour(for: childId)
    }
}

struct DiaperStatistics {
    let todayCount: Int
    let todayWetCount: Int
    let todayDirtyCount: Int
    let weekCount: Int
    let averagePerDay: Double
    let lastChangeTime: Date?
    let timeSinceLastChange: Int?
    let typeStatistics: [String: Int]
}
