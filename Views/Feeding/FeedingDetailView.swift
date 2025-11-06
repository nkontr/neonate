import SwiftUI

struct FeedingDetailView: View {

    let event: FeedingEvent
    @ObservedObject var viewModel: FeedingViewModel
    @ObservedObject var childViewModel: ChildProfileViewModel

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section("Информация") {
                DetailRow(label: "Тип", value: event.feedingType ?? "")
                if let timestamp = event.timestamp {
                    DetailRow(label: "Время", value: formatDate(timestamp))
                }
                if let breast = event.breast {
                    DetailRow(label: "Грудь", value: breast)
                }
                if event.duration > 0 {
                    DetailRow(label: "Длительность", value: "\(event.duration) мин")
                }
                if event.volume > 0 {
                    DetailRow(label: "Объем", value: "\(Int(event.volume)) мл")
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
        .navigationTitle("Кормление")
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
