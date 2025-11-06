import Foundation
import CoreData
import Combine

@MainActor
class AnalyticsViewModel: ObservableObject {

    @Published var selectedPeriod: AnalyticsPeriod = .week

    @Published var selectedChildId: UUID?

    @Published var feedingAnalytics: FeedingAnalytics?

    @Published var sleepAnalytics: SleepAnalytics?

    @Published var diaperAnalytics: DiaperAnalytics?

    @Published var isLoading: Bool = false

    @Published var errorMessage: String?

    private let analyticsService: AnalyticsService
    private var cancellables = Set<AnyCancellable>()
    private var loadTask: Task<Void, Never>?

    private var debounceTimer: Timer?

    init(context: NSManagedObjectContext) {
        self.analyticsService = AnalyticsService(context: context)

        $selectedPeriod
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.loadAnalyticsDataDebounced()
            }
            .store(in: &cancellables)
    }

    func loadAnalyticsData(for childId: UUID) {
        selectedChildId = childId

        loadTask?.cancel()

        isLoading = true
        errorMessage = nil

        loadTask = Task { [weak self] in
            guard let self = self else { return }

            do {

                async let feeding = self.analyticsService.getFeedingAnalytics(for: childId, period: self.selectedPeriod)
                async let sleep = self.analyticsService.getSleepAnalytics(for: childId, period: self.selectedPeriod)
                async let diaper = self.analyticsService.getDiaperAnalytics(for: childId, period: self.selectedPeriod)

                let (feedingData, sleepData, diaperData) = try await (feeding, sleep, diaper)

                guard !Task.isCancelled else { return }

                self.feedingAnalytics = feedingData
                self.sleepAnalytics = sleepData
                self.diaperAnalytics = diaperData

                self.isLoading = false
            } catch {
                guard !Task.isCancelled else { return }
                self.errorMessage = "Ошибка загрузки аналитики: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }

    func refreshAnalytics() {
        guard let childId = selectedChildId else { return }
        loadAnalyticsData(for: childId)
    }

    func changePeriod(to period: AnalyticsPeriod) {
        selectedPeriod = period
    }

    func getFeedingTrends() -> (count: TrendDirection, volume: TrendDirection)? {
        guard let analytics = feedingAnalytics else { return nil }

        let countTrend = analytics.summary.trend

        let volumeTrend = calculateVolumeTrend(data: analytics.volumeOverTime)

        return (countTrend, volumeTrend)
    }

    func getSleepTrends() -> (count: TrendDirection, duration: TrendDirection)? {
        guard let analytics = sleepAnalytics else { return nil }

        let countTrend = analytics.summary.trend
        let durationTrend = calculateDurationTrend(data: analytics.durationByDay)

        return (countTrend, durationTrend)
    }

    func getDiaperTrends() -> TrendDirection? {
        guard let analytics = diaperAnalytics else { return nil }
        return analytics.summary.trend
    }

    func getAverageFeedingsPerDay() -> Double {
        return feedingAnalytics?.summary.averagePerDay ?? 0
    }

    func getAverageSleepPerDay() -> Double {
        guard let analytics = sleepAnalytics else { return 0 }
        let totalMinutes = analytics.totalTimeOverPeriod.reduce(0) { $0 + $1.value }
        let days = Double(selectedPeriod.days)
        return (totalMinutes / days) / 60
    }

    func getAverageDiaperChangesPerDay() -> Double {
        return diaperAnalytics?.averageChangesPerDay ?? 0
    }

    func getFormattedFeedingChartData() -> [ChartDataPoint] {
        guard let analytics = feedingAnalytics else { return [] }
        return analytics.countByDay.map { daily in
            ChartDataPoint(
                date: daily.day,
                value: Double(daily.eventCount),
                label: formatDate(daily.day)
            )
        }
    }

    func getFormattedSleepChartData() -> [ChartDataPoint] {
        guard let analytics = sleepAnalytics else { return [] }
        return analytics.durationByDay.map { daily in
            ChartDataPoint(
                date: daily.day,
                value: daily.totalValue / 60,
                label: formatDate(daily.day)
            )
        }
    }

    func getFormattedDiaperChartData() -> [ChartDataPoint] {
        guard let analytics = diaperAnalytics else { return [] }
        return analytics.countByDay.map { daily in
            ChartDataPoint(
                date: daily.day,
                value: Double(daily.eventCount),
                label: formatDate(daily.day)
            )
        }
    }

    private func loadAnalyticsDataDebounced() {
        guard let childId = selectedChildId else { return }

        debounceTimer?.invalidate()
        debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            self?.loadAnalyticsData(for: childId)
        }
    }

    private func calculateVolumeTrend(data: [ChartDataPoint]) -> TrendDirection {
        guard data.count > 1 else { return .stable }

        let midpoint = data.count / 2
        let firstHalf = data[0..<midpoint]
        let secondHalf = data[midpoint...]

        let firstAverage = firstHalf.reduce(0.0) { $0 + $1.value } / Double(firstHalf.count)
        let secondAverage = secondHalf.reduce(0.0) { $0 + $1.value } / Double(secondHalf.count)

        let percentageChange = ((secondAverage - firstAverage) / firstAverage) * 100

        if percentageChange > 10 {
            return .up
        } else if percentageChange < -10 {
            return .down
        } else {
            return .stable
        }
    }

    private func calculateDurationTrend(data: [DailyChartData]) -> TrendDirection {
        guard data.count > 1 else { return .stable }

        let midpoint = data.count / 2
        let firstHalf = Array(data[0..<midpoint])
        let secondHalf = Array(data[midpoint...])

        let firstAverage = firstHalf.reduce(0.0) { $0 + $1.totalValue } / Double(firstHalf.count)
        let secondAverage = secondHalf.reduce(0.0) { $0 + $1.totalValue } / Double(secondHalf.count)

        let percentageChange = ((secondAverage - firstAverage) / firstAverage) * 100

        if percentageChange > 10 {
            return .up
        } else if percentageChange < -10 {
            return .down
        } else {
            return .stable
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")

        switch selectedPeriod {
        case .day:
            formatter.dateFormat = "HH:mm"
        case .week:
            formatter.dateFormat = "EEE"
        case .month:
            formatter.dateFormat = "dd MMM"
        }

        return formatter.string(from: date)
    }

    deinit {
        loadTask?.cancel()
        debounceTimer?.invalidate()
    }
}

#if DEBUG
extension AnalyticsViewModel {
    static var preview: AnalyticsViewModel {
        let viewModel = AnalyticsViewModel(context: PersistenceController.preview.container.viewContext)

        return viewModel
    }
}
#endif
