import SwiftUI
import Charts

struct DiaperAnalyticsCard: View {

    let analytics: DiaperAnalytics
    let period: AnalyticsPeriod

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            headerView

            countBarChart
                .frame(height: 200)

            statisticsView

            if !analytics.distributionByType.isEmpty {
                Divider()
                pieChartView
            }

            if !analytics.patternByHour.isEmpty {
                Divider()
                heatmapView
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
                Text("Подгузники")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("\(analytics.summary.totalEvents) смен")
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

    private var countBarChart: some View {
        Chart {
            ForEach(analytics.countByDay) { daily in
                BarMark(
                    x: .value("Дата", daily.day, unit: .day),
                    y: .value("Количество", daily.eventCount)
                )
                .foregroundStyle(Color.green.gradient)
                .cornerRadius(4)
                .accessibilityLabel(formatDate(daily.day))
                .accessibilityValue("\(daily.eventCount) смен")
            }

            RuleMark(y: .value("Среднее", analytics.averageChangesPerDay))
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
            AxisMarks(position: .leading)
        }
        .animation(.easeInOut, value: analytics.countByDay.count)
    }

    private var statisticsView: some View {
        VStack(spacing: 8) {
            StatRow(
                icon: "number",
                title: "Среднее в день",
                value: String(format: "%.1f", analytics.averageChangesPerDay),
                iconColor: .green
            )

            if let timeSinceLast = analytics.timeSinceLastChange {
                StatRow(
                    icon: "clock.fill",
                    title: "С последней смены",
                    value: formatInterval(Double(timeSinceLast)),
                    iconColor: .orange
                )
            }

            StatRow(
                icon: "calendar",
                title: "Всего за период",
                value: "\(analytics.summary.totalEvents)",
                iconColor: .blue
            )
        }
    }

    private var pieChartView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Распределение по типам")
                .font(.subheadline)
                .fontWeight(.semibold)

            Chart {
                ForEach(analytics.distributionByType) { item in
                    SectorMark(
                        angle: .value("Количество", item.value),
                        innerRadius: .ratio(0.5),
                        angularInset: 2
                    )
                    .foregroundStyle(by: .value("Тип", item.category))
                    .cornerRadius(4)
                    .accessibilityLabel(item.category)
                    .accessibilityValue("\(Int(item.percentage))%")
                }
            }
            .frame(height: 180)
            .chartLegend(position: .bottom, alignment: .center, spacing: 12)

            VStack(spacing: 4) {
                ForEach(analytics.distributionByType) { item in
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

    private var heatmapView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Паттерн смены по часам")
                .font(.subheadline)
                .fontWeight(.semibold)

            Chart {
                ForEach(Array(analytics.patternByHour.sorted(by: { $0.key < $1.key })), id: \.key) { hour, count in
                    BarMark(
                        x: .value("Час", hour),
                        y: .value("Смены", count)
                    )
                    .foregroundStyle(Color.teal.gradient)
                    .accessibilityLabel("\(hour):00")
                    .accessibilityValue("\(count) смен")
                }
            }
            .frame(height: 150)
            .chartXAxis {
                AxisMarks(values: .stride(by: 3)) { value in
                    if let hour = value.as(Int.self) {
                        AxisValueLabel {
                            Text("\(hour):00")
                                .font(.caption2)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }

            Text("Наиболее частое время смены подгузников за последние 30 дней")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = period.dateFormat
        return formatter.string(from: date)
    }

    private func formatInterval(_ minutes: Double) -> String {
        let hours = Int(minutes) / 60
        let mins = Int(minutes) % 60

        if hours > 0 {
            return "\(hours)ч \(mins)м"
        } else {
            return "\(mins)м"
        }
    }
}

#if DEBUG
struct DiaperAnalyticsCard_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            DiaperAnalyticsCard(
                analytics: DiaperAnalytics(
                    summary: AnalyticsSummary(
                        totalEvents: 56,
                        averagePerDay: 8.0,
                        trend: .stable,
                        percentageChange: 2.1
                    ),
                    countByDay: [],
                    distributionByType: [
                        PieChartDataPoint(category: "Мокрый", value: 30, color: "blue"),
                        PieChartDataPoint(category: "Грязный", value: 15, color: "orange"),
                        PieChartDataPoint(category: "Оба", value: 11, color: "red")
                    ],
                    patternByHour: [
                        0: 2, 3: 1, 6: 3, 9: 5, 12: 6, 15: 4, 18: 5, 21: 3
                    ],
                    averageChangesPerDay: 8.0,
                    timeSinceLastChange: 145
                ),
                period: .week
            )
            .padding()
        }
    }
}
#endif
