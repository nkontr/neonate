import SwiftUI

struct StatsCard: View {

    let icon: String
    let title: String
    let value: String
    let subtitle: String?
    let color: Color

    init(
        icon: String,
        title: String,
        value: String,
        subtitle: String? = nil,
        color: Color = .blue
    ) {
        self.icon = icon
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.color = color
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .accessibilityLabel(title)

                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
}

#Preview {
    VStack(spacing: 16) {
        StatsCard(
            icon: "fork.knife",
            title: "Кормлений сегодня",
            value: "8",
            subtitle: "Последнее: 2 часа назад",
            color: .orange
        )

        StatsCard(
            icon: "bed.double.fill",
            title: "Время сна",
            value: "12ч 30м",
            subtitle: "Среднее: 2ч 30м",
            color: .purple
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
