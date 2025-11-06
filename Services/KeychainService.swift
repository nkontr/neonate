import Foundation
import Security

class KeychainService {

    static let shared = KeychainService()

    private init() {}

    private let service: String = {
        Bundle.main.bundleIdentifier ?? "com.neonate.app"
    }()

    enum KeychainKey: String {
        case accessToken = "com.neonate.accessToken"
        case refreshToken = "com.neonate.refreshToken"
        case userCredentials = "com.neonate.userCredentials"
        case currentUser = "com.neonate.currentUser"
        case biometricEnabled = "com.neonate.biometricEnabled"
    }

    enum KeychainError: LocalizedError {
        case itemNotFound
        case duplicateItem
        case invalidData
        case unexpectedStatus(OSStatus)
        case encodingError
        case decodingError

        var errorDescription: String? {
            switch self {
            case .itemNotFound:
                return "Элемент не найден в Keychain"
            case .duplicateItem:
                return "Элемент уже существует в Keychain"
            case .invalidData:
                return "Некорректные данные"
            case .unexpectedStatus(let status):
                return "Неожиданная ошибка Keychain: \(status)"
            case .encodingError:
                return "Ошибка при кодировании данных"
            case .decodingError:
                return "Ошибка при декодировании данных"
            }
        }
    }

    func save(
        _ data: Data,
        forKey key: KeychainKey,
        accessible: CFString = kSecAttrAccessibleWhenUnlocked
    ) throws {

        try? delete(forKey: key)

        var query = baseQuery(forKey: key)
        query[kSecValueData as String] = data
        query[kSecAttrAccessible as String] = accessible

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            if status == errSecDuplicateItem {
                throw KeychainError.duplicateItem
            }
            throw KeychainError.unexpectedStatus(status)
        }
    }

    func load(forKey key: KeychainKey) throws -> Data {
        var query = baseQuery(forKey: key)
        query[kSecReturnData as String] = kCFBooleanTrue
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status != errSecItemNotFound else {
            throw KeychainError.itemNotFound
        }

        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }

        guard let data = item as? Data else {
            throw KeychainError.invalidData
        }

        return data
    }

    @discardableResult
    func delete(forKey key: KeychainKey) throws -> Bool {
        let query = baseQuery(forKey: key)
        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }

        return status == errSecSuccess
    }

    func exists(forKey key: KeychainKey) -> Bool {
        var query = baseQuery(forKey: key)
        query[kSecReturnData as String] = kCFBooleanFalse
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    func clearAll() throws {
        let keys: [KeychainKey] = [.accessToken, .refreshToken, .userCredentials, .currentUser, .biometricEnabled]

        for key in keys {
            try? delete(forKey: key)
        }
    }

    func save<T: Encodable>(
        _ value: T,
        forKey key: KeychainKey,
        accessible: CFString = kSecAttrAccessibleWhenUnlocked
    ) throws {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(value) else {
            throw KeychainError.encodingError
        }

        try save(data, forKey: key, accessible: accessible)
    }

    func load<T: Decodable>(_ type: T.Type, forKey key: KeychainKey) throws -> T {
        let data = try load(forKey: key)

        let decoder = JSONDecoder()
        guard let value = try? decoder.decode(type, from: data) else {
            throw KeychainError.decodingError
        }

        return value
    }

    func save(
        _ string: String,
        forKey key: KeychainKey,
        accessible: CFString = kSecAttrAccessibleWhenUnlocked
    ) throws {
        guard let data = string.data(using: .utf8) else {
            throw KeychainError.invalidData
        }

        try save(data, forKey: key, accessible: accessible)
    }

    func loadString(forKey key: KeychainKey) throws -> String {
        let data = try load(forKey: key)

        guard let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidData
        }

        return string
    }

    func saveTokens(_ tokens: AuthToken) async throws {
        try save(tokens.accessToken, forKey: .accessToken)
        try save(tokens.refreshToken, forKey: .refreshToken)
    }

    func loadAccessToken() async -> String? {
        try? loadString(forKey: .accessToken)
    }

    func loadRefreshToken() async -> String? {
        try? loadString(forKey: .refreshToken)
    }

    func deleteTokens() async throws {
        try delete(forKey: .accessToken)
        try delete(forKey: .refreshToken)
    }

    func hasValidTokens() async -> Bool {
        exists(forKey: .accessToken) && exists(forKey: .refreshToken)
    }

    func saveUser(_ user: User) async throws {
        try save(user, forKey: .currentUser)
    }

    func loadUser() async -> User? {
        try? load(User.self, forKey: .currentUser)
    }

    func deleteUser() async throws {
        try delete(forKey: .currentUser)
    }

    func saveBiometricEnabled(_ enabled: Bool) async throws {
        try save(enabled, forKey: .biometricEnabled)
    }

    func loadBiometricEnabled() async -> Bool {
        (try? load(Bool.self, forKey: .biometricEnabled)) ?? false
    }

    private func baseQuery(forKey key: KeychainKey) -> [String: Any] {
        return [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue
        ]
    }
}

extension KeychainService {

    func saveAsync(
        _ data: Data,
        forKey key: KeychainKey,
        accessible: CFString = kSecAttrAccessibleWhenUnlocked
    ) async throws {
        try save(data, forKey: key, accessible: accessible)
    }

    func loadAsync(forKey key: KeychainKey) async throws -> Data {
        try load(forKey: key)
    }

    @discardableResult
    func deleteAsync(forKey key: KeychainKey) async throws -> Bool {
        try delete(forKey: key)
    }

    func existsAsync(forKey key: KeychainKey) async -> Bool {
        exists(forKey: key)
    }

    func clearAllAsync() async throws {
        try clearAll()
    }
}

#if DEBUG
extension KeychainService {

    func debugPrintAllKeys() {
        let keys: [KeychainKey] = [.accessToken, .refreshToken, .userCredentials, .currentUser, .biometricEnabled]

        print("=== Keychain Contents ===")
        for key in keys {
            let exists = exists(forKey: key)
            print("\(key.rawValue): \(exists ? "EXISTS" : "NOT FOUND")")
        }
        print("========================")
    }
}
#endif
