import CoreData
import Foundation

protocol CoreDataManaging {
	var viewContext: NSManagedObjectContext { get }
	func create<T: NSManagedObject>(_ type: T.Type) -> T
	func fetch<T: NSManagedObject>(_ request: NSFetchRequest<T>) throws -> [T]
	func delete(_ object: NSManagedObject)
	func save() throws
}

final class CoreDataManager: CoreDataManaging {
	static let shared = CoreDataManager()
	let container: NSPersistentContainer

	init(container: NSPersistentContainer = PersistenceController.shared.container) {
		self.container = container
	}

	var viewContext: NSManagedObjectContext { container.viewContext }

	func create<T: NSManagedObject>(_ type: T.Type) -> T {
		return T(context: viewContext)
	}

	func fetch<T: NSManagedObject>(_ request: NSFetchRequest<T>) throws -> [T] {
		return try viewContext.fetch(request)
	}

	func delete(_ object: NSManagedObject) {
		viewContext.delete(object)
	}

	func save() throws {
		if viewContext.hasChanges {
			try viewContext.save()
		}
	}
}
