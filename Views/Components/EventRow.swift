import SwiftUI

struct EventRow: View {

    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let timestamp: String
    let details: String?

    init(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String,
        timestamp: String,
        details: String? = nil
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.timestamp = timestamp
        self.details = details
    }

    var body: some View {
        HStack(spacing: 16) {

            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 48, height: 48)
                .background(iconColor)
                .clipShape(Circle())
                .accessibilityLabel(title)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if let details = details {
                    Text(details)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Text(timestamp)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    List {
        EventRow(
            icon: "fork.knife",
            iconColor: .orange,
            title: "Грудное кормление",
            subtitle: "Левая грудь",
            timestamp: "2 часа назад",
            details: "Продолжительность: 15 минут"
        )

        EventRow(
            icon: "bed.double.fill",
            iconColor: .purple,
            title: "Дневной сон",
            subtitle: "Хорошее качество",
            timestamp: "30 минут назад",
            details: "Длительность: 1ч 30м"
        )

        EventRow(
            icon: "allergens",
            iconColor: .green,
            title: "Смена подгузника",
            subtitle: "Мокрый",
            timestamp: "1 час назад"
        )
    }
}
