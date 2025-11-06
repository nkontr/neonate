import SwiftUI

struct FeedingStatsCard: View {

    let statistics: FeedingStatistics

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            HStack {
                Image(systemName: "fork.knife.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)

                Text("Кормления")
                    .font(.headline)

                Spacer()
            }

            HStack(spacing: 20) {
                StatItem(
                    title: "Сегодня",
                    value: "\(statistics.todayCount)",
                    icon: "calendar",
                    color: .green
                )

                Divider()
                    .frame(height: 40)

                StatItem(
                    title: "Последнее",
                    value: formatLastFeeding(),
                    icon: "clock.fill",
                    color: .orange
                )
            }

            VStack(spacing: 8) {
                if statistics.todayVolume > 0 {
                    HStack {
                        Label("Объем сегодня", systemImage: "drop.fill")
                            .foregroundColor(.blue)
                            .font(.caption)

                        Spacer()

                        Text("\(Int(statistics.todayVolume)) мл")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                }

                if statistics.todayDuration > 0 {
                    HStack {
                        Label("Время сегодня", systemImage: "timer")
                            .foregroundColor(.purple)
                            .font(.caption)

                        Spacer()

                        Text("\(statistics.todayDuration) мин")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                }

                HStack {
                    Label("Среднее время", systemImage: "chart.bar.fill")
                        .foregroundColor(.green)
                        .font(.caption)

                    Spacer()

                    Text(String(format: "%.1f мин", statistics.averageDuration))
                        .font(.caption)
                        .fontWeight(.semibold)
                }
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Статистика кормлений")
    }

    private func formatLastFeeding() -> String {
        guard let lastFeeding = statistics.lastFeedingTime else {
            return "Нет данных"
        }

        guard let timeSince = statistics.timeSinceLastFeeding else {
            return "Только что"
        }

        let hours = timeSince / 60
        let minutes = timeSince % 60

        if hours > 0 {
            return "\(hours)ч \(minutes)м"
        } else {
            return "\(minutes)м"
        }
    }
}

private struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)

                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#if DEBUG
struct FeedingStatsCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            FeedingStatsCard(
                statistics: FeedingStatistics(
                    todayCount: 8,
                    todayVolume: 600.0,
                    todayDuration: 120,
                    weekCount: 56,
                    weekVolume: 4200.0,
                    averageDuration: 15.5,
                    lastFeedingTime: Date().addingTimeInterval(-7200),
                    timeSinceLastFeeding: 120
                )
            )

            FeedingStatsCard(
                statistics: FeedingStatistics(
                    todayCount: 0,
                    todayVolume: 0,
                    todayDuration: 0,
                    weekCount: 0,
                    weekVolume: 0,
                    averageDuration: 0,
                    lastFeedingTime: nil,
                    timeSinceLastFeeding: nil
                )
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
