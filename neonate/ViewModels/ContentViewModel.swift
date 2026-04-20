import Foundation
import CoreData
import Combine

class ContentViewModel: ObservableObject {

    @Published var items: [Item] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let repository: ItemRepository
    private var cancellables = Set<AnyCancellable>()

    init(context: NSManagedObjectContext) {
        self.repository = ItemRepository(context: context)
        loadItems()
    }

    func loadItems() {
        isLoading = true
        items = repository.fetchAllSortedByDate(ascending: true)
        isLoading = false
    }

    func addItem() {
        let newItem = repository.create()
        newItem.timestamp = Date()

        do {
            try repository.save()
            loadItems()
        } catch {
            errorMessage = "Ошибка при сохранении: \(error.localizedDescription)"
        }
    }

    func deleteItem(_ item: Item) {
        repository.delete(item)

        do {
            try repository.save()
            loadItems()
        } catch {
            errorMessage = "Ошибка при удалении: \(error.localizedDescription)"
        }
    }

    func deleteItems(at offsets: IndexSet) {
        offsets.map { items[$0] }.forEach { item in
            repository.delete(item)
        }

        do {
            try repository.save()
            loadItems()
        } catch {
            errorMessage = "Ошибка при удалении: \(error.localizedDescription)"
        }
    }

    func loadTodayItems() {
        isLoading = true
        items = repository.fetchTodayItems()
        isLoading = false
    }

    func clearError() {
        errorMessage = nil
    }
}
