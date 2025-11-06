import Foundation
import CoreData
import Combine

class UserAccountRepository: BaseRepository<UserAccount> {

    func createUserAccount(
        username: String,
        email: String,
        passwordHash: String,
        preferences: String? = nil
    ) async throws -> UserAccount {
        let account = create()
        account.id = UUID()
        account.username = username
        account.email = email
        account.passwordHash = passwordHash
        account.registeredAt = Date()
        account.lastLoginAt = Date()
        account.preferences = preferences

        try await PersistenceController.shared.saveContext(context)
        return account
    }

    func updateUserAccount(
        _ account: UserAccount,
        username: String? = nil,
        email: String? = nil,
        preferences: String? = nil
    ) async throws {
        if let username = username { account.username = username }
        if let email = email { account.email = email }
        if let preferences = preferences { account.preferences = preferences }

        try await PersistenceController.shared.saveContext(context)
    }

    func updateLastLogin(_ account: UserAccount, timestamp: Date = Date()) async throws {
        account.lastLoginAt = timestamp
        try await PersistenceController.shared.saveContext(context)
    }

    func deleteUserAccount(_ account: UserAccount) async throws {
        delete(account)
        try await PersistenceController.shared.saveContext(context)
    }

    func fetchUserAccount(by id: UUID) -> UserAccount? {
        let predicate = NSPredicate(format: "id == %@", id as CVarArg)
        return fetch(with: predicate).first
    }

    func fetchUserAccount(by email: String) -> UserAccount? {
        let predicate = NSPredicate(format: "email == %@", email)
        return fetch(with: predicate).first
    }

    func fetchUserAccount(byUsername username: String) -> UserAccount? {
        let predicate = NSPredicate(format: "username == %@", username)
        return fetch(with: predicate).first
    }

    func fetchAllAccounts(ascending: Bool = false) -> [UserAccount] {
        let sortDescriptor = NSSortDescriptor(key: "registeredAt", ascending: ascending)
        return fetch(sortedBy: [sortDescriptor])
    }

    func searchAccounts(by searchText: String) -> [UserAccount] {
        let predicate = NSPredicate(
            format: "username CONTAINS[cd] %@ OR email CONTAINS[cd] %@",
            searchText,
            searchText
        )
        let sortDescriptor = NSSortDescriptor(key: "username", ascending: true)
        return fetch(sortedBy: [sortDescriptor], predicate: predicate)
    }

    func fetchAccounts(registeredBetween startDate: Date, and endDate: Date) -> [UserAccount] {
        let predicate = NSPredicate(
            format: "registeredAt >= %@ AND registeredAt <= %@",
            startDate as CVarArg,
            endDate as CVarArg
        )
        let sortDescriptor = NSSortDescriptor(key: "registeredAt", ascending: false)
        return fetch(sortedBy: [sortDescriptor], predicate: predicate)
    }

    func fetchAccounts(lastLoginBetween startDate: Date, and endDate: Date) -> [UserAccount] {
        let predicate = NSPredicate(
            format: "lastLoginAt >= %@ AND lastLoginAt <= %@",
            startDate as CVarArg,
            endDate as CVarArg
        )
        let sortDescriptor = NSSortDescriptor(key: "lastLoginAt", ascending: false)
        return fetch(sortedBy: [sortDescriptor], predicate: predicate)
    }

    func getPreferences(for account: UserAccount) -> [String: Any]? {
        guard let preferencesString = account.preferences,
              let data = preferencesString.data(using: .utf8) else {
            return nil
        }

        return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    }

    func setPreferences(for account: UserAccount, preferences: [String: Any]) async throws {
        let data = try JSONSerialization.data(withJSONObject: preferences)
        account.preferences = String(data: data, encoding: .utf8)

        try await PersistenceController.shared.saveContext(context)
    }

    func updatePreference(for account: UserAccount, key: String, value: Any) async throws {
        var preferences = getPreferences(for: account) ?? [:]
        preferences[key] = value

        try await setPreferences(for: account, preferences: preferences)
    }

    func removePreference(for account: UserAccount, key: String) async throws {
        var preferences = getPreferences(for: account) ?? [:]
        preferences.removeValue(forKey: key)

        try await setPreferences(for: account, preferences: preferences)
    }

    func getTotalAccountCount() -> Int {
        return fetchAll().count
    }

    func getActiveAccountCount(lastDays days: Int) -> Int {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) ?? endDate

        return fetchAccounts(lastLoginBetween: startDate, and: endDate).count
    }

    func fetchNewAccounts(lastDays days: Int) -> [UserAccount] {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) ?? endDate

        return fetchAccounts(registeredBetween: startDate, and: endDate)
    }

    func isEmailExists(_ email: String) -> Bool {
        return fetchUserAccount(by: email) != nil
    }

    func isUsernameExists(_ username: String) -> Bool {
        return fetchUserAccount(byUsername: username) != nil
    }

    func getDaysSinceRegistration(for account: UserAccount) -> Int {
        guard let registeredAt = account.registeredAt else { return 0 }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: registeredAt, to: Date())
        return components.day ?? 0
    }

    func getDaysSinceLastLogin(for account: UserAccount) -> Int? {
        guard let lastLoginAt = account.lastLoginAt else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: lastLoginAt, to: Date())
        return components.day
    }
}
