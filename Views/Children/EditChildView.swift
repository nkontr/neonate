import SwiftUI
import PhotosUI

struct EditChildView: View {

    @Environment(\.dismiss) private var dismiss

    @ObservedObject var viewModel: ChildProfileViewModel
    let child: ChildProfile

    @State private var name: String = ""
    @State private var dateOfBirth: Date = Date()
    @State private var gender: String = "Мальчик"
    @State private var birthWeight: String = ""
    @State private var birthHeight: String = ""
    @State private var notes: String = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoData: Data?

    let genderOptions = ["Мальчик", "Девочка", "Другое"]

    init(viewModel: ChildProfileViewModel, child: ChildProfile) {
        self.viewModel = viewModel
        self.child = child

        _name = State(initialValue: child.name ?? "")
        _dateOfBirth = State(initialValue: child.dateOfBirth ?? Date())
        _gender = State(initialValue: child.gender ?? "Мальчик")
        _birthWeight = State(initialValue: child.birthWeight > 0 ? String(Int(child.birthWeight)) : "")
        _birthHeight = State(initialValue: child.birthHeight > 0 ? String(Int(child.birthHeight)) : "")
        _notes = State(initialValue: child.notes ?? "")
        _photoData = State(initialValue: child.photoData)
    }

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
            .navigationTitle("Редактировать")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        saveChanges()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }

    private func saveChanges() {
        Task {
            await viewModel.updateChild(
                child,
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
