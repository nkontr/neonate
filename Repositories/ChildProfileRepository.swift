import Foundation
import CoreData
import Combine

class ChildProfileRepository: BaseRepository<ChildProfile> {

    func createChildProfile(
        name: String,
        dateOfBirth: Date,
        gender: String? = nil,
        photoData: Data? = nil,
        birthWeight: Double? = nil,
        birthHeight: Double? = nil,
        notes: String? = nil
    ) async throws -> ChildProfile {
        let child = create()
        child.id = UUID()
        child.name = name
        child.dateOfBirth = dateOfBirth
        child.gender = gender
        child.photoData = photoData
        child.birthWeight = birthWeight ?? 0.0
        child.birthHeight = birthHeight ?? 0.0
        child.notes = notes
        child.createdAt = Date()

        try await PersistenceController.shared.saveContext(context)
        return child
    }

    func updateChildProfile(
        _ child: ChildProfile,
        name: String? = nil,
        dateOfBirth: Date? = nil,
        gender: String? = nil,
        photoData: Data? = nil,
        birthWeight: Double? = nil,
        birthHeight: Double? = nil,
        notes: String? = nil
    ) async throws {
        if let name = name { child.name = name }
        if let dateOfBirth = dateOfBirth { child.dateOfBirth = dateOfBirth }
        if let gender = gender { child.gender = gender }
        if let photoData = photoData { child.photoData = photoData }
        if let birthWeight = birthWeight { child.birthWeight = birthWeight }
        if let birthHeight = birthHeight { child.birthHeight = birthHeight }
        if let notes = notes { child.notes = notes }

        try await PersistenceController.shared.saveContext(context)
    }

    func deleteChildProfile(_ child: ChildProfile) async throws {
        delete(child)
        try await PersistenceController.shared.saveContext(context)
    }

    func fetchChildProfile(by id: UUID) -> ChildProfile? {
        let predicate = NSPredicate(format: "id == %@", id as CVarArg)
        return fetch(with: predicate).first
    }

    func fetchAllChildren(ascending: Bool = false) -> [ChildProfile] {
        let sortDescriptor = NSSortDescriptor(key: "createdAt", ascending: ascending)
        return fetch(sortedBy: [sortDescriptor])
    }

    func searchChildren(by name: String) -> [ChildProfile] {
        let predicate = NSPredicate(format: "name CONTAINS[cd] %@", name)
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        return fetch(sortedBy: [sortDescriptor], predicate: predicate)
    }

    func fetchChildren(by gender: String) -> [ChildProfile] {
        let predicate = NSPredicate(format: "gender == %@", gender)
        let sortDescriptor = NSSortDescriptor(key: "dateOfBirth", ascending: false)
        return fetch(sortedBy: [sortDescriptor], predicate: predicate)
    }

    func fetchChildren(bornBetween startDate: Date, and endDate: Date) -> [ChildProfile] {
        let predicate = NSPredicate(format: "dateOfBirth >= %@ AND dateOfBirth <= %@", startDate as CVarArg, endDate as CVarArg)
        let sortDescriptor = NSSortDescriptor(key: "dateOfBirth", ascending: false)
        return fetch(sortedBy: [sortDescriptor], predicate: predicate)
    }

    func getChildrenCount() -> Int {
        return fetchAll().count
    }

    func getAgeInDays(for child: ChildProfile) -> Int {
        guard let dateOfBirth = child.dateOfBirth else { return 0 }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: dateOfBirth, to: Date())
        return components.day ?? 0
    }

    func getAgeInMonths(for child: ChildProfile) -> Int {
        guard let dateOfBirth = child.dateOfBirth else { return 0 }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month], from: dateOfBirth, to: Date())
        return components.month ?? 0
    }

    func getTotalEventsCount(for child: ChildProfile) -> [String: Int] {
        var counts: [String: Int] = [:]

        if let feedingEvents = child.feedingEvents as? Set<FeedingEvent> {
            counts["feeding"] = feedingEvents.count
        }

        if let sleepEvents = child.sleepEvents as? Set<SleepEvent> {
            counts["sleep"] = sleepEvents.count
        }

        if let diaperEvents = child.diaperEvents as? Set<DiaperEvent> {
            counts["diaper"] = diaperEvents.count
        }

        return counts
    }
}
