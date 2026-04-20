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
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.3), color.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                        .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)

                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [color, color.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .accessibilityLabel(title)
                }

                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.primary, .primary.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary.opacity(0.8))

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .liquidGlassCard(backgroundColor: color, cornerRadius: 20, glowColor: color)
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
