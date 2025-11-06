import SwiftUI

struct RegisterView: View {

    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss

    @State private var username: String = ""
    @State private var email: String = ""
    @State private var fullName: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var showPassword: Bool = false
    @State private var showConfirmPassword: Bool = false
    @State private var agreedToTerms: Bool = false

    var body: some View {
        NavigationView {
            ZStack {

                LinearGradient(
                    gradient: Gradient(colors: [Color.purple.opacity(0.6), Color.blue.opacity(0.4)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 25) {
                        Spacer()
                            .frame(height: 40)

                        headerView

                        registrationFormView

                        termsAgreementView

                        registerButton

                        Spacer()
                            .frame(height: 30)
                    }
                    .padding(.horizontal, 30)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                    }
                }
            }
            .alert("Ошибка", isPresented: $authViewModel.showError) {
                Button("OK") {
                    authViewModel.clearError()
                }
            } message: {
                if let errorMessage = authViewModel.errorMessage {
                    Text(errorMessage)
                }
            }
            .onChange(of: authViewModel.isAuthenticated) { isAuth in
                if isAuth {
                    dismiss()
                }
            }
        }
    }

    private var headerView: some View {
        VStack(spacing: 10) {
            Image(systemName: "person.badge.plus.fill")
                .font(.system(size: 60))
                .foregroundColor(.white)

            Text("Создать аккаунт")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text("Присоединяйтесь к neonate")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
        }
    }

    private var registrationFormView: some View {
        VStack(spacing: 16) {

            CustomTextField(
                icon: "person.fill",
                placeholder: "Имя пользователя",
                text: $username,
                isSecure: false
            )

            CustomTextField(
                icon: "envelope.fill",
                placeholder: "Email",
                text: $email,
                isSecure: false,
                keyboardType: .emailAddress
            )

            CustomTextField(
                icon: "person.text.rectangle.fill",
                placeholder: "Полное имя (необязательно)",
                text: $fullName,
                isSecure: false
            )

            CustomTextField(
                icon: "lock.fill",
                placeholder: "Пароль (минимум 6 символов)",
                text: $password,
                isSecure: !showPassword,
                showToggle: true,
                toggleAction: { showPassword.toggle() }
            )

            CustomTextField(
                icon: "lock.fill",
                placeholder: "Подтвердите пароль",
                text: $confirmPassword,
                isSecure: !showConfirmPassword,
                showToggle: true,
                toggleAction: { showConfirmPassword.toggle() }
            )
        }
    }

    private var termsAgreementView: some View {
        HStack(alignment: .top, spacing: 10) {
            Button(action: { agreedToTerms.toggle() }) {
                Image(systemName: agreedToTerms ? "checkmark.square.fill" : "square")
                    .foregroundColor(.white)
                    .font(.title3)
            }

            Text("Я соглашаюсь с условиями использования и политикой конфиденциальности")
                .font(.caption)
                .foregroundColor(.white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var registerButton: some View {
        Button(action: handleRegister) {
            if authViewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .purple))
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                Text("Зарегистрироваться")
                    .font(.headline)
                    .foregroundColor(.purple)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
        .background(Color.white)
        .cornerRadius(10)
        .disabled(!isFormValid || authViewModel.isLoading)
        .opacity((!isFormValid || authViewModel.isLoading) ? 0.6 : 1.0)
    }

    private var isFormValid: Bool {
        !username.isEmpty &&
        !email.isEmpty &&
        !password.isEmpty &&
        !confirmPassword.isEmpty &&
        password.count >= 6 &&
        agreedToTerms
    }

    private func handleRegister() {
        let credentials = RegistrationCredentials(
            username: username,
            email: email,
            password: password,
            confirmPassword: confirmPassword,
            fullName: fullName.isEmpty ? nil : fullName
        )

        Task {
            await authViewModel.register(credentials: credentials)
        }
    }
}

private struct CustomTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var showToggle: Bool = false
    var toggleAction: (() -> Void)?

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 20)

            if isSecure {
                SecureField(placeholder, text: $text)
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(.white)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            } else {
                TextField(placeholder, text: $text)
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(.white)
                    .autocapitalization(keyboardType == .emailAddress ? .none : .words)
                    .disableAutocorrection(true)
                    .keyboardType(keyboardType)
            }

            if showToggle, let action = toggleAction {
                Button(action: action) {
                    Image(systemName: isSecure ? "eye.fill" : "eye.slash.fill")
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.2))
        .cornerRadius(10)
    }
}

#if Preview
struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterView()
            .environmentObject(AuthViewModel.previewUnauthenticated)
    }
}
#endif
