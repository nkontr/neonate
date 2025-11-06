import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext

        let child = ChildProfile(context: viewContext)
        child.id = UUID()
        child.name = "Тестовый ребенок"
        child.dateOfBirth = Date().addingTimeInterval(-90 * 24 * 60 * 60)
        child.gender = "Мальчик"
        child.birthWeight = 3500.0
        child.birthHeight = 52.0
        child.createdAt = Date()

        for i in 0..<5 {
            let feeding = FeedingEvent(context: viewContext)
            feeding.id = UUID()
            feeding.timestamp = Date().addingTimeInterval(-Double(i * 3600))
            feeding.feedingType = i % 2 == 0 ? "Грудное" : "Бутылочка"
            feeding.duration = Int32(15 + i * 5)
            feeding.childId = child.id!
            feeding.child = child
        }

        for i in 0..<3 {
            let sleep = SleepEvent(context: viewContext)
            sleep.id = UUID()
            sleep.startTime = Date().addingTimeInterval(-Double(i * 7200))
            sleep.endTime = Date().addingTimeInterval(-Double(i * 7200 - 3600))
            sleep.duration = 60
            sleep.quality = "Хорошо"
            sleep.childId = child.id!
            sleep.child = child
        }

        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    var backgroundContext: NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "neonate")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        } else {

            let description = container.persistentStoreDescriptions.first
            description?.shouldMigrateStoreAutomatically = true
            description?.shouldInferMappingModelAutomatically = true
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {

                print("⚠️ CoreData error: \(error), \(error.userInfo)")

                if error.code == 134110 {
                    print("🔄 Migration error detected. Deleting old database...")
                    if let storeURL = storeDescription.url {
                        try? FileManager.default.removeItem(at: storeURL)

                        print("⚠️ Database deleted. Please restart the app.")
                    }
                }

                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
    }

    func newChildContext(concurrencyType: NSManagedObjectContextConcurrencyType = .mainQueueConcurrencyType) -> NSManagedObjectContext {
        let context = NSManagedObjectContext(concurrencyType: concurrencyType)
        context.parent = container.viewContext
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }

    func batchDelete(entityName: String, predicate: NSPredicate? = nil) async throws {
        let context = backgroundContext

        try await context.perform {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            fetchRequest.predicate = predicate

            let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            batchDeleteRequest.resultType = .resultTypeObjectIDs

            let result = try context.execute(batchDeleteRequest) as? NSBatchDeleteResult

            guard let objectIDs = result?.result as? [NSManagedObjectID] else { return }

            let changes = [NSDeletedObjectsKey: objectIDs]
            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [context, self.container.viewContext])
        }
    }

    func batchUpdate(entityName: String, propertiesToUpdate: [String: Any], predicate: NSPredicate? = nil) async throws {
        let context = backgroundContext

        try await context.perform {
            let batchUpdateRequest = NSBatchUpdateRequest(entityName: entityName)
            batchUpdateRequest.propertiesToUpdate = propertiesToUpdate
            batchUpdateRequest.predicate = predicate
            batchUpdateRequest.resultType = .updatedObjectIDsResultType

            let result = try context.execute(batchUpdateRequest) as? NSBatchUpdateResult

            guard let objectIDs = result?.result as? [NSManagedObjectID] else { return }

            let changes = [NSUpdatedObjectsKey: objectIDs]
            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [context, self.container.viewContext])
        }
    }

    func saveContext(_ context: NSManagedObjectContext) async throws {
        guard context.hasChanges else { return }

        try await context.perform {
            try context.save()

            if let parent = context.parent {
                try parent.performAndWait {
                    if parent.hasChanges {
                        try parent.save()
                    }
                }
            }
        }
    }

    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) throws -> Void) async throws {
        let context = backgroundContext

        try await context.perform {
            try block(context)

            if context.hasChanges {
                try context.save()
            }
        }
    }
}
