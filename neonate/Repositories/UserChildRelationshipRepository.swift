import Foundation
import CoreData
import Combine

class UserChildRelationshipRepository: BaseRepository<UserChildRelationship> {

    /// Create a relationship between user and child
    func createRelationship(
        userId: UUID,
        childId: UUID,
        role: String = "owner"
    ) async throws -> UserChildRelationship {
        // Check if relationship already exists
        if let existing = fetchRelationship(userId: userId, childId: childId) {
            return existing
        }

        let relationship = create()
        relationship.id = UUID()
        relationship.userId = userId
        relationship.childId = childId
        relationship.role = role
        relationship.addedAt = Date()

        try await PersistenceController.shared.saveContext(context)
        return relationship
    }

    /// Fetch relationship by userId and childId
    func fetchRelationship(userId: UUID, childId: UUID) -> UserChildRelationship? {
        let predicate = NSPredicate(
            format: "userId == %@ AND childId == %@",
            userId as CVarArg,
            childId as CVarArg
        )
        return fetch(with: predicate).first
    }

    /// Fetch all children IDs for a user
    func fetchChildrenIds(for userId: UUID) -> [UUID] {
        let predicate = NSPredicate(format: "userId == %@", userId as CVarArg)
        let relationships = fetch(with: predicate)
        return relationships.compactMap { $0.childId }
    }

    /// Fetch all user IDs for a child
    func fetchUserIds(for childId: UUID) -> [UUID] {
        let predicate = NSPredicate(format: "childId == %@", childId as CVarArg)
        let relationships = fetch(with: predicate)
        return relationships.compactMap { $0.userId }
    }

    /// Fetch all relationships for a user
    func fetchRelationships(for userId: UUID) -> [UserChildRelationship] {
        let predicate = NSPredicate(format: "userId == %@", userId as CVarArg)
        let sortDescriptor = NSSortDescriptor(key: "addedAt", ascending: false)
        return fetch(sortedBy: [sortDescriptor], predicate: predicate)
    }

    /// Check if user has access to child
    func hasAccess(userId: UUID, childId: UUID) -> Bool {
        return fetchRelationship(userId: userId, childId: childId) != nil
    }

    /// Delete relationship
    func deleteRelationship(userId: UUID, childId: UUID) async throws {
        guard let relationship = fetchRelationship(userId: userId, childId: childId) else {
            return
        }
        delete(relationship)
        try await PersistenceController.shared.saveContext(context)
    }

    /// Update role
    func updateRole(userId: UUID, childId: UUID, role: String) async throws {
        guard let relationship = fetchRelationship(userId: userId, childId: childId) else {
            throw NSError(
                domain: "UserChildRelationshipRepository",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "Relationship not found"]
            )
        }
        relationship.role = role
        try await PersistenceController.shared.saveContext(context)
    }

    /// Get role for user-child pair
    func getRole(userId: UUID, childId: UUID) -> String? {
        return fetchRelationship(userId: userId, childId: childId)?.role
    }

    /// Check if user is owner of child
    func isOwner(userId: UUID, childId: UUID) -> Bool {
        return getRole(userId: userId, childId: childId) == "owner"
    }
}
