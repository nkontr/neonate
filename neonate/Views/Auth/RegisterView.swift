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

                VStack(spacing: 16) {
                    Spacer(minLength: 0)

                    headerView

                    registrationFormView

                    termsAgreementView

                    registerButton

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 8)
            }
            .scrollDisabled(true)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                    }
                }
            }
            .alert(String(localized: "error"), isPresented: $authViewModel.showError) {
                Button(String(localized: "ok")) {
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
        VStack(spacing: 8) {
            Image(systemName: "person.badge.plus.fill")
                .font(.system(size: 44))
                .foregroundColor(.white)

            Text(String(localized: "register_title"))
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text(String(localized: "register_subtitle"))
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
    }

    private var registrationFormView: some View {
        VStack(spacing: 12) {

            VStack(alignment: .leading, spacing: 4) {
                CustomTextField(
                    icon: "person.fill",
                    placeholder: String(localized: "register_username_placeholder"),
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
                    placeholder: String(localized: "register_email_placeholder"),
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
                placeholder: String(localized: "register_fullname_placeholder"),
                text: $fullName,
                isSecure: false
            )

            VStack(alignment: .leading, spacing: 4) {
                CustomTextField(
                    icon: "lock.fill",
                    placeholder: String(localized: "register_password_placeholder"),
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
                    placeholder: String(localized: "register_confirm_password_placeholder"),
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

            Text(String(localized: "register_terms_agreement"))
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
                Text(String(localized: "register_button"))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
        }
        .background(
            Group {
                if isFormValid && !authViewModel.isLoading {
                    ZStack {
                        LinearGradient(
                            colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )

                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.2), Color.clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .blur(radius: 10)
                    }
                } else {
                    Color.white.opacity(0.3)
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
        .shadow(
            color: isFormValid && !authViewModel.isLoading ? Color.blue.opacity(0.3) : Color.clear,
            radius: 8,
            x: 0,
            y: 4
        )
        .disabled(!isFormValid || authViewModel.isLoading)
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
            return String(localized: "register_error_username_required")
        }

        if !containsOnlyLetters(username) {
            return String(localized: "register_error_username_letters_only")
        }

        if username.count < 3 {
            return String(localized: "register_error_username_min_length")
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
            return String(localized: "register_error_email_required")
        }
        if !isEmailValid {
            return String(localized: "register_error_email_invalid")
        }
        return nil
    }

    private var isPasswordValid: Bool {
        password.count >= 6
    }

    private var passwordError: String? {
        guard passwordTouched else { return nil }
        if password.isEmpty {
            return String(localized: "register_error_password_required")
        }
        if password.count < 6 {
            return String(localized: "register_error_password_min_length")
        }
        return nil
    }

    private var doPasswordsMatch: Bool {
        !confirmPassword.isEmpty && password == confirmPassword
    }

    private var confirmPasswordError: String? {
        guard confirmPasswordTouched else { return nil }
        if confirmPassword.isEmpty {
            return String(localized: "register_error_confirm_password_required")
        }
        if password != confirmPassword {
            return String(localized: "register_error_passwords_mismatch")
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
