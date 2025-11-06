import Foundation
import CoreData

class AnalyticsService {

    private let feedingRepository: FeedingEventRepository
    private let sleepRepository: SleepEventRepository
    private let diaperRepository: DiaperEventRepository

    init(context: NSManagedObjectContext) {
        self.feedingRepository = FeedingEventRepository(context: context)
        self.sleepRepository = SleepEventRepository(context: context)
        self.diaperRepository = DiaperEventRepository(context: context)
    }

    func getFeedingAnalytics(for childId: UUID, period: AnalyticsPeriod) async -> FeedingAnalytics {
        return await Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else {
                return FeedingAnalytics(
                    summary: AnalyticsSummary(totalEvents: 0, averagePerDay: 0, trend: .stable, percentageChange: 0),
                    countByDay: [],
                    volumeOverTime: [],
                    distributionByType: [],
                    averageInterval: 0,
                    totalVolume: 0
                )
            }

            let (startDate, endDate) = self.getDateRange(for: period)
            let events = self.feedingRepository.fetchFeedingEvents(for: childId, from: startDate, to: endDate)

            let previousPeriodEvents = self.getPreviousPeriodEvents(
                childId: childId,
                currentStart: startDate,
                period: period,
                repository: self.feedingRepository
            )

            let summary = self.createSummary(
                currentEvents: events.count,
                previousEvents: previousPeriodEvents,
                period: period
            )

            let countByDay = self.groupEventsByDay(events: events, period: period) { event in
                ChartDataPoint(date: event.timestamp ?? Date(), value: 1.0)
            }

            let volumeOverTime = events
                .filter { $0.volume > 0 }
                .map { ChartDataPoint(date: $0.timestamp ?? Date(), value: $0.volume) }
                .sorted { $0.date < $1.date }

            let distributionByType = self.createPieChartData(for: events) { event in
                event.feedingType ?? "Неизвестно"
            }

            let averageInterval = self.calculateAverageInterval(events: events)

            let totalVolume = events.reduce(0.0) { $0 + $1.volume }

            return FeedingAnalytics(
                summary: summary,
                countByDay: countByDay,
                volumeOverTime: volumeOverTime,
                distributionByType: distributionByType,
                averageInterval: averageInterval,
                totalVolume: totalVolume
            )
        }.value
    }

    func getSleepAnalytics(for childId: UUID, period: AnalyticsPeriod) async -> SleepAnalytics {
        return await Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else {
                return SleepAnalytics(
                    summary: AnalyticsSummary(totalEvents: 0, averagePerDay: 0, trend: .stable, percentageChange: 0),
                    durationByDay: [],
                    totalTimeOverPeriod: [],
                    distributionByQuality: [],
                    averageDuration: 0,
                    longestSleep: 0,
                    shortestSleep: 0
                )
            }

            let (startDate, endDate) = self.getDateRange(for: period)
            let events = self.sleepRepository.fetchSleepEvents(for: childId, from: startDate, to: endDate)
                .filter { $0.endTime != nil }

            let previousPeriodEvents = self.getPreviousPeriodSleepEvents(
                childId: childId,
                currentStart: startDate,
                period: period
            )

            let summary = self.createSummary(
                currentEvents: events.count,
                previousEvents: previousPeriodEvents,
                period: period
            )

            let durationByDay = self.groupEventsByDay(events: events, period: period) { event in
                ChartDataPoint(date: event.startTime ?? Date(), value: Double(event.duration))
            }

            let totalTimeOverPeriod = self.createDailySleepTotals(events: events, period: period)

            let distributionByQuality = self.createPieChartData(for: events) { event in
                event.quality ?? "Не указано"
            }

            let durations = events.map { Double($0.duration) }
            let averageDuration = durations.isEmpty ? 0 : durations.reduce(0, +) / Double(durations.count)
            let longestSleep = durations.max() ?? 0
            let shortestSleep = durations.min() ?? 0

            return SleepAnalytics(
                summary: summary,
                durationByDay: durationByDay,
                totalTimeOverPeriod: totalTimeOverPeriod,
                distributionByQuality: distributionByQuality,
                averageDuration: averageDuration,
                longestSleep: longestSleep,
                shortestSleep: shortestSleep
            )
        }.value
    }

    func getDiaperAnalytics(for childId: UUID, period: AnalyticsPeriod) async -> DiaperAnalytics {
        return await Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else {
                return DiaperAnalytics(
                    summary: AnalyticsSummary(totalEvents: 0, averagePerDay: 0, trend: .stable, percentageChange: 0),
                    countByDay: [],
                    distributionByType: [],
                    patternByHour: [:],
                    averageChangesPerDay: 0,
                    timeSinceLastChange: nil
                )
            }

            let (startDate, endDate) = self.getDateRange(for: period)
            let events = self.diaperRepository.fetchDiaperEvents(for: childId, from: startDate, to: endDate)

            let previousPeriodEvents = self.getPreviousPeriodDiaperEvents(
                childId: childId,
                currentStart: startDate,
                period: period
            )

            let summary = self.createSummary(
                currentEvents: events.count,
                previousEvents: previousPeriodEvents,
                period: period
            )

            let countByDay = self.groupEventsByDay(events: events, period: period) { event in
                ChartDataPoint(date: event.timestamp ?? Date(), value: 1.0)
            }

            let distributionByType = self.createPieChartData(for: events) { event in
                event.diaperType ?? "Неизвестно"
            }

            let patternByHour = self.diaperRepository.getDiaperChangePatternByHour(for: childId)

            let averageChangesPerDay = Double(events.count) / Double(period.days)

            let timeSinceLastChange = self.diaperRepository.getTimeSinceLastDiaperChange(for: childId)

            return DiaperAnalytics(
                summary: summary,
                countByDay: countByDay,
                distributionByType: distributionByType,
                patternByHour: patternByHour,
                averageChangesPerDay: averageChangesPerDay,
                timeSinceLastChange: timeSinceLastChange
            )
        }.value
    }

    private func getDateRange(for period: AnalyticsPeriod) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -period.days, to: endDate) ?? endDate
        return (startDate, endDate)
    }

    private func getPreviousPeriodEvents(
        childId: UUID,
        currentStart: Date,
        period: AnalyticsPeriod,
        repository: FeedingEventRepository
    ) -> Int {
        let calendar = Calendar.current
        let previousEnd = currentStart
        let previousStart = calendar.date(byAdding: .day, value: -period.days, to: previousEnd) ?? previousEnd
        return repository.fetchFeedingEvents(for: childId, from: previousStart, to: previousEnd).count
    }

    private func getPreviousPeriodSleepEvents(
        childId: UUID,
        currentStart: Date,
        period: AnalyticsPeriod
    ) -> Int {
        let calendar = Calendar.current
        let previousEnd = currentStart
        let previousStart = calendar.date(byAdding: .day, value: -period.days, to: previousEnd) ?? previousEnd
        return sleepRepository.fetchSleepEvents(for: childId, from: previousStart, to: previousEnd)
            .filter { $0.endTime != nil }.count
    }

    private func getPreviousPeriodDiaperEvents(
        childId: UUID,
        currentStart: Date,
        period: AnalyticsPeriod
    ) -> Int {
        let calendar = Calendar.current
        let previousEnd = currentStart
        let previousStart = calendar.date(byAdding: .day, value: -period.days, to: previousEnd) ?? previousEnd
        return diaperRepository.fetchDiaperEvents(for: childId, from: previousStart, to: previousEnd).count
    }

    private func createSummary(currentEvents: Int, previousEvents: Int, period: AnalyticsPeriod) -> AnalyticsSummary {
        let averagePerDay = Double(currentEvents) / Double(period.days)

        let percentageChange: Double
        let trend: TrendDirection

        if previousEvents == 0 {
            percentageChange = currentEvents > 0 ? 100.0 : 0.0
            trend = currentEvents > 0 ? .up : .stable
        } else {
            percentageChange = ((Double(currentEvents) - Double(previousEvents)) / Double(previousEvents)) * 100
            if percentageChange > 5 {
                trend = .up
            } else if percentageChange < -5 {
                trend = .down
            } else {
                trend = .stable
            }
        }

        return AnalyticsSummary(
            totalEvents: currentEvents,
            averagePerDay: averagePerDay,
            trend: trend,
            percentageChange: percentageChange
        )
    }

    private func groupEventsByDay<T>(
        events: [T],
        period: AnalyticsPeriod,
        transform: (T) -> ChartDataPoint
    ) -> [DailyChartData] {
        let calendar = Calendar.current
        let (startDate, endDate) = getDateRange(for: period)

        var eventsByDay: [Date: [ChartDataPoint]] = [:]

        var currentDate = calendar.startOfDay(for: startDate)
        while currentDate <= endDate {
            eventsByDay[currentDate] = []
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }

        for event in events {
            let dataPoint = transform(event)
            let day = calendar.startOfDay(for: dataPoint.date)
            eventsByDay[day, default: []].append(dataPoint)
        }

        return eventsByDay.map { day, points in
            DailyChartData(day: day, dataPoints: points)
        }.sorted { $0.day < $1.day }
    }

    private func createPieChartData<T>(
        for events: [T],
        categoryExtractor: (T) -> String
    ) -> [PieChartDataPoint] {
        var categoryCounts: [String: Double] = [:]

        for event in events {
            let category = categoryExtractor(event)
            categoryCounts[category, default: 0] += 1
        }

        let total = Double(events.count)
        guard total > 0 else { return [] }

        let colors = ["blue", "green", "orange", "purple", "pink", "red"]

        return categoryCounts.enumerated().map { index, pair in
            var point = PieChartDataPoint(
                category: pair.key,
                value: pair.value,
                color: colors[index % colors.count]
            )
            point.percentage = (pair.value / total) * 100
            return point
        }.sorted { $0.value > $1.value }
    }

    private func calculateAverageInterval<T>(events: [T]) -> Double where T: AnyObject {
        guard events.count > 1 else { return 0 }

        var intervals: [TimeInterval] = []
        let sortedEvents = events.sorted { (event1, event2) -> Bool in
            guard let timestamp1 = (event1 as? FeedingEvent)?.timestamp,
                  let timestamp2 = (event2 as? FeedingEvent)?.timestamp else {
                return false
            }
            return timestamp1 < timestamp2
        }

        for i in 1..<sortedEvents.count {
            if let timestamp1 = (sortedEvents[i-1] as? FeedingEvent)?.timestamp,
               let timestamp2 = (sortedEvents[i] as? FeedingEvent)?.timestamp {
                intervals.append(timestamp2.timeIntervalSince(timestamp1))
            }
        }

        guard !intervals.isEmpty else { return 0 }
        let averageSeconds = intervals.reduce(0, +) / Double(intervals.count)
        return averageSeconds / 60
    }

    private func createDailySleepTotals(events: [SleepEvent], period: AnalyticsPeriod) -> [ChartDataPoint] {
        let calendar = Calendar.current
        let (startDate, endDate) = getDateRange(for: period)

        var dailyTotals: [Date: Double] = [:]

        var currentDate = calendar.startOfDay(for: startDate)
        while currentDate <= endDate {
            dailyTotals[currentDate] = 0
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }

        for event in events {
            guard let startTime = event.startTime else { continue }
            let day = calendar.startOfDay(for: startTime)
            dailyTotals[day, default: 0] += Double(event.duration)
        }

        return dailyTotals.map { day, total in
            ChartDataPoint(date: day, value: total)
        }.sorted { $0.date < $1.date }
    }
}
