import Foundation
import LocalAuthentication
import Combine
import CryptoKit

class AuthService {

    static let shared = AuthService()

    private init() {}

    private let keychainService = KeychainService.shared
    private let jwtService = JWTService.shared
    private let biometricService = BiometricAuthService.shared
    private lazy var userRepository = UserAccountRepository(context: PersistenceController.shared.container.viewContext)

    private(set) var currentUser: User?

    private(set) var currentTokens: AuthToken?

    private var mockUsers: [String: (passwordHash: String, user: User)] = [:]

    enum AuthError: LocalizedError {
        case invalidCredentials
        case userAlreadyExists
        case userNotFound
        case tokenExpired
        case tokenInvalid
        case networkError
        case registrationFailed(String)
        case biometricFailed
        case unknown(Error)

        var errorDescription: String? {
            switch self {
            case .invalidCredentials:
                return "Неверное имя пользователя или пароль"
            case .userAlreadyExists:
                return "Пользователь с таким именем или email уже существует"
            case .userNotFound:
                return "Пользователь не найден"
            case .tokenExpired:
                return "Токен истек, пожалуйста, войдите снова"
            case .tokenInvalid:
                return "Недействительный токен"
            case .networkError:
                return "Ошибка сети, проверьте подключение"
            case .registrationFailed(let reason):
                return "Ошибка регистрации: \(reason)"
            case .biometricFailed:
                return "Биометрическая аутентификация не удалась"
            case .unknown(let error):
                return "Неизвестная ошибка: \(error.localizedDescription)"
            }
        }
    }

    func register(credentials: RegistrationCredentials) async throws -> AuthResponse {

        let validationErrors = credentials.validate()
        guard validationErrors.isEmpty else {
            throw AuthError.registrationFailed(validationErrors.first?.errorDescription ?? "Некорректные данные")
        }

        if mockUsers[credentials.username] != nil {
            throw AuthError.userAlreadyExists
        }

        if mockUsers.values.contains(where: { $0.user.email == credentials.email }) {
            throw AuthError.userAlreadyExists
        }

        let user = User(
            username: credentials.username,
            email: credentials.email,
            fullName: credentials.fullName,
            registeredAt: Date(),
            lastLoginAt: Date()
        )

        let passwordHash = hashPassword(credentials.password)

        mockUsers[credentials.username] = (passwordHash: passwordHash, user: user)

        do {
            _ = try await userRepository.createUserAccount(
                username: user.username,
                email: user.email,
                passwordHash: passwordHash
            )
        } catch {
            print("⚠️ Не удалось сохранить пользователя в CoreData: \(error)")
            throw AuthError.registrationFailed("Не удалось сохранить данные")
        }

        let tokens = jwtService.generateTokenPair(
            userId: user.id,
            username: user.username,
            email: user.email
        )

        currentUser = user
        currentTokens = tokens

        try await keychainService.saveTokens(tokens)
        try await keychainService.saveUser(user)

        return AuthResponse(user: user, tokens: tokens, message: "Регистрация прошла успешно")
    }

    func login(credentials: AuthCredentials) async throws -> AuthResponse {

        guard credentials.isValid else {
            throw AuthError.invalidCredentials
        }

        guard let account = userRepository.fetchUserAccount(byUsername: credentials.username) else {
            throw AuthError.invalidCredentials
        }

        let passwordHash = hashPassword(credentials.password)
        guard let storedPasswordHash = account.passwordHash, storedPasswordHash == passwordHash else {
            throw AuthError.invalidCredentials
        }

        let user = User(
            id: account.id!,
            username: account.username!,
            email: account.email!,
            fullName: nil,
            registeredAt: account.registeredAt!,
            lastLoginAt: Date()
        )

        try await userRepository.updateLastLogin(account)

        mockUsers[credentials.username]?.user = user

        let tokens = jwtService.generateTokenPair(
            userId: user.id,
            username: user.username,
            email: user.email
        )

        currentUser = user
        currentTokens = tokens

        try await keychainService.saveTokens(tokens)
        try await keychainService.saveUser(user)

        return AuthResponse(user: user, tokens: tokens, message: "Вход выполнен успешно")
    }

    func loginWithBiometric() async throws -> AuthResponse {

        let biometricEnabled = await biometricService.isBiometricEnabled()
        guard biometricEnabled else {
            throw AuthError.biometricFailed
        }

        do {
            let authenticated = try await biometricService.authenticate(reason: "Войдите с помощью биометрии")
            guard authenticated else {
                throw AuthError.biometricFailed
            }
        } catch {
            throw AuthError.biometricFailed
        }

        guard let user = await keychainService.loadUser(),
              let accessToken = await keychainService.loadAccessToken(),
              let refreshToken = await keychainService.loadRefreshToken() else {
            throw AuthError.userNotFound
        }

        let tokens = AuthToken(
            accessToken: accessToken,
            refreshToken: refreshToken,
            tokenType: "Bearer",
            expiresIn: 3600,
            issuedAt: Date()
        )

        let validTokens: AuthToken
        if tokens.isExpired {
            let newTokens = try await self.refreshToken(refreshToken: tokens.refreshToken)
            validTokens = newTokens
        } else {
            validTokens = tokens
        }

        currentUser = user
        currentTokens = validTokens

        return AuthResponse(user: user, tokens: validTokens, message: "Вход выполнен с помощью биометрии")
    }

