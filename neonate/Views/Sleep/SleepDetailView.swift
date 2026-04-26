import SwiftUI

struct SleepDetailView: View {

    let event: SleepEvent
    @ObservedObject var viewModel: SleepViewModel
    @ObservedObject var childViewModel: ChildProfileViewModel

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section(String(localized: "information")) {
                if let startTime = event.startTime {
                    DetailRow(label: String(localized: "start_label"), value: formatDate(startTime))
                }
                if let endTime = event.endTime {
                    DetailRow(label: String(localized: "end_label"), value: formatDate(endTime))
                } else {
                    DetailRow(label: String(localized: "status_label"), value: String(localized: "in_progress"))
                }
                DetailRow(label: String(localized: "duration_label"), value: formatDuration(event.duration))
                if let quality = event.quality {
                    DetailRow(label: String(localized: "quality_label"), value: localizedQuality(quality))
                }
                if let location = event.location {
                    DetailRow(label: String(localized: "location_label"), value: location)
                }
            }

            if let notes = event.notes, !notes.isEmpty {
                Section(String(localized: "form_notes")) {
                    Text(notes)
                }
            }

            Section {
                Button(role: .destructive) {
                    deleteEvent()
                } label: {
                    Label(String(localized: "delete"), systemImage: "trash")
                }
            }
        }
        .navigationTitle(String(localized: "sleep_title"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func formatDuration(_ minutes: Int32) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        return String(localized: "duration_short_format").replacingOccurrences(of: "%d", with: "\(hours)").replacingOccurrences(of: "%d", with: "\(mins)")
    }

    private func deleteEvent() {
        guard let childId = childViewModel.selectedChild?.id else { return }
        Task {
            await viewModel.deleteSleep(event, childId: childId)
            dismiss()
        }
    }

    private func localizedQuality(_ quality: String) -> String {
        let normalized = quality.trimmingCharacters(in: .whitespaces)

        // Russian and English variants
        if normalized == "Отличный" || normalized == "Excellent" {
            return String(localized: "sleep_quality_excellent")
        } else if normalized == "Хороший" || normalized == "Good" {
            return String(localized: "sleep_quality_good")
        } else if normalized == "Средний" || normalized == "Average" {
            return String(localized: "sleep_quality_average")
        } else if normalized == "Плохой" || normalized == "Poor" {
            return String(localized: "sleep_quality_poor")
        }

        return quality
    }
}
