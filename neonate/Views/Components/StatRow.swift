import SwiftUI

struct StatRow: View {

    let icon: String
    let title: String
    let value: String
    let iconColor: Color

    var body: some View {
        HStack(spacing: 12) {

            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(iconColor)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(value)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

#if DEBUG
struct StatRow_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            StatRow(
                icon: "chart.bar.fill",
                title: "Всего кормлений",
                value: "42",
                iconColor: .blue
            )

            StatRow(
                icon: "drop.fill",
                title: "Общий объем",
                value: "850 мл",
                iconColor: .cyan
            )

            StatRow(
                icon: "clock.fill",
                title: "Средний интервал",
                value: "3ч 15м",
                iconColor: .orange
            )
        }
        .padding()
    }
}
#endif
