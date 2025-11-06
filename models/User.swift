import Foundation

struct User: Codable, Identifiable {

    let id: UUID

    var username: String

    var email: String

    var fullName: String?

    var avatarURL: String?

    let registeredAt: Date

    var lastLoginAt: Date?

    var biometricAuthEnabled: Bool

    var preferences: [String: String]

    init(
        id: UUID = UUID(),
        username: String,
        email: String,
        fullName: String? = nil,
        avatarURL: String? = nil,
        registeredAt: Date = Date(),
        lastLoginAt: Date? = nil,
        biometricAuthEnabled: Bool = false,
        preferences: [String: String] = [:]
    ) {
        self.id = id
        self.username = username
        self.email = email
        self.fullName = fullName
        self.avatarURL = avatarURL
        self.registeredAt = registeredAt
        self.lastLoginAt = lastLoginAt
        self.biometricAuthEnabled = biometricAuthEnabled
        self.preferences = preferences
    }

    var initials: String {
        if let fullName = fullName, !fullName.isEmpty {
            let components = fullName.split(separator: " ")
            let initials = components.prefix(2).compactMap { $0.first }.map { String($0).uppercased() }
            return initials.joined()
        }
        return String(username.prefix(2).uppercased())
    }

    var daysSinceRegistration: Int {
        Calendar.current.dateComponents([.day], from: registeredAt, to: Date()).day ?? 0
    }
}

extension User: Equatable {
    static func == (lhs: User, rhs: User) -> Bool {
        lhs.id == rhs.id
    }
}

#if DEBUG
extension User {

    static var preview: User {
        User(
            username: "test_user",
            email: "test@example.com",
            fullName: "Тестовый Пользователь",
            lastLoginAt: Date(),
            biometricAuthEnabled: true
        )
    }

    static var previewUsers: [User] {
        [
            User(username: "alice", email: "alice@example.com", fullName: "Алиса Иванова"),
            User(username: "bob", email: "bob@example.com", fullName: "Боб Петров", biometricAuthEnabled: true),
            User(username: "charlie", email: "charlie@example.com")
        ]
    }
}
#endif
