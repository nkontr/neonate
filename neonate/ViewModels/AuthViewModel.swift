import Foundation
import Combine
import SwiftUI
import AuthenticationServices

@MainActor
class AuthViewModel: ObservableObject {

    @Published var isAuthenticated: Bool = false

    @Published var isLoading: Bool = false
    @Published var isBiometricLoading: Bool = false

    var currentUser: User?
    var errorMessage: String?
    var showError: Bool = false
    var successMessage: String?
    var showSuccess: Bool = false
    @Published var isBiometricAvailable: Bool = false
    @Published var biometricType: BiometricAuthService.BiometricType = .none
    @Published var isBiometricEnabled: Bool = false

    private let authService = AuthService.shared
    private let biometricService = BiometricAuthService.shared

    init() {
        // Не проверяем авторизацию автоматически при инициализации
        // Это будет сделано позже в RootView
        Task {
            await checkBiometricAvailability()
        }
    }

    func register(credentials: RegistrationCredentials) async {
        print("📝 Starting registration for user: \(credentials.username)")
        isLoading = true
        errorMessage = nil

        do {
            let response = try await authService.register(credentials: credentials)
            currentUser = response.user
            isAuthenticated = true
            print("✅ Registration successful! User: \(response.user.username), isAuthenticated: \(isAuthenticated)")
            successMessage = response.message ?? "Регистрация прошла успешно"
            showSuccess = true
        } catch let error as AuthService.AuthError {
            print("❌ Registration failed: \(error.errorDescription ?? "Unknown error")")
            errorMessage = error.errorDescription
            showError = true
        } catch {
            print("❌ Registration failed with unknown error: \(error.localizedDescription)")
            errorMessage = "Неизвестная ошибка: \(error.localizedDescription)"
            showError = true
        }

        isLoading = false
    }

    func login(credentials: AuthCredentials) async {
        print("🔑 Starting login for user: \(credentials.username)")
        isLoading = true
        errorMessage = nil

        do {
            let response = try await authService.login(credentials: credentials)
            currentUser = response.user
            isAuthenticated = true
            print("✅ Login successful! User: \(response.user.username), isAuthenticated: \(isAuthenticated)")
            successMessage = response.message ?? "Вход выполнен успешно"
            showSuccess = true
        } catch let error as AuthService.AuthError {
            print("❌ Login failed: \(error.errorDescription ?? "Unknown error")")
            errorMessage = error.errorDescription
            showError = true
        } catch {
            print("❌ Login failed with unknown error: \(error.localizedDescription)")
            errorMessage = "Неизвестная ошибка: \(error.localizedDescription)"
            showError = true
        }

        isLoading = false
    }

