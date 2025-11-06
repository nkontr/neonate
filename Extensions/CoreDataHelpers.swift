import Foundation
import CoreData

extension NSManagedObjectContext {

    func performAndWait<T>(_ block: () throws -> T) throws -> T {
        var result: Result<T, Error>!

        performAndWait {
            result = Result { try block() }
        }

        return try result.get()
    }

    func saveIfNeeded() throws {
        guard hasChanges else { return }
        try save()
    }

    func createObject<T: NSManagedObject>() -> T {
        return T(context: self)
    }

    func countObjects<T>(for fetchRequest: NSFetchRequest<T>) -> Int {
        do {
            return try count(for: fetchRequest)
        } catch {
            print("Ошибка при подсчете объектов: \(error)")
            return 0
        }
    }

    func deleteAllObjects(entityName: String) throws {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        try execute(batchDeleteRequest)
    }

    func batchInsert(entityName: String, objects: [[String: Any]]) throws {
        let batchInsert = NSBatchInsertRequest(entityName: entityName, objects: objects)
        try execute(batchInsert)
    }
}

extension NSManagedObject {

    var isFault: Bool {
        return self.isFault
    }

    var entityName: String {
        return entity.name ?? String(describing: type(of: self))
    }

    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [:]

        for attribute in entity.attributesByName {
            let key = attribute.key
            if let value = value(forKey: key) {
                dict[key] = value
            }
        }

        return dict
    }

    func copy(to context: NSManagedObjectContext) -> NSManagedObject? {
        guard let entityName = entity.name else { return nil }

        let copy = NSEntityDescription.insertNewObject(forEntityName: entityName, into: context)

        for attribute in entity.attributesByName {
            let key = attribute.key
            if let value = value(forKey: key) {
                copy.setValue(value, forKey: key)
            }
        }

        return copy
    }
}

extension NSPredicate {

    static func byId(_ id: UUID) -> NSPredicate {
        return NSPredicate(format: "id == %@", id as CVarArg)
    }

    static func dateRange(key: String, from startDate: Date, to endDate: Date) -> NSPredicate {
        return NSPredicate(format: "%K >= %@ AND %K <= %@", key, startDate as CVarArg, key, endDate as CVarArg)
    }

    static func contains(key: String, text: String) -> NSPredicate {
        return NSPredicate(format: "%K CONTAINS[cd] %@", key, text)
    }

    static func and(_ predicates: [NSPredicate]) -> NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }

    static func or(_ predicates: [NSPredicate]) -> NSPredicate {
        return NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
    }
}

extension NSSortDescriptor {

    static func ascending(_ key: String) -> NSSortDescriptor {
        return NSSortDescriptor(key: key, ascending: true)
    }

    static func descending(_ key: String) -> NSSortDescriptor {
        return NSSortDescriptor(key: key, ascending: false)
    }
}

struct CoreDataUtilities {

    static func migrateStore(
        from sourceURL: URL,
        to destinationURL: URL,
        sourceModel: NSManagedObjectModel,
        destinationModel: NSManagedObjectModel
    ) throws {
        let mappingModel = NSMappingModel(
            from: nil,
            forSourceModel: sourceModel,
            destinationModel: destinationModel
        )

        let migrationManager = NSMigrationManager(
            sourceModel: sourceModel,
            destinationModel: destinationModel
        )

        try migrationManager.migrateStore(
            from: sourceURL,
            sourceType: NSSQLiteStoreType,
            options: nil,
            with: mappingModel,
            toDestinationURL: destinationURL,
            destinationType: NSSQLiteStoreType,
            destinationOptions: nil
        )
    }

    static func requiresMigration(storeURL: URL, for model: NSManagedObjectModel) -> Bool {
        do {
            let metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(
                ofType: NSSQLiteStoreType,
                at: storeURL,
                options: nil
            )

            return !model.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata)
        } catch {
            return false
        }
    }

    static func destroyStore(at storeURL: URL) throws {
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: NSManagedObjectModel())
        try coordinator.destroyPersistentStore(at: storeURL, ofType: NSSQLiteStoreType, options: nil)
    }

    static func getDatabaseSize(at storeURL: URL) -> Int64 {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: storeURL.path)
            return attributes[.size] as? Int64 ?? 0
        } catch {
            return 0
        }
    }

    static func formatDatabaseSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

extension NSError {

    var isMergeConflict: Bool {
        return domain == NSCocoaErrorDomain && code == NSManagedObjectMergeError
    }

    var isConstraintViolation: Bool {
        return domain == NSCocoaErrorDomain && code == NSValidationMultipleErrorsError
    }

    var isStoreNotFound: Bool {
        return domain == NSCocoaErrorDomain && code == NSPersistentStoreInvalidTypeError
    }
}
