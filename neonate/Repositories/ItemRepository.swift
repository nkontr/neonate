import Foundation
import CoreData

class ItemRepository: BaseRepository<Item> {

    func fetchAllSortedByDate(ascending: Bool = true) -> [Item] {
        let sortDescriptor = NSSortDescriptor(keyPath: \Item.timestamp, ascending: ascending)
        return fetch(sortedBy: [sortDescriptor])
    }

    func fetchItems(for date: Date) -> [Item] {
        guard let startOfDay = date.startOfDay as Date?,
              let endOfDay = date.endOfDay as Date? else {
            return []
        }

        let predicate = NSPredicate(
            format: "timestamp >= %@ AND timestamp <= %@",
            startOfDay as NSDate,
            endOfDay as NSDate
        )

        return fetch(with: predicate)
    }

    func fetchTodayItems() -> [Item] {
        return fetchItems(for: Date())
    }

    func deleteOldItems(daysToKeep: Int) {
        guard let cutoffDate = Calendar.current.date(byAdding: .day, value: -daysToKeep, to: Date()) else {
            return
        }

        let predicate = NSPredicate(format: "timestamp < %@", cutoffDate as NSDate)
        let itemsToDelete = fetch(with: predicate)

        itemsToDelete.forEach { delete($0) }

        do {
            try save()
        } catch {
            print("Ошибка при удалении старых элементов: \(error)")
        }
    }
}
