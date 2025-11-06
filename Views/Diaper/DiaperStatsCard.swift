import SwiftUI

struct DiaperStatsCard: View {

    let statistics: DiaperStatistics

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            HStack {
                Image(systemName: "drop.fill")
                    .foregroundColor(.blue)
                    .font(.title2)

                Text("Подгузники")
                    .font(.headline)

                Spacer()
            }

            HStack(spacing: 20) {
                StatItem(
                    title: "Сегодня",
                    value: "\(statistics.todayCount)",
                    icon: "calendar",
                    color: .blue
                )

                Divider()
                    .frame(height: 40)

                StatItem(
                    title: "Последняя",
                    value: formatLastChange(),
                    icon: "clock.fill",
                    color: .orange
                )
            }

            VStack(spacing: 8) {
                HStack {
                    Label("Мокрых", systemImage: "drop.fill")
                        .foregroundColor(.blue)
                        .font(.caption)

                    Spacer()

                    Text("\(statistics.todayWetCount)")
                        .font(.caption)
                        .fontWeight(.semibold)
                }

                HStack {
                    Label("Грязных", systemImage: "sparkles")
                        .foregroundColor(.brown)
                        .font(.caption)

                    Spacer()

                    Text("\(statistics.todayDirtyCount)")
                        .font(.caption)
                        .fontWeight(.semibold)
                }

                HStack {
                    Label("Среднее в день", systemImage: "chart.bar.fill")
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
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Статистика смен подгузников")
    }

    private func formatLastChange() -> String {
        guard let lastChange = statistics.lastChangeTime else {
            return "Нет данных"
        }

        guard let timeSince = statistics.timeSinceLastChange else {
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
