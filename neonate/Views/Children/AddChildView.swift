import SwiftUI
import PhotosUI

struct AddChildView: View {

    @Environment(\.dismiss) private var dismiss

    @ObservedObject var viewModel: ChildProfileViewModel

    @State private var name: String = ""
    @State private var dateOfBirth: Date = Date()
    @State private var gender: String = "Мальчик"
    @State private var birthWeight: String = ""
    @State private var birthHeight: String = ""
    @State private var notes: String = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoData: Data?

    let genderOptions = ["Мальчик", "Девочка", "Другое"]

    var body: some View {
        NavigationView {
            Form {
                Section("Основная информация") {
                    TextField("Имя ребенка", text: $name)

                    DatePicker(
                        "Дата рождения",
                        selection: $dateOfBirth,
                        in: ...Date(),
                        displayedComponents: .date
                    )

                    Picker("Пол", selection: $gender) {
                        ForEach(genderOptions, id: \.self) { option in
                            Text(option)
                        }
                    }
                }

                Section("Фото") {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        if let photoData = photoData, let uiImage = UIImage(data: photoData) {
                            HStack {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 60, height: 60)
                                    .clipShape(Circle())

                                Text("Изменить фото")
                            }
                        } else {
                            Label("Добавить фото", systemImage: "camera")
                        }
                    }
                    .onChange(of: selectedPhoto) { _, newValue in
                        Task {
                            if let data = try? await newValue?.loadTransferable(type: Data.self) {
                                photoData = data
                            }
                        }
                    }
                }

                Section("При рождении") {
                    TextField("Вес (граммы)", text: $birthWeight)
                        .keyboardType(.numberPad)

                    TextField("Рост (см)", text: $birthHeight)
                        .keyboardType(.decimalPad)
                }

                Section("Заметки") {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
            }
            .navigationTitle("Новый профиль")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        saveChild()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }

    private func saveChild() {
        Task {
            await viewModel.addChild(
                name: name,
                dateOfBirth: dateOfBirth,
                gender: gender,
                photoData: photoData,
                birthWeight: Double(birthWeight),
                birthHeight: Double(birthHeight),
                notes: notes.isEmpty ? nil : notes
            )
            dismiss()
        }
    }
}
