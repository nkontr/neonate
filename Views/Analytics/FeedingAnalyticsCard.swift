import SwiftUI
import Charts

struct FeedingAnalyticsCard: View {

    let analytics: FeedingAnalytics
    let period: AnalyticsPeriod

    @State private var selectedChart: FeedingChartType = .count

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            headerView

            chartTypePicker

            chartView
                .frame(height: 200)

            statisticsView

            if !analytics.distributionByType.isEmpty {
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
                Text("Кормления")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("\(analytics.summary.totalEvents) за период")
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

    private var chartTypePicker: some View {
        Picker("Тип графика", selection: $selectedChart) {
            Text("Количество").tag(FeedingChartType.count)
            Text("Объем").tag(FeedingChartType.volume)
        }
        .pickerStyle(.segmented)
    }

    @ViewBuilder
    private var chartView: some View {
        switch selectedChart {
        case .count:
            countBarChart
        case .volume:
            volumeLineChart
        }
    }

    private var countBarChart: some View {
        Chart {
            ForEach(analytics.countByDay) { daily in
                BarMark(
                    x: .value("Дата", daily.day, unit: .day),
                    y: .value("Количество", daily.eventCount)
                )
                .foregroundStyle(Color.blue.gradient)
                .cornerRadius(4)
                .accessibilityLabel(formatDate(daily.day))
                .accessibilityValue("\(daily.eventCount) кормлений")
            }

            RuleMark(y: .value("Среднее", analytics.summary.averagePerDay))
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

    private var volumeLineChart: some View {
        Chart {
            ForEach(analytics.volumeOverTime) { point in
                LineMark(
                    x: .value("Время", point.date),
                    y: .value("Объем, мл", point.value)
                )
                .foregroundStyle(Color.cyan.gradient)
                .interpolationMethod(.catmullRom)

                PointMark(
                    x: .value("Время", point.date),
                    y: .value("Объем, мл", point.value)
                )
                .foregroundStyle(Color.cyan)
                .symbolSize(30)
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { value in
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
                    if let volume = value.as(Double.self) {
                        Text("\(Int(volume)) мл")
                            .font(.caption2)
                    }
                }
            }
        }
        .animation(.easeInOut, value: analytics.volumeOverTime.count)
    }

    private var statisticsView: some View {
        VStack(spacing: 8) {
            StatRow(
                icon: "number",
                title: "Среднее в день",
                value: String(format: "%.1f", analytics.summary.averagePerDay),
                iconColor: .blue
            )

            if analytics.totalVolume > 0 {
                StatRow(
                    icon: "drop.fill",
                    title: "Общий объем",
                    value: "\(Int(analytics.totalVolume)) мл",
                    iconColor: .cyan
                )
            }

            if analytics.averageInterval > 0 {
                StatRow(
                    icon: "clock.fill",
                    title: "Средний интервал",
                    value: formatInterval(analytics.averageInterval),
                    iconColor: .orange
                )
            }
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

enum FeedingChartType {
    case count
    case volume
}

#if DEBUG
struct FeedingAnalyticsCard_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            FeedingAnalyticsCard(
                analytics: FeedingAnalytics(
                    summary: AnalyticsSummary(
                        totalEvents: 42,
                        averagePerDay: 6.0,
                        trend: .up,
                        percentageChange: 15.5
                    ),
                    countByDay: [],
                    volumeOverTime: [],
                    distributionByType: [
                        PieChartDataPoint(category: "Грудное", value: 25, color: "blue"),
                        PieChartDataPoint(category: "Бутылочка", value: 12, color: "green"),
                        PieChartDataPoint(category: "Прикорм", value: 5, color: "orange")
                    ],
                    averageInterval: 195,
                    totalVolume: 850
                ),
                period: .week
            )
            .padding()
        }
    }
}
#endif
