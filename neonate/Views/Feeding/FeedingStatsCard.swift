import SwiftUI

struct FeedingStatsCard: View {

    let statistics: FeedingStatistics

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

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

                Text(String(localized: "feedings_title"))
                    .font(.headline)
                    .fontWeight(.bold)

                Spacer()
            }

            HStack(spacing: 20) {
                StatItem(
                    title: String(localized: "today_stats"),
                    value: "\(statistics.todayCount)",
                    icon: "calendar",
                    color: .green
                )

                Divider()
                    .frame(height: 40)

                StatItem(
                    title: String(localized: "last_stats"),
                    value: formatLastFeeding(),
                    icon: "clock.fill",
                    color: .orange
                )
            }

            VStack(spacing: 8) {
                if statistics.todayVolume > 0 {
                    HStack {
                        Label(String(localized: "volume_today"), systemImage: "drop.fill")
                            .foregroundColor(.blue)
                            .font(.caption)

                        Spacer()

                        Text("\(Int(statistics.todayVolume)) \(String(localized: "unit_ml"))")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                }

                if statistics.todayDuration > 0 {
                    HStack {
                        Label(String(localized: "time_today"), systemImage: "timer")
                            .foregroundColor(.purple)
                            .font(.caption)

                        Spacer()

                        Text(String(format: NSLocalizedString("minutes_short_format", comment: ""), statistics.todayDuration))
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                }

                HStack {
                    Label(String(localized: "average_time"), systemImage: "chart.bar.fill")
                        .foregroundColor(.green)
                        .font(.caption)

                    Spacer()

                    Text(String(format: "%.1f \(String(localized: "unit_minutes"))", statistics.averageDuration))
                        .font(.caption)
                        .fontWeight(.semibold)
                }
            }
            .padding(.top, 8)
        }
        .liquidGlassCard(backgroundColor: .green, cornerRadius: 20, glowColor: .green)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(localized: "stats_accessibility_feeding"))
    }

    private func formatLastFeeding() -> String {
        guard let lastFeeding = statistics.lastFeedingTime else {
            return String(localized: "no_data_stats")
        }

        guard let timeSince = statistics.timeSinceLastFeeding else {
            return String(localized: "just_now_stats")
        }

        let hours = timeSince / 60
        let minutes = timeSince % 60

        if hours > 0 {
            return String(format: NSLocalizedString("duration_hours_minutes", comment: ""), hours, minutes)
        } else {
            return String(format: NSLocalizedString("duration_minutes", comment: ""), minutes)
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
