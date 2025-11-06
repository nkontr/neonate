import SwiftUI

struct SleepDetailView: View {

    let event: SleepEvent
    @ObservedObject var viewModel: SleepViewModel
    @ObservedObject var childViewModel: ChildProfileViewModel

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section("Информация") {
                if let startTime = event.startTime {
                    DetailRow(label: "Начало", value: formatDate(startTime))
                }
                if let endTime = event.endTime {
                    DetailRow(label: "Конец", value: formatDate(endTime))
                } else {
                    DetailRow(label: "Статус", value: "В процессе")
                }
                DetailRow(label: "Длительность", value: formatDuration(event.duration))
                if let quality = event.quality {
                    DetailRow(label: "Качество", value: quality)
                }
                if let location = event.location {
                    DetailRow(label: "Место", value: location)
                }
            }

            if let notes = event.notes, !notes.isEmpty {
                Section("Заметки") {
                    Text(notes)
                }
            }

            Section {
                Button(role: .destructive) {
                    deleteEvent()
                } label: {
                    Label("Удалить", systemImage: "trash")
                }
            }
        }
        .navigationTitle("Сон")
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
        return "\(hours)ч \(mins)м"
    }

    private func deleteEvent() {
        guard let childId = childViewModel.selectedChild?.id else { return }
        Task {
            await viewModel.deleteSleep(event, childId: childId)
            dismiss()
        }
    }
}
