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
        .animation(.easeInOut(duration: 0.3), value: selectedChart)
        .liquidGlassCard(backgroundColor: .green, cornerRadius: 20, glowColor: .green)
    }

    private var headerView: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.green.opacity(0.3), Color.green.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                    .shadow(color: Color.green.opacity(0.3), radius: 8, x: 0, y: 4)

                Image(systemName: "fork.knife.circle.fill")
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green, .green.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(String(localized: "analytics_feedings"))
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

    private var chartTypePicker: some View {
        Picker(String(localized: "analytics_chart_type"), selection: $selectedChart) {
            Text(String(localized: "analytics_count")).tag(FeedingChartType.count)
            Text(String(localized: "analytics_volume")).tag(FeedingChartType.volume)
        }
        .pickerStyle(.segmented)
    }

    @ViewBuilder
    private var chartView: some View {
        ZStack {
            if selectedChart == .count {
                countBarChart
                    .transition(.opacity)
            }
            if selectedChart == .volume {
                volumeLineChart
                    .transition(.opacity)
            }
        }
    }

    private var countBarChart: some View {
        Chart {
            ForEach(analytics.countByDay) { daily in
                BarMark(
                    x: .value(String(localized: "analytics_date"), daily.day, unit: .day),
                    y: .value(String(localized: "analytics_count_value"), daily.eventCount)
                )
                .foregroundStyle(Color.blue.gradient)
                .cornerRadius(4)
                .accessibilityLabel(formatDate(daily.day))
                .accessibilityValue(String(format: NSLocalizedString("analytics_feedings_count", comment: ""), daily.eventCount))
            }

            RuleMark(y: .value(String(localized: "analytics_average_value"), analytics.summary.averagePerDay))
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
            AxisMarks(position: .leading)
        }
        .animation(.smooth(duration: 0.6), value: analytics.countByDay.count)
    }

    private var volumeLineChart: some View {
        Chart {
            ForEach(analytics.volumeOverTime) { point in
                LineMark(
                    x: .value(String(localized: "analytics_time"), point.date),
                    y: .value(String(localized: "analytics_volume_ml"), point.value)
                )
                .foregroundStyle(Color.cyan.gradient)
                .interpolationMethod(.catmullRom)

                PointMark(
                    x: .value(String(localized: "analytics_time"), point.date),
                    y: .value(String(localized: "analytics_volume_ml"), point.value)
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
                        Text("\(Int(volume)) \(String(localized: "unit_ml"))")
                            .font(.caption2)
                    }
                }
            }
        }
        .animation(.smooth(duration: 0.6), value: analytics.volumeOverTime.count)
    }

    private var statisticsView: some View {
        VStack(spacing: 8) {
            StatRow(
                icon: "number",
                title: String(localized: "analytics_average_per_day"),
                value: String(format: "%.1f", analytics.summary.averagePerDay),
                iconColor: .blue
            )

            if analytics.totalVolume > 0 {
                StatRow(
                    icon: "drop.fill",
                    title: String(localized: "analytics_total_volume"),
                    value: "\(Int(analytics.totalVolume)) \(String(localized: "unit_ml"))",
                    iconColor: .cyan
                )
            }

            if analytics.averageInterval > 0 {
                StatRow(
                    icon: "clock.fill",
                    title: String(localized: "analytics_average_interval"),
                    value: formatInterval(analytics.averageInterval),
                    iconColor: .orange
                )
            }
        }
    }

    private var pieChartView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "analytics_distribution_by_type"))
                .font(.subheadline)
                .fontWeight(.semibold)

            Chart {
                ForEach(analytics.distributionByType) { item in
                    SectorMark(
                        angle: .value("Количество", item.value),
                        innerRadius: .ratio(0.5),
                        angularInset: 2
                    )
                    .foregroundStyle(by: .value("Тип", localizedFeedingType(item.category)))
                    .cornerRadius(4)
                    .accessibilityLabel(localizedFeedingType(item.category))
                    .accessibilityValue("\(Int(item.percentage))%")
                }
            }
            .frame(height: 180)
            .chartLegend(position: .bottom, alignment: .center, spacing: 12)

            VStack(spacing: 4) {
                ForEach(analytics.distributionByType) { item in
                    HStack {
                        Text(localizedFeedingType(item.category))
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

    private func formatInterval(_ minutes: Double) -> String {
        let hours = Int(minutes) / 60
        let mins = Int(minutes) % 60

        if hours > 0 {
            return String(format: NSLocalizedString("duration_hours_minutes", comment: ""), hours, mins)
        } else {
            return String(format: NSLocalizedString("duration_minutes", comment: ""), mins)
        }
    }

    private func localizedFeedingType(_ type: String) -> String {
        let normalized = type.trimmingCharacters(in: .whitespaces)

        if normalized == "Грудное" || normalized == "Грудное вскармливание" || normalized == "Breast" || normalized == "Breastfeeding" {
            return String(localized: "feeding_type_breast_feeding")
        } else if normalized == "Бутылочка" || normalized == "Кормление из бутылочки" || normalized == "Bottle" || normalized == "Bottle feeding" {
            return String(localized: "feeding_type_bottle_feeding")
        } else if normalized == "Прикорм" || normalized == "Solid" || normalized == "Complementary feeding" {
            return String(localized: "feeding_type_complementary_feeding")
        }

        return type
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
