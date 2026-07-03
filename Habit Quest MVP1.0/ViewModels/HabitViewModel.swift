import Foundation
import CoreData
import Combine

final class HabitViewModel: ObservableObject {
	@Published var habits: [Habit] = []
	@Published var errorMessage: String?

	private let manager: CoreDataManaging
	private var cancellables: Set<AnyCancellable> = []

	init(manager: CoreDataManaging = CoreDataManager.shared) {
		self.manager = manager
	}

	func loadActiveHabits() {
		let request: NSFetchRequest<Habit> = Habit.fetchRequest()
		request.predicate = NSPredicate(format: "isActive == YES")
		request.sortDescriptors = [NSSortDescriptor(key: "createdDate", ascending: false)]
		do {
			habits = try manager.fetch(request)
		} catch {
			errorMessage = error.localizedDescription
		}
	}

	func addHabit(name: String, attribute: AttributeType, estimatedMinutes: Int) {
		guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
			errorMessage = AppError.invalidInput("习惯名称不能为空").localizedDescription
			return
		}
		let habit: Habit = manager.create(Habit.self)
		habit.id = UUID()
		habit.name = name
		habit.attributeType = attribute.rawValue
		habit.estimatedMinutes = Int64(estimatedMinutes)
		habit.createdDate = Date()
		habit.isActive = true
		do {
			try manager.save()
			loadActiveHabits()
		} catch {
			errorMessage = AppError.saveFailed.localizedDescription
		}
	}

	func updateHabit(_ habit: Habit, name: String, attribute: AttributeType, estimatedMinutes: Int) {
		habit.name = name
		habit.attributeType = attribute.rawValue
		habit.estimatedMinutes = Int64(estimatedMinutes)
		do {
			try manager.save()
			loadActiveHabits()
		} catch {
			errorMessage = AppError.saveFailed.localizedDescription
		}
	}

	func softDelete(_ habit: Habit) {
		habit.isActive = false
		do {
			try manager.save()
			loadActiveHabits()
		} catch {
			errorMessage = AppError.deleteFailed.localizedDescription
		}
	}
}
