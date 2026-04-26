import SwiftUI
import PhotosUI

struct EditChildView: View {

    @Environment(\.dismiss) private var dismiss

    @ObservedObject var viewModel: ChildProfileViewModel
    let child: ChildProfile

    @State private var name: String = ""
    @State private var dateOfBirth: Date = Date()
    @State private var gender: String = String(localized: "gender_boy")
    @State private var birthWeight: String = ""
    @State private var birthHeight: String = ""
    @State private var notes: String = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoData: Data?

    var genderOptions: [String] {
        [
            String(localized: "gender_boy"),
            String(localized: "gender_girl"),
            String(localized: "gender_other")
        ]
    }

    init(viewModel: ChildProfileViewModel, child: ChildProfile) {
        self.viewModel = viewModel
        self.child = child

        _name = State(initialValue: child.name ?? "")
        _dateOfBirth = State(initialValue: child.dateOfBirth ?? Date())
        _gender = State(initialValue: child.gender ?? String(localized: "gender_boy"))
        _birthWeight = State(initialValue: child.birthWeight > 0 ? String(Int(child.birthWeight)) : "")
        _birthHeight = State(initialValue: child.birthHeight > 0 ? String(Int(child.birthHeight)) : "")
        _notes = State(initialValue: child.notes ?? "")
        _photoData = State(initialValue: child.photoData)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(String(localized: "form_basic_info")) {
                    TextField(String(localized: "placeholder_child_name"), text: $name)

                    DatePicker(
                        String(localized: "profile_birth_date"),
                        selection: $dateOfBirth,
                        in: ...Date(),
                        displayedComponents: .date
                    )

                    Picker(String(localized: "profile_gender"), selection: $gender) {
                        ForEach(genderOptions, id: \.self) { option in
                            Text(option)
                        }
                    }
                }

                Section(String(localized: "form_photo")) {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        if let photoData = photoData, let uiImage = UIImage(data: photoData) {
                            HStack {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 60, height: 60)
                                    .clipShape(Circle())

                                Text(String(localized: "profile_change_photo"))
                            }
                        } else {
                            Label(String(localized: "profile_add_photo"), systemImage: "camera")
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

                Section(String(localized: "form_at_birth")) {
                    TextField(String(localized: "placeholder_weight_grams"), text: $birthWeight)
                        .keyboardType(.numberPad)

                    TextField(String(localized: "placeholder_height_cm"), text: $birthHeight)
                        .keyboardType(.decimalPad)
                }

                Section(String(localized: "form_notes")) {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
            }
            .navigationTitle(String(localized: "profile_edit"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "cancel")) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "save")) {
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
