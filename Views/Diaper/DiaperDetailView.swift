import SwiftUI
import CoreData

struct DiaperDetailView: View {

    @Environment(\.dismiss) private var dismiss

    let event: DiaperEvent

    var body: some View {
        NavigationView {
            List {

                Section("Информация") {
                    HStack {
                        Image(systemName: getDiaperIcon(for: event.diaperType))
                            .foregroundColor(getDiaperColor(for: event.diaperType))
                            .font(.title2)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(event.diaperType ?? "Смена подгузника")
                                .font(.headline)

                            Text(formatDateTime(event.timestamp))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                if let notes = event.notes, !notes.isEmpty {
                    Section("Заметки") {
                        Text(notes)
                            .font(.body)
                    }
                }

                Section("Интервал") {
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.blue)

                        Text(getTimeSinceLastChange())
                            .font(.body)
                    }
                }

                if let child = event.child {
                    Section("Ребенок") {
                        HStack {
                            if let photoData = child.photoData,
                               let uiImage = UIImage(data: photoData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 50, height: 50)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.gray)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(child.name ?? "")
                                    .font(.headline)

                                if let dateOfBirth = child.dateOfBirth {
                                    Text(getAge(from: dateOfBirth))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Смена подгузника")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func getDiaperIcon(for type: String?) -> String {
        guard let type = type else { return "drop.fill" }

        switch type {
        case "Мокрый":
            return "drop.fill"
        case "Грязный":
            return "sparkles"
        case "Оба":
            return "drop.triangle.fill"
        default:
            return "drop.fill"
        }
    }

    private func getDiaperColor(for type: String?) -> Color {
        guard let type = type else { return .blue }

        switch type {
        case "Мокрый":
            return .blue
        case "Грязный":
            return .brown
        case "Оба":
            return .orange
        default:
            return .blue
        }
    }

    private func formatDateTime(_ date: Date?) -> String {
        guard let date = date else { return "" }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short

        return formatter.string(from: date)
    }

    private func getTimeSinceLastChange() -> String {
        guard let timestamp = event.timestamp else {
            return "Неизвестно"
        }

        let now = Date()
        let interval = now.timeIntervalSince(timestamp)

        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60

        if hours > 0 {
            return "\(hours) ч. \(minutes) мин. назад"
        } else if minutes > 0 {
            return "\(minutes) мин. назад"
        } else {
            return "Только что"
        }
    }

    private func getAge(from dateOfBirth: Date) -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .day], from: dateOfBirth, to: Date())

        if let months = components.month, let days = components.day {
            if months < 1 {
                return "\(days) дн."
            } else if months < 12 {
                return "\(months) мес."
            } else {
                let years = months / 12
                let remainingMonths = months % 12
                return "\(years) г. \(remainingMonths) мес."
            }
        }

        return ""
    }
}

#if DEBUG
struct DiaperDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let child = ChildProfile(context: context)
        child.id = UUID()
        child.name = "Тестовый ребенок"
        child.dateOfBirth = Date().addingTimeInterval(-90 * 24 * 60 * 60)

        let event = DiaperEvent(context: context)
        event.id = UUID()
        event.timestamp = Date()
        event.diaperType = "Мокрый"
        event.notes = "Первая смена утром"
        event.child = child

        return DiaperDetailView(event: event)
    }
}
#endif
