import SwiftUI
import PhotosUI

struct EditProfileView: View {

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var fullName: String = ""
    @State private var isLoading: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var profileImage: UIImage?
    @State private var showingCameraPicker = false
    @State private var showingGalleryPicker = false

    var body: some View {
        NavigationView {
            Form {
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
                    Text(String(localized: "edit_profile_photo_section"))
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
                            removeProfileImage()
                        } label: {
                            Label(String(localized: "edit_profile_remove_photo"), systemImage: "trash")
                        }
                    }
                }

                // Name Section
                Section {
                    TextField(String(localized: "edit_profile_name_placeholder"), text: $fullName)
                        .textContentType(.name)
                        .autocapitalization(.words)
                        .disabled(isLoading)
                } header: {
                    Text(String(localized: "edit_profile_name_section"))
                } footer: {
                    Text(String(localized: "edit_profile_name_hint"))
                }

                // Email Section
                Section {
                    HStack {
                        if isApplePrivateEmail {
                            Image(systemName: "lock.shield.fill")
                                .foregroundColor(.blue)
                        }
                        Text(displayEmail)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text(String(localized: "edit_profile_email_section"))
                } footer: {
                    Text(isApplePrivateEmail
                        ? String(localized: "edit_profile_email_private")
                        : String(localized: "edit_profile_email_locked"))
                }
            }
            .navigationTitle(String(localized: "edit_profile_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "cancel")) {
                        dismiss()
                    }
                    .disabled(isLoading)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "save")) {
                        saveProfile()
                    }
                    .disabled(isLoading || fullName.isEmpty)
                }
            }
            .alert(String(localized: "error"), isPresented: $showError) {
                Button(String(localized: "ok")) {
                    showError = false
                }
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showingCameraPicker) {
                ImagePicker(image: $profileImage, sourceType: .camera)
            }
            .sheet(isPresented: $showingGalleryPicker) {
                ImagePicker(image: $profileImage, sourceType: .photoLibrary)
            }
            .onAppear {
                loadCurrentUserData()
            }
        }
    }

    private var displayEmail: String {
        authViewModel.currentUser?.displayEmail ?? ""
    }

    private var isApplePrivateEmail: Bool {
        authViewModel.currentUser?.email.contains("@privaterelay.appleid.com") ?? false
    }


    private func loadCurrentUserData() {
        if let user = authViewModel.currentUser {
            fullName = user.fullName ?? ""
            loadProfileImage()
        }
    }

    private func loadProfileImage() {
        Task {
            if let imageData = try? await KeychainService.shared.loadProfileImage(),
               let image = UIImage(data: imageData) {
                await MainActor.run {
                    profileImage = image
                }
            }
        }
    }

    private func removeProfileImage() {
        withAnimation(.easeInOut(duration: 0.3)) {
            profileImage = nil
        }
        Task {
            try? await KeychainService.shared.deleteProfileImage()
        }
    }

    private func saveProfile() {
        guard let currentUser = authViewModel.currentUser else {
            errorMessage = String(localized: "edit_profile_error_no_user")
            showError = true
            return
        }

        isLoading = true

        let updatedUser = User(
            id: currentUser.id,
            username: currentUser.username,
            email: currentUser.email,
            fullName: fullName.isEmpty ? nil : fullName,
            registeredAt: currentUser.registeredAt,
            lastLoginAt: currentUser.lastLoginAt
        )

        Task {
            // Update profile WITHOUT showing success message AND without changing isLoading in ViewModel
            await authViewModel.updateUserProfile(updatedUser, showSuccessMessage: false, updateLoadingState: false)

            // Save or delete profile photo
            if let profileImage = profileImage,
               let imageData = profileImage.jpegData(compressionQuality: 0.8) {
                try? await KeychainService.shared.saveProfileImage(imageData)
            } else {
                // Удаляем фото из Keychain если оно было удалено
                try? await KeychainService.shared.deleteProfileImage()
            }

            await MainActor.run {
                isLoading = false

                if authViewModel.showError {
                    errorMessage = authViewModel.errorMessage ?? String(localized: "edit_profile_error_save")
                    showError = true
                } else {
                    // Close the edit screen
                    dismiss()
                }
            }
        }
    }
}

#if Preview
struct EditProfileView_Previews: PreviewProvider {
    static var previews: some View {
        EditProfileView()
            .environmentObject(AuthViewModel.preview)
    }
}
#endif
