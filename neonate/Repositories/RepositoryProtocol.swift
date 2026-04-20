import Foundation
import CoreData
import Combine

protocol RepositoryProtocol {
    associatedtype Entity: NSManagedObject

    func create() -> Entity

    func save() throws

    func delete(_ entity: Entity)

    func fetchAll() -> [Entity]

    func fetch(with predicate: NSPredicate) -> [Entity]
}

class BaseRepository<T: NSManagedObject>: RepositoryProtocol {
    typealias Entity = T

    let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func create() -> T {
        return T(context: context)
    }

    func save() throws {
        if context.hasChanges {
            try context.save()
        }
    }

    func delete(_ entity: T) {
        context.delete(entity)
    }

    func fetchAll() -> [T] {
        let fetchRequest = T.fetchRequest()

        do {
            guard let results = try context.fetch(fetchRequest) as? [T] else {
                return []
            }
            return results
        } catch {
            print("Ошибка при загрузке данных: \(error)")
            return []
        }
    }

    func fetch(with predicate: NSPredicate) -> [T] {
        let fetchRequest = T.fetchRequest()
        fetchRequest.predicate = predicate

        do {
            guard let results = try context.fetch(fetchRequest) as? [T] else {
                return []
            }
            return results
        } catch {
            print("Ошибка при загрузке данных с предикатом: \(error)")
            return []
        }
    }

    func fetch(sortedBy sortDescriptors: [NSSortDescriptor], predicate: NSPredicate? = nil) -> [T] {
        let fetchRequest = T.fetchRequest()
        fetchRequest.sortDescriptors = sortDescriptors
        fetchRequest.predicate = predicate

        do {
            guard let results = try context.fetch(fetchRequest) as? [T] else {
                return []
            }
            return results
        } catch {
            print("Ошибка при загрузке отсортированных данных: \(error)")
            return []
        }
    }
}
