import SwiftUI
import Charts

struct SleepAnalyticsCard: View {

    let analytics: SleepAnalytics
    let period: AnalyticsPeriod

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            headerView

            durationBarChart
                .frame(height: 200)

            statisticsView

            if !analytics.distributionByQuality.isEmpty {
                Divider()
                pieChartView
            }
        }
        .liquidGlassCard(backgroundColor: .purple, cornerRadius: 20, glowColor: .purple)
    }

    private var headerView: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.purple.opacity(0.3), Color.purple.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                    .shadow(color: Color.purple.opacity(0.3), radius: 8, x: 0, y: 4)

                Image(systemName: "moon.zzz.fill")
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .purple.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(String(localized: "analytics_sleep"))
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text(String(format: NSLocalizedString("analytics_events_in_period", comment: ""), analytics.summary.totalEvents))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            TrendIndicator(
                trend: analytics.summary.trend,
                percentageChange: analytics.summary.percentageChange,
                isPositiveGood: true
            )
        }
    }

    private var durationBarChart: some View {
        Chart {
            ForEach(analytics.totalTimeOverPeriod) { point in
                BarMark(
                    x: .value(String(localized: "analytics_date"), point.date, unit: .day),
                    y: .value(String(localized: "unit_hours"), point.value / 60)
                )
                .foregroundStyle(Color.purple.gradient)
                .cornerRadius(4)
                .accessibilityLabel(formatDate(point.date))
                .accessibilityValue(formatDuration(point.value))
            }

            RuleMark(y: .value(String(localized: "analytics_average_value"), analytics.averageDuration / 60))
                .foregroundStyle(.gray.opacity(0.5))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                .accessibilityLabel(String(localized: "analytics_average_value"))
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { value in
                if let date = value.as(Date.self) {
                    AxisValueLabel {
                        Text(formatDate(date))
                            .font(.caption2)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisValueLabel {
                    if let hours = value.as(Double.self) {
                        Text(String(format: NSLocalizedString("duration_hours", comment: ""), Int(hours)))
                            .font(.caption2)
                    }
                }
            }
        }
        .animation(.smooth(duration: 0.6), value: analytics.totalTimeOverPeriod.count)
    }

    private var statisticsView: some View {
        VStack(spacing: 8) {
            StatRow(
                icon: "moon.fill",
                title: String(localized: "analytics_average_duration"),
                value: formatDuration(analytics.averageDuration),
                iconColor: .purple
            )

            if analytics.longestSleep > 0 {
                StatRow(
                    icon: "arrow.up.circle.fill",
                    title: String(localized: "analytics_longest_sleep"),
                    value: formatDuration(analytics.longestSleep),
                    iconColor: .indigo
                )
            }

            if analytics.shortestSleep > 0 {
                StatRow(
                    icon: "arrow.down.circle.fill",
                    title: String(localized: "analytics_shortest_sleep"),
                    value: formatDuration(analytics.shortestSleep),
                    iconColor: .blue
                )
            }

            let totalSleep = analytics.totalTimeOverPeriod.reduce(0) { $0 + $1.value }
            if totalSleep > 0 {
                StatRow(
                    icon: "clock.fill",
                    title: String(localized: "analytics_total_time"),
                    value: formatDuration(totalSleep),
                    iconColor: .cyan
                )
            }
        }
    }

    private var pieChartView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "analytics_distribution_by_quality"))
                .font(.subheadline)
                .fontWeight(.semibold)

            Chart {
                ForEach(analytics.distributionByQuality) { item in
                    SectorMark(
                        angle: .value("Количество", item.value),
                        innerRadius: .ratio(0.5),
                        angularInset: 2
                    )
                    .foregroundStyle(by: .value("Качество", localizedQuality(item.category)))
                    .cornerRadius(4)
                    .accessibilityLabel(localizedQuality(item.category))
                    .accessibilityValue("\(Int(item.percentage))%")
                }
            }
            .frame(height: 180)
            .chartLegend(position: .bottom, alignment: .center, spacing: 12)

            VStack(spacing: 4) {
                ForEach(analytics.distributionByQuality) { item in
                    HStack {
                        Text(localizedQuality(item.category))
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Spacer()

                        Text(String(format: "%.0f%%", item.percentage))
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                }
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = period.dateFormat
        return formatter.string(from: date)
    }

    private func formatDuration(_ minutes: Double) -> String {
        let hours = Int(minutes) / 60
        let mins = Int(minutes) % 60

        if hours > 0 && mins > 0 {
            return String(format: NSLocalizedString("duration_hours_minutes", comment: ""), hours, mins)
        } else if hours > 0 {
            return String(format: NSLocalizedString("duration_hours", comment: ""), hours)
        } else {
            return String(format: NSLocalizedString("duration_minutes", comment: ""), mins)
        }
    }

    private func localizedQuality(_ quality: String) -> String {
        let normalized = quality.trimmingCharacters(in: .whitespaces)

        if normalized == "Отлично" || normalized == "Excellent" {
            return String(localized: "sleep_quality_excellent")
        } else if normalized == "Хорошо" || normalized == "Good" {
            return String(localized: "sleep_quality_good")
        } else if normalized == "Плохо" || normalized == "Poor" {
            return String(localized: "sleep_quality_poor")
        }

        return quality
    }
}

#if DEBUG
struct SleepAnalyticsCard_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            SleepAnalyticsCard(
                analytics: SleepAnalytics(
                    summary: AnalyticsSummary(
                        totalEvents: 28,
                        averagePerDay: 4.0,
                        trend: .up,
                        percentageChange: 12.5
                    ),
                    durationByDay: [],
                    totalTimeOverPeriod: [],
                    distributionByQuality: [
                        PieChartDataPoint(category: "Отлично", value: 15, color: "green"),
                        PieChartDataPoint(category: "Хорошо", value: 10, color: "blue"),
                        PieChartDataPoint(category: "Плохо", value: 3, color: "red")
                    ],
                    averageDuration: 120,
                    longestSleep: 240,
                    shortestSleep: 45
                ),
                period: .week
            )
            .padding()
        }
    }
}
#endif
