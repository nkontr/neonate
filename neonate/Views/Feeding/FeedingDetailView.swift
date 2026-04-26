import SwiftUI

struct FeedingDetailView: View {

    let event: FeedingEvent
    @ObservedObject var viewModel: FeedingViewModel
    @ObservedObject var childViewModel: ChildProfileViewModel

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section(String(localized: "detail_information")) {
                DetailRow(label: String(localized: "detail_type"), value: localizedFeedingType(event.feedingType ?? ""))
                if let timestamp = event.timestamp {
                    DetailRow(label: String(localized: "detail_time"), value: formatDate(timestamp))
                }
                if let breast = event.breast {
                    DetailRow(label: String(localized: "detail_breast"), value: localizedBreast(breast))
                }
                if event.duration > 0 {
                    DetailRow(label: String(localized: "detail_duration"), value: "\(event.duration) \(String(localized: "unit_minutes"))")
                }
                if event.volume > 0 {
                    DetailRow(label: String(localized: "detail_volume"), value: "\(Int(event.volume)) \(String(localized: "unit_ml"))")
                }
            }

            if let notes = event.notes, !notes.isEmpty {
                Section(String(localized: "detail_notes")) {
                    Text(notes)
                }
            }

            Section {
                Button(role: .destructive) {
                    deleteEvent()
                } label: {
                    Label(String(localized: "detail_delete"), systemImage: "trash")
                }
            }
        }
        .navigationTitle(String(localized: "detail_feeding_title"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func deleteEvent() {
        guard let childId = childViewModel.selectedChild?.id else { return }
        Task {
            await viewModel.deleteFeeding(event, childId: childId)
            dismiss()
        }
    }

    private func localizedFeedingType(_ type: String) -> String {
        print("🔍 FeedingDetailView - Original type from DB: '\(type)'")

        if type == "Грудное" || type == "Грудное вскармливание" {
            return String(localized: "feeding_type_breast_feeding")
        } else if type == "Бутылочка" || type == "Кормление из бутылочки" {
            return String(localized: "feeding_type_bottle_feeding")
        } else if type == "Прикорм" {
            return String(localized: "feeding_type_complementary_feeding")
        } else if type == "Breast" || type == "Breastfeeding" {
            return String(localized: "feeding_type_breast_feeding")
        } else if type == "Bottle" || type == "Bottle feeding" {
            return String(localized: "feeding_type_bottle_feeding")
        } else if type == "Solid" || type == "Complementary feeding" {
            return String(localized: "feeding_type_complementary_feeding")
        }

        print("⚠️ FeedingDetailView - No match found, returning original: '\(type)'")
        return type
    }

    private func localizedBreast(_ breast: String) -> String {
        print("🔍 Breast value from DB: '\(breast)'")
        let normalized = breast.trimmingCharacters(in: .whitespaces)

        if normalized == "Левая" || normalized == "Left" {
            let result = String(localized: "feeding_breast_left")
            print("✅ Matched Left -> '\(result)'")
            return result
        } else if normalized == "Правая" || normalized == "Right" {
            let result = String(localized: "feeding_breast_right")
            print("✅ Matched Right -> '\(result)'")
            return result
        } else if normalized == "Обе" || normalized == "Both" {
            let result = String(localized: "feeding_breast_both")
            print("✅ Matched Both -> '\(result)'")
            return result
        }

        print("⚠️ No match found for breast: '\(breast)'")
        return breast
    }
}

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}
