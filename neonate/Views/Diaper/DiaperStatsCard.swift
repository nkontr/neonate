import SwiftUI

struct DiaperStatsCard: View {

    let statistics: DiaperStatistics

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            HStack {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                        .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)

                    Image(systemName: "drop.fill")
                        .font(.title2)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .blue.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                Text(String(localized: "diapers_title"))
                    .font(.headline)
                    .fontWeight(.bold)

                Spacer()
            }

            HStack(spacing: 20) {
                StatItem(
                    title: String(localized: "today_stats"),
                    value: "\(statistics.todayCount)",
                    icon: "calendar",
                    color: .blue
                )

                Divider()
                    .frame(height: 40)

                StatItem(
                    title: String(localized: "last_stats"),
                    value: formatLastChange(),
                    icon: "clock.fill",
                    color: .orange
                )
            }

            VStack(spacing: 8) {
                HStack {
                    Label(String(localized: "wet_count"), systemImage: "drop.fill")
                        .foregroundColor(.blue)
                        .font(.caption)

                    Spacer()

                    Text("\(statistics.todayWetCount)")
                        .font(.caption)
                        .fontWeight(.semibold)
                }

                HStack {
                    Label(String(localized: "dirty_count"), systemImage: "sparkles")
                        .foregroundColor(.brown)
                        .font(.caption)

                    Spacer()

                    Text("\(statistics.todayDirtyCount)")
                        .font(.caption)
                        .fontWeight(.semibold)
                }

                HStack {
                    Label(String(localized: "average_per_day"), systemImage: "chart.bar.fill")
                        .foregroundColor(.green)
                        .font(.caption)

                    Spacer()

                    Text(String(format: "%.1f", statistics.averagePerDay))
                        .font(.caption)
                        .fontWeight(.semibold)
                }
            }
            .padding(.top, 8)
        }
        .liquidGlassCard(backgroundColor: .blue, cornerRadius: 20, glowColor: .blue)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(localized: "stats_accessibility_diaper"))
    }

    private func formatLastChange() -> String {
        guard let lastChange = statistics.lastChangeTime else {
            return String(localized: "no_data_stats")
        }

        guard let timeSince = statistics.timeSinceLastChange else {
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
struct DiaperStatsCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            DiaperStatsCard(
                statistics: DiaperStatistics(
                    todayCount: 8,
                    todayWetCount: 5,
                    todayDirtyCount: 3,
                    weekCount: 56,
                    averagePerDay: 8.0,
                    lastChangeTime: Date().addingTimeInterval(-3600),
                    timeSinceLastChange: 60,
                    typeStatistics: ["Мокрый": 5, "Грязный": 3]
                )
            )

            DiaperStatsCard(
                statistics: DiaperStatistics(
                    todayCount: 0,
                    todayWetCount: 0,
                    todayDirtyCount: 0,
                    weekCount: 0,
                    averagePerDay: 0,
                    lastChangeTime: nil,
                    timeSinceLastChange: nil,
                    typeStatistics: [:]
                )
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
