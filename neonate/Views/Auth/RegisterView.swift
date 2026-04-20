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

    @State private var usernameTouched: Bool = false
    @State private var emailTouched: Bool = false
    @State private var passwordTouched: Bool = false
    @State private var confirmPasswordTouched: Bool = false

    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.glassPurple.opacity(0.8),
                        Color.glassBlue.opacity(0.6)
                    ]),
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
            .onChange(of: authViewModel.isAuthenticated) { _, isAuth in
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

            VStack(alignment: .leading, spacing: 4) {
                CustomTextField(
                    icon: "person.fill",
                    placeholder: "Имя пользователя (только буквы)",
                    text: $username,
                    isSecure: false
                )
                .onChange(of: username) { _, _ in
                    Task { @MainActor in
                        if !usernameTouched {
                            usernameTouched = true
                        }
                    }
                }

                if let error = usernameError {
                    ValidationErrorText(message: error)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                CustomTextField(
                    icon: "envelope.fill",
                    placeholder: "Email",
                    text: $email,
                    isSecure: false,
                    keyboardType: .emailAddress
                )
                .onChange(of: email) { _, _ in
                    Task { @MainActor in
                        if !emailTouched {
                            emailTouched = true
                        }
                    }
                }

                if let error = emailError {
                    ValidationErrorText(message: error)
                }
            }

            CustomTextField(
                icon: "person.text.rectangle.fill",
                placeholder: "Полное имя (необязательно)",
                text: $fullName,
                isSecure: false
            )

            VStack(alignment: .leading, spacing: 4) {
                CustomTextField(
                    icon: "lock.fill",
                    placeholder: "Пароль (минимум 6 символов)",
                    text: $password,
                    isSecure: !showPassword,
                    showToggle: true,
                    toggleAction: { showPassword.toggle() }
                )
                .onChange(of: password) { _, _ in
                    Task { @MainActor in
                        if !passwordTouched {
                            passwordTouched = true
                        }
                    }
                }

                if let error = passwordError {
                    ValidationErrorText(message: error)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                CustomTextField(
                    icon: "lock.fill",
                    placeholder: "Подтвердите пароль",
                    text: $confirmPassword,
                    isSecure: !showConfirmPassword,
                    showToggle: true,
                    toggleAction: { showConfirmPassword.toggle() }
                )
                .onChange(of: confirmPassword) { _, _ in
                    Task { @MainActor in
                        if !confirmPasswordTouched {
                            confirmPasswordTouched = true
                        }
                    }
                }

                if let error = confirmPasswordError {
                    ValidationErrorText(message: error)
                }
            }
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
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .frame(maxWidth: .infinity)
            } else {
                Text("Зарегистрироваться")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
            }
        }
        .liquidGlassButton(color: .white, isPressed: false)
        .disabled(!isFormValid || authViewModel.isLoading)
        .opacity((!isFormValid || authViewModel.isLoading) ? 0.6 : 1.0)
    }

    private func containsOnlyLetters(_ string: String) -> Bool {
        let allowedCharacters = CharacterSet.letters
        return string.unicodeScalars.allSatisfy { allowedCharacters.contains($0) }
    }

    private var isUsernameValid: Bool {
        return username.count >= 3 && containsOnlyLetters(username)
    }

    private var usernameError: String? {
        guard usernameTouched else { return nil }
        if username.isEmpty {
            return "Имя пользователя обязательно"
        }

        if !containsOnlyLetters(username) {
            return "Только буквы (без цифр и символов)"
        }

        if username.count < 3 {
            return "Минимум 3 символа"
        }
        return nil
    }

    private func isValidEmailDomain(_ email: String) -> Bool {
        // Список популярных и реальных TLD
        let validTLDs = [
            // Международные
            "com", "net", "org", "edu", "gov", "mil", "int", "info", "biz",
            // Новые популярные
            "io", "dev", "app", "tech", "online", "site", "store", "blog", "cloud",
            // Страновые коды
            "ru", "ua", "by", "kz", "us", "uk", "de", "fr", "it", "es", "cn", "jp", "kr",
            "ca", "au", "br", "in", "mx", "nl", "se", "no", "fi", "dk", "pl", "cz",
            // Кириллица
            "рф"
        ]

        guard let domain = email.split(separator: "@").last?.lowercased(),
              email.contains("@") else {
            return false
        }

        // Проверяем TLD
        for tld in validTLDs {
            if domain.hasSuffix(".\(tld)") {
                return true
            }
        }

        return false
    }

    private var isEmailValid: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        let basicFormat = emailPredicate.evaluate(with: email)

        return basicFormat && isValidEmailDomain(email)
    }

    private var emailError: String? {
        guard emailTouched else { return nil }
        if email.isEmpty {
            return "Email обязателен"
        }
        if !isEmailValid {
            return "Неверный формат email"
        }
        return nil
    }

    private var isPasswordValid: Bool {
        password.count >= 6
    }

    private var passwordError: String? {
        guard passwordTouched else { return nil }
        if password.isEmpty {
            return "Пароль обязателен"
        }
        if password.count < 6 {
            return "Минимум 6 символов"
        }
        return nil
    }

    private var doPasswordsMatch: Bool {
        !confirmPassword.isEmpty && password == confirmPassword
    }

    private var confirmPasswordError: String? {
        guard confirmPasswordTouched else { return nil }
        if confirmPassword.isEmpty {
            return "Подтвердите пароль"
        }
        if password != confirmPassword {
            return "Пароли не совпадают"
        }
        return nil
    }

    private var isFormValid: Bool {
        isUsernameValid &&
        isEmailValid &&
        isPasswordValid &&
        doPasswordsMatch &&
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

private struct ValidationErrorText: View {
    let message: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.caption)
            Text(message)
                .font(.caption)
        }
        .foregroundColor(.red.opacity(0.95))
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.2))
        )
        .padding(.leading, 4)
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
                .foregroundColor(.white.opacity(0.8))
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
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .glassTextField(cornerRadius: 16)
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
