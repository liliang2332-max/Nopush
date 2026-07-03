import CoreData

final class PersistenceController {
	static let shared = PersistenceController()

	let container: NSPersistentContainer

	private init(inMemory: Bool = false) {
		container = NSPersistentContainer(name: "HabitQuest")

		// WAL 模式与不备份到 iCloud
		if let storeDescription = container.persistentStoreDescriptions.first {
			storeDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
			storeDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
			storeDescription.setOption("-wal" as NSString, forKey: NSSQLitePragmasOption)
			storeDescription.setOption(true as NSNumber, forKey: NSPersistentStoreFileProtectionKey)
		}

		if inMemory {
			container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
		}

		container.loadPersistentStores { _, error in
			if let error = error as NSError? {
				fatalError("Unresolved error: \(error), \(error.userInfo)")
			}
		}

		container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
		container.viewContext.automaticallyMergesChangesFromParent = true
	}

	func saveContext() {
		let context = container.viewContext
		guard context.hasChanges else { return }
		do {
			try context.save()
		} catch {
			let nsError = error as NSError
			print("Core Data save error: \(nsError), \(nsError.userInfo)")
		}
	}
}
