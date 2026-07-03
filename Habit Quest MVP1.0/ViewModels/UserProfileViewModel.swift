import Foundation
import CoreData

final class UserProfileViewModel: ObservableObject {
	@Published private(set) var currentEXP: Int = 0
	@Published private(set) var totalEXP: Int = 0
	@Published private(set) var attributes: [AttributeType: Int] = [.strength: 0, .intelligence: 0, .agility: 0, .charisma: 0]

	private let manager: CoreDataManaging

	init(manager: CoreDataManaging = CoreDataManager.shared) {
		self.manager = manager
		load()
	}

	private func load() {
		let request: NSFetchRequest<UserProfile> = UserProfile.fetchRequest()
		do {
			if let profile = try manager.fetch(request).first {
				bind(profile)
			} else {
				let p: UserProfile = manager.create(UserProfile.self)
				p.id = UUID()
				p.createdDate = Date()
				p.lastActiveDate = Date()
				try manager.save()
				bind(p)
			}
		} catch {
			// 静默失败：初始化阶段不影响运行
		}
	}

	private func bind(_ p: UserProfile) {
		currentEXP = Int(p.currentEXP)
		totalEXP = Int(p.totalEXP)
		attributes[.strength] = Int(p.strengthPoints)
		attributes[.intelligence] = Int(p.intelligencePoints)
		attributes[.agility] = Int(p.agilityPoints)
		attributes[.charisma] = Int(p.charismaPoints)
	}

	func addEXP(_ value: Int) throws {
		let request: NSFetchRequest<UserProfile> = UserProfile.fetchRequest()
		guard let p = try manager.fetch(request).first else { throw AppError.dataNotFound }
		p.currentEXP += Int64(value)
		p.totalEXP += Int64(value)
		try manager.save()
		bind(p)
	}

	func spendEXP(_ value: Int) throws {
		let request: NSFetchRequest<UserProfile> = UserProfile.fetchRequest()
		guard let p = try manager.fetch(request).first else { throw AppError.dataNotFound }
		guard p.currentEXP >= Int64(value) else { throw AppError.insufficientEXP(current: Int(p.currentEXP), required: value) }
		p.currentEXP -= Int64(value)
		try manager.save()
		bind(p)
	}

	func addAttributePoints(_ type: AttributeType, points: Int) throws {
		let request: NSFetchRequest<UserProfile> = UserProfile.fetchRequest()
		guard let p = try manager.fetch(request).first else { throw AppError.dataNotFound }
		switch type {
		case .strength: p.strengthPoints += Int64(points)
		case .intelligence: p.intelligencePoints += Int64(points)
		case .agility: p.agilityPoints += Int64(points)
		case .charisma: p.charismaPoints += Int64(points)
		}
		try manager.save()
		bind(p)
	}
}
