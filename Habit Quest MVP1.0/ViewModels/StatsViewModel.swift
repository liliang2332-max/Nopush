import Foundation
import CoreData

struct WeeklyTrendPoint: Identifiable { let id = UUID(); let date: Date; let points: Int }

final class StatsViewModel: ObservableObject {
	@Published private(set) var todayCompletedCount: Int = 0
	@Published private(set) var currentStreakDays: Int = 0
	@Published private(set) var weeklyTrend: [WeeklyTrendPoint] = []

	private let manager: CoreDataManaging
	private let calendar = Calendar.current

	init(manager: CoreDataManaging = CoreDataManager.shared) {
		self.manager = manager
	}

	func reload() {
		loadTodayCompleted()
		loadCurrentStreak()
		loadWeeklyTrend()
	}

	private func loadTodayCompleted() {
		let request: NSFetchRequest<TaskRecord> = TaskRecord.fetchRequest()
		let start = calendar.startOfDay(for: Date())
		let end = calendar.date(byAdding: .day, value: 1, to: start)!
		request.predicate = NSPredicate(format: "completed == YES AND endTime >= %@ AND endTime < %@", start as NSDate, end as NSDate)
		do { todayCompletedCount = try manager.fetch(request).count } catch { todayCompletedCount = 0 }
	}

	private func loadCurrentStreak() {
		let request: NSFetchRequest<DailyStreak> = DailyStreak.fetchRequest()
		request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
		do {
			let records = try manager.fetch(request)
			currentStreakDays = computeStreakDays(from: records.map { $0.date ?? Date.distantPast })
		} catch { currentStreakDays = 0 }
	}

	private func computeStreakDays(from dates: [Date]) -> Int {
		guard !dates.isEmpty else { return 0 }
		var streak = 0
		var current = calendar.startOfDay(for: Date())
		let set = Set(dates.map { calendar.startOfDay(for: $0) })
		while set.contains(current) {
			streak += 1
			current = calendar.date(byAdding: .day, value: -1, to: current)!
		}
		return streak
	}

	private func loadWeeklyTrend() {
		let request: NSFetchRequest<DailyStreak> = DailyStreak.fetchRequest()
		let today = calendar.startOfDay(for: Date())
		let weekStart = calendar.date(byAdding: .day, value: -6, to: today)!
		request.predicate = NSPredicate(format: "date >= %@ AND date <= %@", weekStart as NSDate, today as NSDate)
		request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
		do {
			let records = try manager.fetch(request)
			weeklyTrend = records.map { WeeklyTrendPoint(date: $0.date ?? Date(), points: Int($0.totalAttributePoints)) }
		} catch { weeklyTrend = [] }
	}
}
