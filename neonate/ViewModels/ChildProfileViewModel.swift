import Foundation
import SwiftUI
import CoreData
import Combine

@MainActor
class ChildProfileViewModel: ObservableObject {

    @Published var children: [ChildProfile] = []

    @Published var selectedChild: ChildProfile?

    @Published var isLoading: Bool = false

    @Published var error: Error?

    @Published var showError: Bool = false

    private let repository: ChildProfileRepository
    private var cancellables = Set<AnyCancellable>()

    private let selectedChildIdKey = "selectedChildId"

    /// Current user ID for filtering children
    var currentUserId: UUID?

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.repository = ChildProfileRepository(context: context)
    }

    /// Set current user and load their children
    func setCurrentUser(userId: UUID) {
        // Check if user changed
        let userChanged = self.currentUserId != userId

        self.currentUserId = userId

        // Clear selected child if user changed
        if userChanged {
            selectedChild = nil
        }

        loadChildren()
        loadSelectedChild()

        // Perform migration if needed
        Task {
            await DataMigrationService.shared.performMigrationIfNeeded(userId: userId)
            // Reload children after migration
            loadChildren()
            // Reload selected child after migration (might have new children)
            loadSelectedChild()
        }
    }

    func loadChildren() {
        isLoading = true
        if let userId = currentUserId {
            children = repository.fetchChildren(for: userId, ascending: false)
        } else {
            // Fallback: load all children (for backwards compatibility during migration)
            children = repository.fetchAllChildren(ascending: false)
        }
        isLoading = false
    }

    func addChild(
        name: String,
        dateOfBirth: Date,
        gender: String? = nil,
        photoData: Data? = nil,
        birthWeight: Double? = nil,
        birthHeight: Double? = nil,
        notes: String? = nil
    ) async {
        isLoading = true

        do {
            let child = try await repository.createChildProfile(
                name: name,
                dateOfBirth: dateOfBirth,
                gender: gender,
                photoData: photoData,
                birthWeight: birthWeight,
                birthHeight: birthHeight,
                notes: notes,
                userId: currentUserId  // Pass current user ID
            )

            loadChildren()

            selectChild(child)

        } catch {
            self.error = error
            self.showError = true
        }

        isLoading = false
    }

    func updateChild(
        _ child: ChildProfile,
        name: String? = nil,
        dateOfBirth: Date? = nil,
        gender: String? = nil,
        photoData: Data? = nil,
        birthWeight: Double? = nil,
        birthHeight: Double? = nil,
        notes: String? = nil
    ) async {
        isLoading = true

        do {
            try await repository.updateChildProfile(
                child,
                name: name,
                dateOfBirth: dateOfBirth,
                gender: gender,
                photoData: photoData,
                birthWeight: birthWeight,
                birthHeight: birthHeight,
                notes: notes
            )

            loadChildren()

            // Обновляем selectedChild на обновленный объект из массива
            if let childId = child.id,
               let updatedChild = children.first(where: { $0.id == childId }) {
                selectedChild = updatedChild
            }

        } catch {
            self.error = error
            self.showError = true
        }

        isLoading = false
    }

    func deleteChild(_ child: ChildProfile) async {
        isLoading = true

        do {

            if selectedChild?.id == child.id {
                selectedChild = nil
                UserDefaults.standard.removeObject(forKey: selectedChildIdKey)
            }

            try await repository.deleteChildProfile(child)
            loadChildren()

            if selectedChild == nil, let firstChild = children.first {
                selectChild(firstChild)
            }

        } catch {
            self.error = error
            self.showError = true
        }

        isLoading = false
    }

    func selectChild(_ child: ChildProfile) {
        selectedChild = child

        if let childId = child.id {
            UserDefaults.standard.set(childId.uuidString, forKey: selectedChildIdKey)
        }
    }

    func getAgeInDays(for child: ChildProfile) -> Int {
        return repository.getAgeInDays(for: child)
    }

    func getAgeInMonths(for child: ChildProfile) -> Int {
        return repository.getAgeInMonths(for: child)
    }

    func getFormattedAge(for child: ChildProfile) -> String {
        let months = getAgeInMonths(for: child)
        let days = getAgeInDays(for: child)

        if months < 1 {
            return "\(days) \(String(localized: "age_days_short"))"
        } else if months < 12 {
            let remainingDays = days - (months * 30)
            return "\(months) \(String(localized: "age_months_short")) \(remainingDays) \(String(localized: "age_days_short"))"
        } else {
            let years = months / 12
            let remainingMonths = months % 12
            return "\(years) \(String(localized: "age_years_short")) \(remainingMonths) \(String(localized: "age_months_short"))"
        }
    }

    func getEventsCount(for child: ChildProfile) -> [String: Int] {
        return repository.getTotalEventsCount(for: child)
    }

    private func loadSelectedChild() {
        guard let savedIdString = UserDefaults.standard.string(forKey: selectedChildIdKey),
              let savedId = UUID(uuidString: savedIdString) else {

            selectedChild = children.first
            return
        }

        // Check if user has access to this child
        if let userId = currentUserId {
            if repository.hasAccess(userId: userId, childId: savedId),
               let child = repository.fetchChildProfile(by: savedId) {
                selectedChild = child
                return
            }
        } else {
            // Fallback for backwards compatibility
            if let child = repository.fetchChildProfile(by: savedId) {
                selectedChild = child
                return
            }
        }

        // Child not found or no access - select first available child
        selectedChild = children.first
    }
}