    func loginWithBiometric() async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await authService.loginWithBiometric()
            currentUser = response.user
            isAuthenticated = true
            successMessage = response.message ?? "Вход выполнен с помощью биометрии"
            showSuccess = true
        } catch let error as AuthService.AuthError {
            errorMessage = error.errorDescription
            showError = true
        } catch let error as BiometricAuthService.BiometricError {
            errorMessage = error.errorDescription
            showError = true
        } catch {
            errorMessage = "Неизвестная ошибка: \(error.localizedDescription)"
            showError = true
        }

        isLoading = false
    }

    func loginWithApple(credential: ASAuthorizationAppleIDCredential) async {
        print("🍎 AuthViewModel: Processing Apple Sign In...")
        isLoading = true
        errorMessage = nil

        do {
            let response = try await authService.loginWithApple(credential: credential)
            currentUser = response.user
            isAuthenticated = true
            successMessage = response.message ?? "Вход выполнен через Apple ID"
            showSuccess = true
            print("✅ AuthViewModel: Apple Sign In completed, isAuthenticated = \(isAuthenticated)")
        } catch let error as AuthService.AuthError {
            print("❌ AuthViewModel: Auth error - \(error.errorDescription ?? "unknown")")
            errorMessage = error.errorDescription
            showError = true
        } catch {
            print("❌ AuthViewModel: Unknown error - \(error.localizedDescription)")
            errorMessage = "Ошибка входа через Apple: \(error.localizedDescription)"
            showError = true
        }

        isLoading = false
    }

    func logout() async {
        isLoading = true
        errorMessage = nil

        do {
            try await authService.logout()
            currentUser = nil
            isAuthenticated = false
            successMessage = "Выход выполнен успешно"
            showSuccess = true
        } catch {
            errorMessage = "Ошибка при выходе: \(error.localizedDescription)"
            showError = true
        }

        isLoading = false
    }

    func checkAuthenticationStatus() async {
        isLoading = true

        do {
            if let response = try await authService.restoreSession() {
                currentUser = response.user
                isAuthenticated = true
                await checkBiometricEnabled()
            } else {
                isAuthenticated = false
            }
        } catch {
            isAuthenticated = false
        }

        isLoading = false
    }

    func refreshTokenIfNeeded() async {
        if await authService.shouldRefreshToken() {
            do {
                guard let refreshToken = await KeychainService.shared.loadRefreshToken() else {
                    return
                }
                _ = try await authService.refreshToken(refreshToken: refreshToken)
            } catch {

                await logout()
            }
        }
    }

    func checkBiometricAvailability() async {
        let availability = biometricService.checkBiometricAvailability()
        isBiometricAvailable = availability.available
        biometricType = availability.type
    }

    func checkBiometricEnabled() async {
        isBiometricEnabled = await biometricService.isBiometricEnabled()
    }

    func enableBiometric() async {
        isBiometricLoading = true
        errorMessage = nil

        do {
            try await authService.enableBiometric()
            isBiometricEnabled = true
            successMessage = String(localized: "biometric_enabled_success")
            showSuccess = true
        } catch let error as BiometricAuthService.BiometricError {
            errorMessage = error.errorDescription
            showError = true
        } catch {
            errorMessage = String(localized: "biometric_enable_error")
            showError = true
        }

        isBiometricLoading = false
    }

    func disableBiometric() async {
        isBiometricLoading = true
        errorMessage = nil

        do {
            try await authService.disableBiometric()
            isBiometricEnabled = false
        } catch {
            errorMessage = String(localized: "biometric_disable_error")
            showError = true
        }

        isBiometricLoading = false
    }

    /// Verify biometric authentication locally without changing isAuthenticated state
    /// Returns true if biometric authentication succeeded, false otherwise
    func verifyBiometric() async -> Bool {
        isLoading = true
        errorMessage = nil
        showError = false

        do {
            let authenticated = try await biometricService.authenticate(reason: String(localized: "biometric_unlock_reason"))
            isLoading = false
            return authenticated
        } catch let error as BiometricAuthService.BiometricError {
            errorMessage = error.errorDescription
            showError = true
            isLoading = false
            return false
        } catch {
            errorMessage = "Ошибка биометрической аутентификации"
            showError = true
            isLoading = false
            return false
        }
    }

    func toggleBiometric() async {
        if isBiometricEnabled {
            await disableBiometric()
        } else {
            await enableBiometric()
        }
    }

    func updateUserProfile(_ user: User, showSuccessMessage: Bool = true, updateLoadingState: Bool = true) async {
        if updateLoadingState {
            isLoading = true
        }
        errorMessage = nil

        do {
            try await authService.updateUserProfile(user)
            currentUser = user
            if showSuccessMessage {
                successMessage = "Профиль обновлен"
                showSuccess = true
            }
        } catch {
            errorMessage = "Ошибка при обновлении профиля: \(error.localizedDescription)"
            showError = true
        }

        if updateLoadingState {
            isLoading = false
        }
    }

    func changePassword(oldPassword: String, newPassword: String) async {
        isLoading = true
        errorMessage = nil

        do {
            try await authService.changePassword(oldPassword: oldPassword, newPassword: newPassword)
            successMessage = "Пароль успешно изменен"
            showSuccess = true
        } catch let error as AuthService.AuthError {
            errorMessage = error.errorDescription
            showError = true
        } catch {
            errorMessage = "Ошибка при изменении пароля: \(error.localizedDescription)"
            showError = true
        }

        isLoading = false
    }

    func resetPassword(email: String) async {
        isLoading = true
        errorMessage = nil

        do {
            try await authService.resetPassword(email: email)
            successMessage = "Инструкции по восстановлению пароля отправлены на \(email)"
            showSuccess = true
        } catch let error as AuthService.AuthError {
            errorMessage = error.errorDescription
            showError = true
        } catch {
            errorMessage = "Ошибка при сбросе пароля: \(error.localizedDescription)"
            showError = true
        }

        isLoading = false
    }

    func createDemoAccount() async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await authService.createDemoAccount()
            currentUser = response.user
            isAuthenticated = true
            successMessage = "Демо-аккаунт создан. Логин: demo_user, Пароль: demo123"
            showSuccess = true
        } catch {
            errorMessage = "Ошибка при создании демо-аккаунта: \(error.localizedDescription)"
            showError = true
        }

        isLoading = false
    }

    func clearError() {
        errorMessage = nil
        showError = false
    }

    func clearSuccess() {
        successMessage = nil
        showSuccess = false
    }

    var biometricDisplayName: String {
        biometricType.displayName
    }

    var biometricIcon: String {
        biometricType.icon
    }
}

#if DEBUG
extension AuthViewModel {

    static var preview: AuthViewModel {
        let viewModel = AuthViewModel()
        viewModel.isAuthenticated = true
        viewModel.currentUser = User.preview
        viewModel.isBiometricAvailable = true
        viewModel.biometricType = .faceID
        viewModel.isBiometricEnabled = true
        return viewModel
    }

    static var previewUnauthenticated: AuthViewModel {
        let viewModel = AuthViewModel()
        viewModel.isAuthenticated = false
        viewModel.isBiometricAvailable = true
        viewModel.biometricType = .touchID
        return viewModel
    }

    static var previewWithError: AuthViewModel {
        let viewModel = AuthViewModel()
        viewModel.isAuthenticated = false
        viewModel.errorMessage = "Неверное имя пользователя или пароль"
        viewModel.showError = true
        return viewModel
    }

    static var previewLoading: AuthViewModel {
        let viewModel = AuthViewModel()
        viewModel.isLoading = true
        return viewModel
    }
}
#endif
