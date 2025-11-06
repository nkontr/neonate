import Foundation
import LocalAuthentication

class BiometricAuthService {

    static let shared = BiometricAuthService()

    private init() {}

    private let context = LAContext()
    private let keychainService = KeychainService.shared

    enum BiometricType {
        case faceID
        case touchID
        case opticID
        case none

        var displayName: String {
            switch self {
            case .faceID:
                return "Face ID"
            case .touchID:
                return "Touch ID"
            case .opticID:
                return "Optic ID"
            case .none:
                return "Биометрия недоступна"
            }
        }

        var icon: String {
            switch self {
            case .faceID:
                return "faceid"
            case .touchID:
                return "touchid"
            case .opticID:
                return "opticid"
            case .none:
                return "lock.fill"
            }
        }
    }

    enum BiometricError: LocalizedError {
        case notAvailable
        case notEnrolled
        case lockout
        case userCancel
        case userFallback
        case systemCancel
        case passcodeNotSet
        case biometryNotEnrolled
        case unknown(Error)

        var errorDescription: String? {
            switch self {
            case .notAvailable:
                return "Биометрическая аутентификация недоступна на этом устройстве"
            case .notEnrolled:
                return "Биометрия не настроена. Пожалуйста, настройте Face ID или Touch ID в настройках устройства"
            case .lockout:
                return "Биометрия заблокирована из-за множественных неудачных попыток"
            case .userCancel:
                return "Аутентификация отменена пользователем"
            case .userFallback:
                return "Пользователь выбрал альтернативный метод аутентификации"
            case .systemCancel:
                return "Аутентификация отменена системой"
            case .passcodeNotSet:
                return "Пароль устройства не установлен"
            case .biometryNotEnrolled:
                return "Биометрия не зарегистрирована"
            case .unknown(let error):
                return "Неизвестная ошибка: \(error.localizedDescription)"
            }
        }
    }

    func checkBiometricAvailability() -> (available: Bool, type: BiometricType, error: BiometricError?) {
        let context = LAContext()
        var authError: NSError?

        let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError)

        let biometricType: BiometricType
        switch context.biometryType {
        case .faceID:
            biometricType = .faceID
        case .touchID:
            biometricType = .touchID
        case .opticID:
            biometricType = .opticID
        case .none:
            biometricType = .none
        @unknown default:
            biometricType = .none
        }

        var error: BiometricError?
        if let authError = authError {
            error = mapError(authError)
        }

        return (canEvaluate, biometricType, error)
    }

    func getBiometricType() -> BiometricType {
        let context = LAContext()
        switch context.biometryType {
        case .faceID:
            return .faceID
        case .touchID:
            return .touchID
        case .opticID:
            return .opticID
        case .none:
            return .none
        @unknown default:
            return .none
        }
    }

    func isBiometricAvailable() -> Bool {
        checkBiometricAvailability().available
    }

    func authenticate(reason: String = "Войдите для доступа к приложению") async throws -> Bool {
        let context = LAContext()

        context.localizedCancelTitle = "Отмена"
        context.localizedFallbackTitle = "Использовать пароль"

        var authError: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError) else {
            if let error = authError {
                throw mapError(error)
            }
            throw BiometricError.notAvailable
        }

        return try await withCheckedThrowingContinuation { continuation in
            context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            ) { success, error in
                if success {
                    continuation.resume(returning: true)
                } else if let error = error as? LAError {
                    continuation.resume(throwing: self.mapLAError(error))
                } else if let error = error {
                    continuation.resume(throwing: BiometricError.unknown(error))
                } else {
                    continuation.resume(returning: false)
                }
            }
        }
    }

    func authenticateWithDevicePasscode(reason: String = "Войдите для доступа к приложению") async throws -> Bool {
        let context = LAContext()

        context.localizedCancelTitle = "Отмена"

        var authError: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &authError) else {
            if let error = authError {
                throw mapError(error)
            }
            throw BiometricError.notAvailable
        }

        return try await withCheckedThrowingContinuation { continuation in
            context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason
            ) { success, error in
                if success {
                    continuation.resume(returning: true)
                } else if let error = error as? LAError {
                    continuation.resume(throwing: self.mapLAError(error))
                } else if let error = error {
                    continuation.resume(throwing: BiometricError.unknown(error))
                } else {
                    continuation.resume(returning: false)
                }
            }
        }
    }

    func isBiometricEnabled() async -> Bool {
        await keychainService.loadBiometricEnabled()
    }

    func enableBiometric() async throws {

        let availability = checkBiometricAvailability()
        guard availability.available else {
            if let error = availability.error {
                throw error
            }
            throw BiometricError.notAvailable
        }

        let authenticated = try await authenticate(reason: "Подтвердите настройку биометрической аутентификации")

        if authenticated {
            try await keychainService.saveBiometricEnabled(true)
        }
    }

    func disableBiometric() async throws {
        try await keychainService.saveBiometricEnabled(false)
    }

    func toggleBiometric() async throws -> Bool {
        let currentState = await isBiometricEnabled()

        if currentState {
            try await disableBiometric()
            return false
        } else {
            try await enableBiometric()
            return true
        }
    }

    private func mapError(_ error: NSError) -> BiometricError {
        switch error.code {
        case LAError.biometryNotAvailable.rawValue:
            return .notAvailable
        case LAError.biometryNotEnrolled.rawValue:
            return .notEnrolled
        case LAError.biometryLockout.rawValue:
            return .lockout
        case LAError.passcodeNotSet.rawValue:
            return .passcodeNotSet
        default:
            return .unknown(error)
        }
    }

    private func mapLAError(_ error: LAError) -> BiometricError {
        switch error.code {
        case .biometryNotAvailable:
            return .notAvailable
        case .biometryNotEnrolled:
            return .notEnrolled
        case .biometryLockout:
            return .lockout
        case .userCancel:
            return .userCancel
        case .userFallback:
            return .userFallback
        case .systemCancel:
            return .systemCancel
        case .passcodeNotSet:
            return .passcodeNotSet
        default:
            return .unknown(error)
        }
    }
}

#if DEBUG
extension BiometricAuthService {

    static func mockSuccessfulAuth() async throws -> Bool {

        try await Task.sleep(nanoseconds: 500_000_000)
        return true
    }

    static func mockFailedAuth() async throws -> Bool {
        try await Task.sleep(nanoseconds: 500_000_000)
        throw BiometricError.userCancel
    }
}
#endif