    func logout() async throws {

        currentUser = nil
        currentTokens = nil

        try await keychainService.deleteTokens()
        try await keychainService.deleteUser()
    }

    func refreshToken(refreshToken: String) async throws -> AuthToken {

        guard let payload = jwtService.validateToken(refreshToken) else {
            throw AuthError.tokenInvalid
        }

        guard payload.type == .refresh else {
            throw AuthError.tokenInvalid
        }

        guard let userId = UUID(uuidString: payload.sub) else {
            throw AuthError.tokenInvalid
        }

        let newTokens = jwtService.generateTokenPair(
            userId: userId,
            username: payload.username,
            email: payload.email
        )

        currentTokens = newTokens
        try await keychainService.saveTokens(newTokens)

        return newTokens
    }

    func validateToken() async -> Bool {
        guard let tokens = currentTokens else {
            return false
        }

        return jwtService.validateToken(tokens.accessToken) != nil
    }

    func shouldRefreshToken() async -> Bool {
        guard let tokens = currentTokens else {
            return false
        }

        return tokens.needsRefresh
    }

    func restoreSession() async throws -> AuthResponse? {

        guard let user = await keychainService.loadUser(),
              let accessToken = await keychainService.loadAccessToken(),
              let refreshToken = await keychainService.loadRefreshToken() else {
            return nil
        }

        let tokens = AuthToken(
            accessToken: accessToken,
            refreshToken: refreshToken,
            tokenType: "Bearer",
            expiresIn: 3600,
            issuedAt: Date()
        )

        if jwtService.validateToken(tokens.accessToken) != nil {

            currentUser = user
            currentTokens = tokens
            return AuthResponse(user: user, tokens: tokens, message: "Сессия восстановлена")
        }

        if jwtService.validateToken(tokens.refreshToken) != nil {
            do {
                let newTokens = try await self.refreshToken(refreshToken: tokens.refreshToken)
                currentUser = user
                currentTokens = newTokens
                return AuthResponse(user: user, tokens: newTokens, message: "Сессия обновлена")
            } catch {

                try? await logout()
                return nil
            }
        }

        try? await logout()
        return nil
    }

    func isAuthenticated() -> Bool {
        return currentUser != nil && currentTokens != nil
    }

    func getCurrentUser() async -> User? {
        if let user = currentUser {
            return user
        }

        return await keychainService.loadUser()
    }

    func updateUserProfile(_ user: User) async throws {

        if let username = mockUsers.first(where: { $0.value.user.id == user.id })?.key {
            mockUsers[username]?.user = user
        }

        try await keychainService.saveUser(user)

        currentUser = user

        if let account = userRepository.fetchUserAccount(byUsername: user.username) {
            try await userRepository.updateUserAccount(
                account,
                username: user.username,
                email: user.email
            )
        }
    }

    func changePassword(oldPassword: String, newPassword: String) async throws {
        guard let user = currentUser else {
            throw AuthError.userNotFound
        }

        guard let userEntry = mockUsers[user.username] else {
            throw AuthError.userNotFound
        }

        let oldPasswordHash = hashPassword(oldPassword)
        guard userEntry.passwordHash == oldPasswordHash else {
            throw AuthError.invalidCredentials
        }

        let newPasswordHash = hashPassword(newPassword)
        mockUsers[user.username]?.passwordHash = newPasswordHash
    }

    func resetPassword(email: String) async throws {

        guard mockUsers.values.contains(where: { $0.user.email == email }) else {
            throw AuthError.userNotFound
        }

        try await Task.sleep(nanoseconds: 1_000_000_000)
    }

    func enableBiometric() async throws {
        guard currentUser != nil else {
            throw AuthError.userNotFound
        }

        try await biometricService.enableBiometric()
    }

    func disableBiometric() async throws {
        try await biometricService.disableBiometric()
    }

    private func hashPassword(_ password: String) -> String {
        let inputData = Data((password + "salt_neonate_2025").utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }

    func createDemoAccount() async throws -> AuthResponse {
        let demoCredentials = RegistrationCredentials(
            username: "demo_user",
            email: "demo@neonate.app",
            password: "demo123",
            confirmPassword: "demo123",
            fullName: "Демо Пользователь"
        )

        return try await register(credentials: demoCredentials)
    }

    func hasDemoAccount() -> Bool {
        return mockUsers["demo_user"] != nil
    }
}

#if DEBUG
extension AuthService {

    func setupMockData() {
        let testUser = User(
            username: "test_user",
            email: "test@example.com",
            fullName: "Тестовый Пользователь"
        )

        let passwordHash = hashPassword("test123")
        mockUsers["test_user"] = (passwordHash: passwordHash, user: testUser)
    }

    func clearMockData() {
        mockUsers.removeAll()
        currentUser = nil
        currentTokens = nil
    }
}
#endif
