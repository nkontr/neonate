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
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Сон")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("\(analytics.summary.totalEvents) периодов сна")
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
                    x: .value("Дата", point.date, unit: .day),
                    y: .value("Часы", point.value / 60)
                )
                .foregroundStyle(Color.purple.gradient)
                .cornerRadius(4)
                .accessibilityLabel(formatDate(point.date))
                .accessibilityValue(formatDuration(point.value))
            }

            RuleMark(y: .value("Среднее", analytics.averageDuration / 60))
                .foregroundStyle(.gray.opacity(0.5))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                .accessibilityLabel("Среднее значение")
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
                        Text("\(Int(hours))ч")
                            .font(.caption2)
                    }
                }
            }
        }
        .animation(.easeInOut, value: analytics.totalTimeOverPeriod.count)
    }

    private var statisticsView: some View {
        VStack(spacing: 8) {
            StatRow(
                icon: "moon.fill",
                title: "Средняя продолжительность",
                value: formatDuration(analytics.averageDuration),
                iconColor: .purple
            )

            if analytics.longestSleep > 0 {
                StatRow(
                    icon: "arrow.up.circle.fill",
                    title: "Самый длинный сон",
                    value: formatDuration(analytics.longestSleep),
                    iconColor: .indigo
                )
            }

            if analytics.shortestSleep > 0 {
                StatRow(
                    icon: "arrow.down.circle.fill",
                    title: "Самый короткий сон",
                    value: formatDuration(analytics.shortestSleep),
                    iconColor: .blue
                )
            }

            let totalSleep = analytics.totalTimeOverPeriod.reduce(0) { $0 + $1.value }
            if totalSleep > 0 {
                StatRow(
                    icon: "clock.fill",
                    title: "Общее время сна",
                    value: formatDuration(totalSleep),
                    iconColor: .cyan
                )
            }
        }
    }

    private var pieChartView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Распределение по качеству")
                .font(.subheadline)
                .fontWeight(.semibold)

            Chart {
                ForEach(analytics.distributionByQuality) { item in
                    SectorMark(
                        angle: .value("Количество", item.value),
                        innerRadius: .ratio(0.5),
                        angularInset: 2
                    )
                    .foregroundStyle(by: .value("Качество", item.category))
                    .cornerRadius(4)
                    .accessibilityLabel(item.category)
                    .accessibilityValue("\(Int(item.percentage))%")
                }
            }
            .frame(height: 180)
            .chartLegend(position: .bottom, alignment: .center, spacing: 12)

            VStack(spacing: 4) {
                ForEach(analytics.distributionByQuality) { item in
                    HStack {
                        Text(item.category)
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
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = period.dateFormat
        return formatter.string(from: date)
    }

    private func formatDuration(_ minutes: Double) -> String {
        let hours = Int(minutes) / 60
        let mins = Int(minutes) % 60

        if hours > 0 && mins > 0 {
            return "\(hours)ч \(mins)м"
        } else if hours > 0 {
            return "\(hours)ч"
        } else {
            return "\(mins)м"
        }
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
