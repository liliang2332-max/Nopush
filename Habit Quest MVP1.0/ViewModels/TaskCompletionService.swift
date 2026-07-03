import Foundation
import CoreData

final class TaskCompletionService {
	private let manager: CoreDataManaging
	private let ratingRules = RatingRules()
	private let pricing = DelayPricingService()

	init(manager: CoreDataManaging = CoreDataManager.shared) {
		self.manager = manager
	}

	/// 完成任务后计算评价与经验值，并写入 TaskRecord + 更新 UserProfile
	func finalizeTask(record: TaskRecord, actualMinutes: Int) throws {
		let estimated = Int(record.estimatedMinutes)
		let original = ratingRules.rating(for: actualMinutes, estimatedMinutes: estimated)
		let final = Rating(rawValue: record.rating ?? original.rawValue) ?? original
		let exp = ratingRules.expForRating(final)

		record.actualMinutes = Int64(actualMinutes)
		record.originalRating = original.rawValue
		record.rating = final.rawValue
		record.expGained = Int64(exp)
		record.completed = true
		record.endTime = Date()

		try manager.save()

		let userVM = UserProfileViewModel(manager: manager)
		try userVM.addEXP(exp)
		// 属性加点策略可根据 rating 与 attributeType 权重调整，这里先简单 +exp/5
		let points = max(1, exp / 5)
		let type = AttributeType(rawValue: record.attributeType ?? "strength") ?? .strength
		try userVM.addAttributePoints(type, points: points)
	}

	/// 购买延时包时，记录历史并降级评价占位（实际降级在结算时以 record.rating 为准）
	func buyDelayPackage(for record: TaskRecord, dailySequence: Int) throws -> Int {
		let cost = pricing.priceForDailySequence(dailySequence)
		let userVM = UserProfileViewModel(manager: manager)
		try userVM.spendEXP(cost)

		record.delayPackagesUsed += 1
		// 预降级标记（若已有 rating 则降一级），最终以 finalizeTask 的 final 为准
		let current = Rating(rawValue: record.rating ?? "S") ?? .S
		record.rating = ratingRules.downgraded(from: current).rawValue

		let history: DelayPackageHistory = manager.create(DelayPackageHistory.self)
		history.id = UUID()
		history.taskRecordId = record.id
		history.purchaseTime = Date()
		history.cost = Int64(cost)
		history.delayMinutes = 15
		history.dailySequenceNumber = Int64(dailySequence)

		try manager.save()
		return cost
	}
}
