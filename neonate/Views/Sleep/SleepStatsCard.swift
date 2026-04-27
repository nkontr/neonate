import SwiftUI

struct SleepStatsCard: View {

    let statistics: SleepStatistics

    var body: some View {
        let _ = Self._printChanges()
        VStack(alignment: .leading, spacing: 16) {

            HStack {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.indigo.opacity(0.3), Color.indigo.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                        .shadow(color: Color.indigo.opacity(0.3), radius: 8, x: 0, y: 4)

                    Image(systemName: "moon.zzz.fill")
                        .font(.title2)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.indigo, .indigo.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                Text(String(localized: "sleep_title"))
                    .font(.headline)
                    .fontWeight(.bold)

                Spacer()

                if statistics.isCurrentlySleeping {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)

                        Text(String(localized: "sleeping_now"))
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }

            HStack(spacing: 20) {
                StatItem(
                    title: String(localized: "today_stats"),
                    value: formatDuration(statistics.todayTotalMinutes),
                    icon: "calendar",
                    color: .indigo
                )

                Divider()
                    .frame(height: 40)

                StatItem(
                    title: String(localized: "sessions_stats"),
                    value: "\(statistics.todayCount)",
                    icon: "bed.double.fill",
                    color: .purple
                )
            }

            VStack(spacing: 8) {
                HStack {
                    Label(String(localized: "average_time"), systemImage: "chart.bar.fill")
                        .foregroundColor(.blue)
                        .font(.caption)

                    Spacer()

                    Text(formatDuration(Int(statistics.averageDuration)))
                        .font(.caption)
                        .fontWeight(.semibold)
                }

                if !statistics.isCurrentlySleeping {
                    HStack {
                        Label(String(localized: "since_last_sleep"), systemImage: "clock.fill")
                            .foregroundColor(.orange)
                            .font(.caption)

                        Spacer()

                        Text(formatTimeSinceLastSleep())
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                }

                if let bestQuality = getMostCommonQuality() {
                    HStack {
                        Label(String(localized: "common_quality"), systemImage: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)

                        Spacer()

                        Text(bestQuality)
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                }
            }
            .padding(.top, 8)
        }
        .liquidGlassCard(backgroundColor: .indigo, cornerRadius: 20, glowColor: .indigo)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(localized: "stats_accessibility_sleep"))
    }

    private func formatDuration(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60

        if hours > 0 {
            return String(format: NSLocalizedString("duration_hours_minutes", comment: ""), hours, mins)
        } else {
            return String(format: NSLocalizedString("duration_minutes", comment: ""), mins)
        }
    }

    private func formatTimeSinceLastSleep() -> String {
        guard let timeSince = statistics.timeSinceLastSleep else {
            return String(localized: "no_data_stats")
        }

        let hours = timeSince / 60
        let minutes = timeSince % 60

        if hours > 0 {
            return String(format: NSLocalizedString("duration_hours_minutes", comment: ""), hours, minutes)
        } else {
            return String(format: NSLocalizedString("duration_minutes", comment: ""), minutes)
        }
    }

    private func getMostCommonQuality() -> String? {
        let qualities = statistics.qualityStatistics
        guard !qualities.isEmpty else { return nil }

        let sorted = qualities.sorted { $0.value > $1.value }
        return sorted.first?.key
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
struct SleepStatsCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            SleepStatsCard(
                statistics: SleepStatistics(
                    todayCount: 5,
                    todayTotalMinutes: 480,
                    weekCount: 35,
                    weekTotalMinutes: 3360,
                    averageDuration: 96.0,
                    qualityStatistics: ["Хорошо": 20, "Отлично": 10, "Плохо": 5],
                    locationStatistics: ["Кроватка": 25, "Коляска": 10],
                    isCurrentlySleeping: false,
                    timeSinceLastSleep: 120
                )
            )

            SleepStatsCard(
                statistics: SleepStatistics(
                    todayCount: 2,
                    todayTotalMinutes: 180,
                    weekCount: 14,
                    weekTotalMinutes: 1260,
                    averageDuration: 90.0,
                    qualityStatistics: ["Хорошо": 8, "Плохо": 6],
                    locationStatistics: ["Кроватка": 14],
                    isCurrentlySleeping: true,
                    timeSinceLastSleep: nil
                )
            )

            SleepStatsCard(
                statistics: SleepStatistics(
                    todayCount: 0,
                    todayTotalMinutes: 0,
                    weekCount: 0,
                    weekTotalMinutes: 0,
                    averageDuration: 0,
                    qualityStatistics: [:],
                    locationStatistics: [:],
                    isCurrentlySleeping: false,
                    timeSinceLastSleep: nil
                )
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
