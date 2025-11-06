import Foundation
import SwiftUI
import CoreData
import Combine

@MainActor
class SleepViewModel: ObservableObject {

    @Published var sleepEvents: [SleepEvent] = []

    @Published var currentSleepSession: SleepEvent?

    @Published var isLoading: Bool = false

    @Published var error: Error?

    @Published var showError: Bool = false

    @Published var currentSleepDuration: TimeInterval = 0

    private var timer: Timer?

    private let repository: SleepEventRepository
    private let reminderManager = ReminderManager.shared
    private var cancellables = Set<AnyCancellable>()

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.repository = SleepEventRepository(context: context)
    }

    func loadSleepEvents(for childId: UUID) {
        isLoading = true
        sleepEvents = repository.fetchSleepEvents(for: childId, ascending: false)
        loadCurrentSleepSession(for: childId)
        isLoading = false
    }

    func startSleep(
        childId: UUID,
        startTime: Date = Date(),
        location: String? = nil,
        notes: String? = nil
    ) async {
        isLoading = true

        do {
            let event = try await repository.createSleepEvent(
                childId: childId,
                startTime: startTime,
                endTime: nil,
                quality: nil,
                location: location,
                notes: notes
            )

            currentSleepSession = event
            startTimer()
            loadSleepEvents(for: childId)

            if #available(iOS 16.0, *) {
                AppIntentsManager.shared.donateStartSleepTimerIntent()
            }

        } catch {
            self.error = error
            self.showError = true
        }

        isLoading = false
    }

    func endSleep(
        childId: UUID,
        endTime: Date = Date(),
        quality: String? = nil
    ) async {
        guard let session = currentSleepSession else { return }

        isLoading = true

        do {
            try await repository.endSleep(session, endTime: endTime)

            if let quality = quality {
                try await repository.updateSleepEvent(session, quality: quality)
            }

            stopTimer()
            currentSleepSession = nil
            currentSleepDuration = 0
            loadSleepEvents(for: childId)

            try await reminderManager.updateLastTriggeredAfterEvent(
                childId: childId,
                type: .sleep
            )

            if #available(iOS 16.0, *) {
                AppIntentsManager.shared.donateLogSleepIntent(
                    startTime: session.startTime ?? Date(),
                    endTime: endTime,
                    quality: quality
                )
            }

        } catch {
            self.error = error
            self.showError = true
        }

        isLoading = false
    }

    func addSleep(
        childId: UUID,
        startTime: Date,
        endTime: Date,
        quality: String? = nil,
        location: String? = nil,
        notes: String? = nil
    ) async {
        isLoading = true

        do {
            _ = try await repository.createSleepEvent(
                childId: childId,
                startTime: startTime,
                endTime: endTime,
                quality: quality,
                location: location,
                notes: notes
            )

            loadSleepEvents(for: childId)

        } catch {
            self.error = error
            self.showError = true
        }

        isLoading = false
    }

    func deleteSleep(_ event: SleepEvent, childId: UUID) async {
        isLoading = true

        do {

            if event.id == currentSleepSession?.id {
                stopTimer()
                currentSleepSession = nil
                currentSleepDuration = 0
            }

            try await repository.deleteSleepEvent(event)
            loadSleepEvents(for: childId)

        } catch {
            self.error = error
            self.showError = true
        }

        isLoading = false
    }

    func getStatistics(for childId: UUID) -> SleepStatistics {
        let todayEvents = repository.fetchTodaySleepEvents(for: childId)
        let weekEvents = repository.fetchSleepEvents(for: childId, lastDays: 7)

        let todayTotalMinutes = repository.getTodayTotalSleepTime(for: childId)
        let todayCount = todayEvents.count

        let averageDuration = repository.getAverageSleepDuration(for: childId)
        let qualityStats = repository.getSleepQualityStatistics(for: childId)
        let locationStats = repository.getSleepLocationStatistics(for: childId)

        let isCurrentlySleeping = repository.isCurrentlySleeping(for: childId)
        let timeSinceLastSleep = repository.getTimeSinceLastSleep(for: childId)

        let weekTotalMinutes = weekEvents.reduce(0) { $0 + Int($1.duration) }

        return SleepStatistics(
            todayCount: todayCount,
            todayTotalMinutes: todayTotalMinutes,
            weekCount: weekEvents.count,
            weekTotalMinutes: weekTotalMinutes,
            averageDuration: averageDuration,
            qualityStatistics: qualityStats,
            locationStatistics: locationStats,
            isCurrentlySleeping: isCurrentlySleeping,
            timeSinceLastSleep: timeSinceLastSleep
        )
    }

    private func loadCurrentSleepSession(for childId: UUID) {
        if let activeSleep = repository.fetchActiveSleep(for: childId) {
            currentSleepSession = activeSleep
            startTimer()
        } else {
            currentSleepSession = nil
            stopTimer()
        }
    }

    private func startTimer() {
        stopTimer()

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self,
                  let session = self.currentSleepSession,
                  let startTime = session.startTime else { return }

            Task { @MainActor in
                self.currentSleepDuration = Date().timeIntervalSince(startTime)
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    deinit {
        timer?.invalidate()
        timer = nil
    }
}

struct SleepStatistics {
    let todayCount: Int
    let todayTotalMinutes: Int
    let weekCount: Int
    let weekTotalMinutes: Int
    let averageDuration: Double
    let qualityStatistics: [String: Int]
    let locationStatistics: [String: Int]
    let isCurrentlySleeping: Bool
    let timeSinceLastSleep: Int?
}
