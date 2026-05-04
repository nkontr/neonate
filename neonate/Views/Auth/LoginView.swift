import SwiftUI
import AuthenticationServices

struct LoginView: View {

    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showPassword: Bool = false
    @State private var showRegisterView: Bool = false
    @StateObject private var appleSignInCoordinator = AppleSignInCoordinator()

    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LiquidGlassGradients.primaryAuth
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    Spacer(minLength: 0)

                    headerView

                    loginFormView

                    appleSignInButton

                    bottomActionsView

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 8)
            }
            .scrollDisabled(true)
            .navigationBarHidden(true)
            .sheet(isPresented: $showRegisterView) {
                RegisterView()
                    .environmentObject(authViewModel)
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
        }
    }

    private var headerView: some View {
        VStack(spacing: 8) {
            Image(systemName: "heart.circle.fill")
                .font(.system(size: 70))
                .foregroundColor(.white)
                .accessibilityHidden(true)

            Text("neonate")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text(String(localized: "app_name"))
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("neonate. \(String(localized: "app_name"))")
        .accessibilityAddTraits(.isHeader)
    }

    private var loginFormView: some View {
        VStack(spacing: 14) {

            VStack(alignment: .leading, spacing: 8) {
                Text(String(localized: "auth_email"))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.9))

                HStack {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(.white.opacity(0.8))
                        .accessibilityHidden(true)
                    TextField(String(localized: "auth_email_placeholder"), text: $email)
                        .textFieldStyle(PlainTextFieldStyle())
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .foregroundColor(.white)
                        .accessibilityLabel(String(localized: "auth_email"))
                        .accessibilityValue(email.isEmpty ? String(localized: "a11y_empty_field") : email)
                }
                .glassTextField(cornerRadius: 16)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(String(localized: "auth_password"))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.9))

                HStack {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.white.opacity(0.8))
                        .accessibilityHidden(true)

                    if showPassword {
                        TextField(String(localized: "auth_password_placeholder"), text: $password)
                            .textFieldStyle(PlainTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .foregroundColor(.white)
                            .accessibilityLabel(String(localized: "auth_password"))
                            .accessibilityValue(password.isEmpty ? String(localized: "a11y_empty_field") : String(localized: "a11y_toggle_on"))
                    } else {
                        SecureField(String(localized: "auth_password_placeholder"), text: $password)
                            .textFieldStyle(PlainTextFieldStyle())
                            .foregroundColor(.white)
                            .accessibilityLabel(String(localized: "auth_password"))
                            .accessibilityValue(password.isEmpty ? String(localized: "a11y_empty_field") : String(localized: "a11y_toggle_on"))
                    }

                    Button(action: { showPassword.toggle() }) {
                        Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .accessibilityLabel(showPassword ? String(localized: "a11y_hide_password") : String(localized: "a11y_show_password"))
                }
                .glassTextField(cornerRadius: 16)
            }

            Button(action: handleLogin) {
                if authViewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(maxWidth: .infinity)
                        .accessibilityLabel(String(localized: "loading"))
                } else {
                    Text(String(localized: "auth_login_button"))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
            }
            .background(
                Group {
                    if !email.isEmpty && !password.isEmpty && !authViewModel.isLoading {
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
                color: (!email.isEmpty && !password.isEmpty && !authViewModel.isLoading) ? Color.blue.opacity(0.3) : Color.clear,
                radius: 8,
                x: 0,
                y: 4
            )
            .disabled(authViewModel.isLoading || email.isEmpty || password.isEmpty)
            .buttonAccessibility(
                label: String(localized: "auth_login_button"),
                hint: nil,
                isEnabled: !authViewModel.isLoading && !email.isEmpty && !password.isEmpty
            )
        }
        .padding(.horizontal, 4)
    }

    private var appleSignInButton: some View {
        VStack(spacing: 12) {
            HStack {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.4), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)
                    .accessibilityHidden(true)
                Text(String(localized: "auth_or"))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.9))
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.4), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)
                    .accessibilityHidden(true)
            }

            Button(action: handleAppleSignInTap) {
                HStack(spacing: 12) {
                    Image(systemName: "apple.logo")
                        .font(.title2)
                        .accessibilityHidden(true)

                    Text(String(localized: "apple_signin_button"))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    ZStack {
                        LinearGradient(
                            colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )

                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.2), Color.clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .blur(radius: 10)
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .disabled(authViewModel.isLoading)
            .opacity(authViewModel.isLoading ? 0.6 : 1.0)
        }
    }

    private var bottomActionsView: some View {
        VStack(spacing: 12) {
            Button(action: { showRegisterView = true }) {
                HStack {
                    Text(String(localized: "auth_no_account"))
                        .foregroundColor(.white.opacity(0.8))
                    Text(String(localized: "auth_register_button"))
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                .font(.subheadline)
            }
            .buttonAccessibility(
                label: "\(String(localized: "auth_no_account")) \(String(localized: "auth_register_button"))",
                hint: nil
            )
        }
    }

    private func handleLogin() {
        Task {
            let credentials = AuthCredentials(username: email, password: password)
            await authViewModel.login(credentials: credentials)
        }
    }

    private func handleAppleSignInTap() {
        print("🍎 Starting Apple Sign In...")

        appleSignInCoordinator.onCompletion = { result in
            handleAppleSignIn(result)
        }

        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]

        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = appleSignInCoordinator
        authorizationController.presentationContextProvider = appleSignInCoordinator
        authorizationController.performRequests()
    }

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        print("🍎 Apple Sign In result received")
        switch result {
        case .success(let authorization):
            print("✅ Apple Sign In successful")
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                print("✅ Got Apple ID credential, logging in...")
                Task {
                    await authViewModel.loginWithApple(credential: appleIDCredential)
                }
            }
        case .failure(let error):
            print("❌ Apple Sign In failed: \(error.localizedDescription)")
            Task { @MainActor in
                authViewModel.errorMessage = "Ошибка входа через Apple: \(error.localizedDescription)"
                authViewModel.showError = true
            }
        }
    }
}

class AppleSignInCoordinator: NSObject, ObservableObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    var onCompletion: ((Result<ASAuthorization, Error>) -> Void)?

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        print("🍎 Coordinator: Authorization completed successfully")
        onCompletion?(.success(authorization))
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("🍎 Coordinator: Authorization failed with error: \(error.localizedDescription)")

        // Игнорируем ошибку отмены пользователем
        if let authError = error as? ASAuthorizationError {
            if authError.code == .canceled {
                print("🍎 User canceled Apple Sign In")
                return
            }
        }

        onCompletion?(.failure(error))
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            print("⚠️ Warning: Could not find window for presentation anchor")
            return UIWindow()
        }
        return window
    }
}

#if Preview
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LoginView()
                .environmentObject(AuthViewModel.previewUnauthenticated)
                .previewDisplayName("Default")

            LoginView()
                .environmentObject(AuthViewModel.previewLoading)
                .previewDisplayName("Loading")

            LoginView()
                .environmentObject(AuthViewModel.previewWithError)
                .previewDisplayName("With Error")
        }
    }
}
#endif
