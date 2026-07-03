import Foundation
import CoreData
import Combine

// 经验值管理ViewModel
class ExperienceViewModel: ObservableObject {
    @Published var currentEXP: Int = 0
    @Published var totalEXP: Int = 0
    @Published var level: Int = 1
    @Published var sBadgesThisLevel: Int = 0
    @Published var requiredEXPForCurrentLevel: Int = 100
    @Published var showExpChange: Bool = false
    @Published var expChangeAmount: Int = 0
    @Published var attributes: [AttributeType: Int] = [.strength: 0, .intelligence: 0, .agility: 0, .charisma: 0]
    @Published var showLevelUpModal: Bool = false
    @Published var levelUpInfo: (newLevel: Int, features: [UnlockableFeature]) = (1, [])
    
    private let context: NSManagedObjectContext
    private var cancellables = Set<AnyCancellable>()
    private let unlockManager = FeatureUnlockManager.shared
    
    init(context: NSManagedObjectContext) {
        self.context = context
        loadUserProfile()
        setupNotificationObservers()
    }
    
    // MARK: - Load Profile
    func loadUserProfile() {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "UserProfile")
        
        do {
            if let results = try context.fetch(request) as? [NSManagedObject],
               let profile = results.first {
                let exp = profile.value(forKey: "currentEXP") as? Int32 ?? 0
                let total = profile.value(forKey: "totalEXP") as? Int32 ?? 0
                let lv = profile.value(forKey: "currentLevel") as? Int32 ?? 1
                let badges = profile.value(forKey: "sBadgesThisLevel") as? Int32 ?? 0
                let required = Self.expRequired(for: Int(lv))
                let strength = profile.value(forKey: "strengthPoints") as? Int32 ?? 0
                let intelligence = profile.value(forKey: "intelligencePoints") as? Int32 ?? 0
                let agility = profile.value(forKey: "agilityPoints") as? Int32 ?? 0
                let charisma = profile.value(forKey: "charismaPoints") as? Int32 ?? 0
                
                DispatchQueue.main.async {
                    self.currentEXP = Int(exp)
                    self.totalEXP = Int(total)
                    self.level = Int(lv)
                    self.sBadgesThisLevel = Int(badges)
                    self.requiredEXPForCurrentLevel = required
                    self.attributes[.strength] = Int(strength)
                    self.attributes[.intelligence] = Int(intelligence)
                    self.attributes[.agility] = Int(agility)
                    self.attributes[.charisma] = Int(charisma)
                }
            }
        } catch {
            print("Failed to load user profile: \(error)")
        }
    }
    
    // MARK: - Setup Observers
    private func setupNotificationObservers() {
        NotificationCenter.default.publisher(for: .expChanged)
            .sink { [weak self] notification in
                if let change = notification.userInfo?["change"] as? Int {
                    self?.updateEXP(change: change)
                }
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave, object: context)
            .sink { [weak self] _ in
                self?.loadUserProfile()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .levelUp)
            .sink { [weak self] notification in
                if let newLevel = notification.userInfo?["newLevel"] as? Int {
                    self?.handleLevelUp(newLevel: newLevel)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Update EXP
    func updateEXP(change: Int) {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "UserProfile")
        
        do {
            if let results = try context.fetch(request) as? [NSManagedObject],
               let profile = results.first {
                
                let currentLevel = profile.value(forKey: "currentLevel") as? Int32 ?? 1
                let required = Self.expRequired(for: Int(currentLevel))
                let currentExpBefore = profile.value(forKey: "currentEXP") as? Int32 ?? 0
                let newCurrentEXP = min(required, Int(currentExpBefore) + change)
                let newTotalEXP = Int(profile.value(forKey: "totalEXP") as? Int32 ?? 0) + max(0, change)
                
                profile.setValue(Int32(newCurrentEXP), forKey: "currentEXP")
                profile.setValue(Int32(newTotalEXP), forKey: "totalEXP")
                
                try context.save()
                
                // 更新UI
                DispatchQueue.main.async {
                    self.currentEXP = newCurrentEXP
                    self.totalEXP = newTotalEXP
                    self.level = Int(currentLevel)
                    self.requiredEXPForCurrentLevel = required
                    
                    // 显示经验值变化动画
                    self.expChangeAmount = change
                    self.showExpChange = true
                    
                    // 3秒后隐藏
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        self.showExpChange = false
                    }
                }
            }
        } catch {
            print("Failed to update EXP: \(error)")
        }
    }
    
    // MARK: - Check Sufficient EXP
    func hasSufficientEXP(required: Int) -> Bool {
        return currentEXP >= required
    }

    // MARK: - Level Requirements
    static func expRequired(for level: Int) -> Int {
        let lv = max(1, level)
        let value = 100.0 * pow(Double(lv), 1.5)
        return Int(value.rounded())
    }
    
    // MARK: - Handle Level Up
    private func handleLevelUp(newLevel: Int) {
        print("📊 [Analytics] Level Up: \(newLevel - 1) → \(newLevel)")
        
        // ✅ 修复：使用正确的方法名
        let unlockedFeatures = unlockManager.featuresUnlocked(for: newLevel)
        
        // ✅ 修复：使用正确的方法
        unlockManager.logUnlockEvent(features: unlockedFeatures)
        
        // 显示升级弹窗
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.levelUpInfo = (newLevel, unlockedFeatures)
            self.showLevelUpModal = true
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let expChanged = Notification.Name("expChanged")
    static let attributeChanged = Notification.Name("attributeChanged")
    static let taskCompleted = Notification.Name("taskCompleted")
    static let levelUp = Notification.Name("levelUp")
}
