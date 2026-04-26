import SwiftUI
import CoreData

struct DiaperDetailView: View {

    @Environment(\.dismiss) private var dismiss

    let event: DiaperEvent

    var body: some View {
        NavigationView {
            List {

                Section(String(localized: "detail_information")) {
                    HStack {
                        Image(systemName: getDiaperIcon(for: event.diaperType))
                            .foregroundColor(getDiaperColor(for: event.diaperType))
                            .font(.title2)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(localizedDiaperType(event.diaperType))
                                .font(.headline)

                            Text(formatDateTime(event.timestamp))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                if let notes = event.notes, !notes.isEmpty {
                    Section(String(localized: "form_notes")) {
                        Text(notes)
                            .font(.body)
                    }
                }

                Section(String(localized: "diaper_interval_section")) {
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.blue)

                        Text(getTimeSinceLastChange())
                            .font(.body)
                    }
                }

                if let child = event.child {
                    Section(String(localized: "child_section")) {
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
            .navigationTitle(String(localized: "diaper_change_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "done")) {
                        dismiss()
                    }
                }
            }
        }
    }

    private func localizedDiaperType(_ type: String?) -> String {
        guard let type = type else {
            return String(localized: "diaper_change_default")
        }

        let normalized = type.trimmingCharacters(in: .whitespaces)

        // Russian and English variants
        if normalized == "Мокрый" || normalized == "Wet" {
            return String(localized: "diaper_type_wet")
        } else if normalized == "Грязный" || normalized == "Dirty" {
            return String(localized: "diaper_type_dirty")
        } else if normalized == "Оба" || normalized == "Both" {
            return String(localized: "diaper_type_both")
        }

        return type
    }

    private func getDiaperIcon(for type: String?) -> String {
        guard let type = type else { return "drop.fill" }

        let normalized = type.trimmingCharacters(in: .whitespaces)

        // Check both Russian and English variants
        if normalized == "Мокрый" || normalized == "Wet" {
            return "drop.fill"
        } else if normalized == "Грязный" || normalized == "Dirty" {
            return "sparkles"
        } else if normalized == "Оба" || normalized == "Both" {
            return "drop.triangle.fill"
        }

        return "drop.fill"
    }

    private func getDiaperColor(for type: String?) -> Color {
        guard let type = type else { return .blue }

        let normalized = type.trimmingCharacters(in: .whitespaces)

        // Check both Russian and English variants
        if normalized == "Мокрый" || normalized == "Wet" {
            return .blue
        } else if normalized == "Грязный" || normalized == "Dirty" {
            return .brown
        } else if normalized == "Оба" || normalized == "Both" {
            return .orange
        }

        return .blue
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
            return String(localized: "unknown")
        }

        let now = Date()
        let interval = now.timeIntervalSince(timestamp)

        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60

        if hours > 0 {
            let hoursStr = String(localized: "hours_short")
            let minsStr = String(localized: "minutes_short")
            let agoStr = String(localized: "time_ago")
            return "\(hours) \(hoursStr) \(minutes) \(minsStr) \(agoStr)"
        } else if minutes > 0 {
            let minsStr = String(localized: "minutes_short")
            let agoStr = String(localized: "time_ago")
            return "\(minutes) \(minsStr) \(agoStr)"
        } else {
            return String(localized: "just_now")
        }
    }

    private func getAge(from dateOfBirth: Date) -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .day], from: dateOfBirth, to: Date())

        if let months = components.month, let days = components.day {
            if months < 1 {
                return "\(days) \(String(localized: "age_days_short"))"
            } else if months < 12 {
                return "\(months) \(String(localized: "age_months_short"))"
            } else {
                let years = months / 12
                let remainingMonths = months % 12
                return "\(years) \(String(localized: "age_years_short")) \(remainingMonths) \(String(localized: "age_months_short"))"
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
