import SwiftUI

struct AddSleepView: View {

    @Environment(\.dismiss) private var dismiss

    @ObservedObject var viewModel: SleepViewModel
    @ObservedObject var childViewModel: ChildProfileViewModel

    @State private var startTime: Date = Date().addingTimeInterval(-3600)
    @State private var endTime: Date = Date()
    @State private var quality: String = "Хорошее"
    @State private var location: String = "Кроватка"
    @State private var notes: String = ""

    let qualityOptions = ["Отличное", "Хорошее", "Нормальное", "Беспокойное"]
    let locationOptions = ["Кроватка", "Коляска", "На руках", "В машине"]

    var body: some View {
        NavigationView {
            Form {
                Section("Время") {
                    DatePicker("Начало", selection: $startTime)
                    DatePicker("Конец", selection: $endTime)

                    HStack {
                        Text("Длительность")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(calculateDuration())
                            .fontWeight(.medium)
                    }
                }

                Section("Качество") {
                    Picker("Качество сна", selection: $quality) {
                        ForEach(qualityOptions, id: \.self) { option in
                            Text(option)
                        }
                    }
                }

                Section("Место") {
                    Picker("Место сна", selection: $location) {
                        ForEach(locationOptions, id: \.self) { option in
                            Text(option)
                        }
                    }
                }

                Section("Заметки") {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }

                Section {
                    SiriShortcutButton(
                        shortcutType: .sleep,
                        title: "Скажите Siri для быстрого добавления сна"
                    )
                }
            }
            .navigationTitle("Добавить сон")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") { saveSleep() }
                        .disabled(endTime <= startTime)
                }
            }
        }
    }

    private func calculateDuration() -> String {
        let duration = endTime.timeIntervalSince(startTime)
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        return "\(hours)ч \(minutes)м"
    }

    private func saveSleep() {
        guard let childId = childViewModel.selectedChild?.id else { return }
        Task {
            await viewModel.addSleep(
                childId: childId,
                startTime: startTime,
                endTime: endTime,
                quality: quality,
                location: location,
                notes: notes.isEmpty ? nil : notes
            )
            dismiss()
        }
    }
}
