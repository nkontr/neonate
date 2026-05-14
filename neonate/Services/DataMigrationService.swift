import Foundation
import CoreData

class DataMigrationService {

    static let shared = DataMigrationService()
    private let context: NSManagedObjectContext
    private let migrationCompletedKey = "userChildRelationshipMigrationCompleted"

    private init() {
        self.context = PersistenceController.shared.container.viewContext
    }

    /// Check if migration has been completed before
    private var isMigrationCompleted: Bool {
        get { UserDefaults.standard.bool(forKey: migrationCompletedKey) }
        set { UserDefaults.standard.set(newValue, forKey: migrationCompletedKey) }
    }

    /// Migrate existing ORPHANED children to be owned by current user
    /// Only migrates children that have NO owners at all
    func migrateChildrenToUser(userId: UUID) async throws {
        print("🔄 Starting data migration: linking ORPHANED children to user \(userId)")

        let relationshipRepo = UserChildRelationshipRepository(context: context)
        let childRepo = ChildProfileRepository(context: context)

        // Fetch all children
        let allChildren = childRepo.fetchAllChildren()
        print("📊 Found \(allChildren.count) children in database")

        var migratedCount = 0
        var skippedCount = 0

        for child in allChildren {
            guard let childId = child.id else {
                print("⚠️ Skipping child without ID")
                continue
            }

            // Check if child has ANY owners
            let ownerIds = relationshipRepo.fetchUserIds(for: childId)

            if !ownerIds.isEmpty {
                // Child already has owner(s) - skip
                print("⏭️  Child \(child.name ?? "unnamed") already has owner(s): \(ownerIds.count)")
                skippedCount += 1
                continue
            }

            // Child is orphaned - assign to current user
            do {
                _ = try await relationshipRepo.createRelationship(
                    userId: userId,
                    childId: childId,
                    role: "owner"
                )
                print("✅ Linked orphaned child \(child.name ?? "unnamed") to user")
                migratedCount += 1
            } catch {
                print("❌ Failed to link child \(child.name ?? "unnamed"): \(error.localizedDescription)")
            }
        }

        print("✨ Migration complete: \(migratedCount) orphaned children linked, \(skippedCount) already owned")
    }

    /// Check if migration is needed
    func needsMigration(userId: UUID) -> Bool {
        let relationshipRepo = UserChildRelationshipRepository(context: context)
        let childRepo = ChildProfileRepository(context: context)

        let allChildren = childRepo.fetchAllChildren()

        // Check if there are any orphaned children (without owners)
        for child in allChildren {
            guard let childId = child.id else { continue }
            let ownerIds = relationshipRepo.fetchUserIds(for: childId)
            if ownerIds.isEmpty {
                // Found at least one orphaned child - migration needed
                return true
            }
        }

        // No orphaned children found
        return false
    }

    /// Perform migration check on app launch
    func performMigrationIfNeeded(userId: UUID) async {
        // If migration was already completed globally, skip
        if isMigrationCompleted {
            print("ℹ️  Global migration already completed - skipping")
            return
        }

        guard needsMigration(userId: userId) else {
            print("ℹ️  No orphaned children found - marking migration as completed")
            isMigrationCompleted = true
            return
        }

        print("⚡️ Migration needed - starting automatic migration")
        do {
            try await migrateChildrenToUser(userId: userId)
            isMigrationCompleted = true
            print("✅ Migration completed and marked as done")
        } catch {
            print("❌ Migration failed: \(error.localizedDescription)")
        }
    }

    /// Assign all orphaned children to a user
    func assignOrphanedChildren(to userId: UUID) async throws {
        print("🔍 Looking for orphaned children...")

        let relationshipRepo = UserChildRelationshipRepository(context: context)
        let childRepo = ChildProfileRepository(context: context)

        let allChildren = childRepo.fetchAllChildren()
        var orphanedCount = 0

        for child in allChildren {
            guard let childId = child.id else { continue }

            // Check if child has any owners
            let ownerIds = relationshipRepo.fetchUserIds(for: childId)
            if ownerIds.isEmpty {
                // Child is orphaned - assign to user
                _ = try await relationshipRepo.createRelationship(
                    userId: userId,
                    childId: childId,
                    role: "owner"
                )
                print("🆘 Assigned orphaned child \(child.name ?? "unnamed") to user")
                orphanedCount += 1
            }
        }

        print("✅ Assigned \(orphanedCount) orphaned children")
    }
}
