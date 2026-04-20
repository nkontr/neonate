import SwiftUI

struct AddFeedingView: View {

    @Environment(\.dismiss) private var dismiss

    @ObservedObject var viewModel: FeedingViewModel
    @ObservedObject var childViewModel: ChildProfileViewModel

    @State private var feedingType: String = "Грудное"
    @State private var timestamp: Date = Date()
    @State private var duration: String = ""
    @State private var volume: String = ""
    @State private var breast: String = "Левая"
    @State private var notes: String = ""

    let feedingTypes = ["Грудное", "Бутылочка", "Прикорм"]
    let breastOptions = ["Левая", "Правая", "Обе"]

    var body: some View {
        NavigationView {
            Form {
                Section("Тип кормления") {
                    Picker("Тип", selection: $feedingType) {
                        ForEach(feedingTypes, id: \.self) { type in
                            Text(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Время") {
                    DatePicker("Время кормления", selection: $timestamp)
                }

                if feedingType == "Грудное" {
                    Section("Грудь") {
                        Picker("Грудь", selection: $breast) {
                            ForEach(breastOptions, id: \.self) { option in
                                Text(option)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    Section("Длительность") {
                        TextField("Минуты", text: $duration)
                            .keyboardType(.numberPad)
                    }
                } else {
                    Section("Объем") {
                        TextField("Миллилитры", text: $volume)
                            .keyboardType(.numberPad)
                    }
                }

                Section("Заметки") {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }

                Section {
                    SiriShortcutButton(
                        shortcutType: .feeding,
                        title: "Скажите Siri для быстрого добавления кормления"
                    )
                }
            }
            .navigationTitle("Новое кормление")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") { saveFeeding() }
                }
            }
        }
    }

    private func saveFeeding() {
        guard let childId = childViewModel.selectedChild?.id else { return }

        Task {
            await viewModel.addFeeding(
                childId: childId,
                timestamp: timestamp,
                feedingType: feedingType,
                duration: Int32(duration) ?? 0,
                volume: Double(volume) ?? 0,
                breast: feedingType == "Грудное" ? breast : nil,
                notes: notes.isEmpty ? nil : notes
            )
            dismiss()
        }
    }
}
