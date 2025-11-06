import Foundation

enum TrendDirection: String {
    case up = "up"
    case down = "down"
    case stable = "stable"

    var systemImage: String {
        switch self {
        case .up:
            return "arrow.up.right"
        case .down:
            return "arrow.down.right"
        case .stable:
            return "arrow.right"
        }
    }

    func color(isPositive: Bool = true) -> String {
        switch self {
        case .up:
            return isPositive ? "green" : "red"
        case .down:
            return isPositive ? "red" : "green"
        case .stable:
            return "gray"
        }
    }
}

enum AnalyticsPeriod: String, CaseIterable {
    case day = "День"
    case week = "Неделя"
    case month = "Месяц"

    var days: Int {
        switch self {
        case .day:
            return 1
        case .week:
            return 7
        case .month:
            return 30
        }
    }

    var dateFormat: String {
        switch self {
        case .day:
            return "HH:mm"
        case .week:
            return "EEE"
        case .month:
            return "dd MMM"
        }
    }
}

struct AnalyticsSummary {

    let totalEvents: Int

    let averagePerDay: Double

    let trend: TrendDirection

    let percentageChange: Double

    let additionalInfo: [String: Double]

    init(
        totalEvents: Int,
        averagePerDay: Double,
        trend: TrendDirection,
        percentageChange: Double,
        additionalInfo: [String: Double] = [:]
    ) {
        self.totalEvents = totalEvents
        self.averagePerDay = averagePerDay
        self.trend = trend
        self.percentageChange = percentageChange
        self.additionalInfo = additionalInfo
    }
}

struct FeedingAnalytics {

    let summary: AnalyticsSummary

    let countByDay: [DailyChartData]

    let volumeOverTime: [ChartDataPoint]

    let distributionByType: [PieChartDataPoint]

    let averageInterval: Double

    let totalVolume: Double
}

struct SleepAnalytics {

    let summary: AnalyticsSummary

    let durationByDay: [DailyChartData]

    let totalTimeOverPeriod: [ChartDataPoint]

    let distributionByQuality: [PieChartDataPoint]

    let averageDuration: Double

    let longestSleep: Double

    let shortestSleep: Double
}

struct DiaperAnalytics {

    let summary: AnalyticsSummary

    let countByDay: [DailyChartData]

    let distributionByType: [PieChartDataPoint]

    let patternByHour: [Int: Int]

    let averageChangesPerDay: Double

    let timeSinceLastChange: Int?
}
