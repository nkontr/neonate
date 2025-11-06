import SwiftUI

struct LoginView: View {

    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var username: String = ""
    @State private var password: String = ""
    @State private var showPassword: Bool = false
    @State private var showRegisterView: Bool = false

    var body: some View {
        NavigationView {
            ZStack {

                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.4)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 30) {
                        Spacer()
                            .frame(height: 60)

                        headerView

                        loginFormView

                        if authViewModel.isBiometricAvailable {
                            biometricButton
                        }

                        bottomActionsView

                        Spacer()
                            .frame(height: 40)
                    }
                    .padding(.horizontal, 30)
                }
            }
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
        VStack(spacing: 10) {
            Image(systemName: "heart.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.white)
                .accessibilityHidden(true)

            Text("neonate")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text(String(localized: "app_name"))
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("neonate. \(String(localized: "app_name"))")
        .accessibilityAddTraits(.isHeader)
    }

    private var loginFormView: some View {
        VStack(spacing: 20) {

            VStack(alignment: .leading, spacing: 8) {
                Text(String(localized: "auth_username"))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))

                HStack {
                    Image(systemName: "person.fill")
                        .foregroundColor(.white.opacity(0.7))
                        .accessibilityHidden(true)
                    TextField(String(localized: "auth_username_placeholder"), text: $username)
                        .textFieldStyle(PlainTextFieldStyle())
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .foregroundColor(.white)
                        .accessibilityLabel(String(localized: "auth_username"))
                        .accessibilityValue(username.isEmpty ? String(localized: "a11y_empty_field") : username)
                }
                .padding()
                .background(Color.white.opacity(0.2))
                .cornerRadius(10)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(String(localized: "auth_password"))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))

                HStack {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.white.opacity(0.7))
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
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .accessibilityLabel(showPassword ? String(localized: "a11y_hide_password") : String(localized: "a11y_show_password"))
                }
                .padding()
                .background(Color.white.opacity(0.2))
                .cornerRadius(10)
            }

            Button(action: handleLogin) {
                if authViewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .accessibilityLabel(String(localized: "loading"))
                } else {
                    Text(String(localized: "auth_login_button"))
                        .font(.headline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
            }
            .background(Color.white)
            .cornerRadius(10)
            .disabled(authViewModel.isLoading || username.isEmpty || password.isEmpty)
            .opacity((authViewModel.isLoading || username.isEmpty || password.isEmpty) ? 0.6 : 1.0)
            .buttonAccessibility(
                label: String(localized: "auth_login_button"),
                hint: nil,
                isEnabled: !authViewModel.isLoading && !username.isEmpty && !password.isEmpty
            )
        }
    }

    private var biometricButton: some View {
        VStack(spacing: 15) {
            HStack {
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(height: 1)
                    .accessibilityHidden(true)
                Text(String(localized: "auth_or"))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(height: 1)
                    .accessibilityHidden(true)
            }

            Button(action: handleBiometricLogin) {
                HStack {
                    Image(systemName: authViewModel.biometricIcon)
                        .font(.title2)
                        .accessibilityHidden(true)
                    Text(String(format: NSLocalizedString("biometry_login", comment: ""), authViewModel.biometricDisplayName))
                        .font(.subheadline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white.opacity(0.2))
                .cornerRadius(10)
            }
            .disabled(authViewModel.isLoading || !authViewModel.isBiometricEnabled)
            .buttonAccessibility(
                label: String(format: NSLocalizedString("biometry_login", comment: ""), authViewModel.biometricDisplayName),
                hint: nil,
                isEnabled: !authViewModel.isLoading && authViewModel.isBiometricEnabled
            )
        }
    }

    private var bottomActionsView: some View {
        VStack(spacing: 15) {
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

            #if DEBUG
            Button(action: handleDemoLogin) {
                Text(String(localized: "auth_demo_account"))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            .buttonAccessibility(
                label: String(localized: "auth_demo_account"),
                hint: nil
            )
            #endif
        }
    }

    private func handleLogin() {
        Task {
            let credentials = AuthCredentials(username: username, password: password)
            await authViewModel.login(credentials: credentials)
        }
    }

    private func handleBiometricLogin() {
        Task {
            await authViewModel.loginWithBiometric()
        }
    }

    private func handleDemoLogin() {
        Task {
            await authViewModel.createDemoAccount()
        }
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
