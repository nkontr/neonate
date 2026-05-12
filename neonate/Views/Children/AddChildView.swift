import SwiftUI

struct AddChildView: View {

    @Environment(\.dismiss) private var dismiss

    @ObservedObject var viewModel: ChildProfileViewModel

    @State private var name: String = ""
    @State private var dateOfBirth: Date = Date()
    @State private var gender: String = String(localized: "gender_boy")
    @State private var birthWeight: String = ""
    @State private var birthHeight: String = ""
    @State private var notes: String = ""
    @State private var profileImage: UIImage?
    @State private var showingCameraPicker = false
    @State private var showingGalleryPicker = false

    var genderOptions: [String] {
        [
            String(localized: "gender_boy"),
            String(localized: "gender_girl"),
            String(localized: "gender_other")
        ]
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

                // Profile Photo Display
                Section {
                    HStack {
                        Spacer()

                        if let profileImage = profileImage {
                            Image(uiImage: profileImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                                )
                        } else {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 100))
                                .foregroundColor(.blue)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text(String(localized: "form_photo"))
                }

                // Photo Actions
                Section {
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        Button {
                            showingCameraPicker = true
                        } label: {
                            Label(String(localized: "edit_profile_camera_button"), systemImage: "camera")
                        }
                    }

                    Button {
                        showingGalleryPicker = true
                    } label: {
                        Label(String(localized: "edit_profile_gallery_button"), systemImage: "photo")
                    }

                    if profileImage != nil {
                        Button(role: .destructive) {
                            profileImage = nil
                        } label: {
                            Label(String(localized: "edit_profile_remove_photo"), systemImage: "trash")
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
            .navigationTitle(String(localized: "profile_new"))
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingCameraPicker) {
                ImagePicker(image: $profileImage, sourceType: .camera)
            }
            .sheet(isPresented: $showingGalleryPicker) {
                ImagePicker(image: $profileImage, sourceType: .photoLibrary)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "cancel")) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "save")) {
                        saveChild()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }

    private func saveChild() {
        Task {
            // Convert UIImage to Data if present
            let photoData = profileImage?.jpegData(compressionQuality: 0.8)

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
