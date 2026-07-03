import Foundation
import CoreData

// 功能解锁管理器
class FeatureUnlockManager {
    static let shared = FeatureUnlockManager()
    
    private let context = PersistenceController.shared.container.viewContext
    
    private init() {}
    
    // 获取用户当前等级
    func getCurrentLevel() -> Int {
        guard let profile = getUserProfile() else { return 1 }
        return Int(profile.value(forKey: "currentLevel") as? Int32 ?? 1)
    }
    
    // 检查功能是否已解锁
    func isFeatureUnlocked(_ feature: UnlockableFeature) -> Bool {
        let currentLevel = getCurrentLevel()
        return currentLevel >= feature.requiredLevel
    }
    
    // 检查功能是否已解锁（兼容方法）
    func isUnlocked(_ feature: UnlockableFeature) -> Bool {
        return isFeatureUnlocked(feature)
    }
    
    // 获取所有已解锁的功能
    func getUnlockedFeatures() -> [UnlockableFeature] {
        let currentLevel = getCurrentLevel()
        return UnlockableFeature.allCases.filter { $0.requiredLevel <= currentLevel }
    }
    
    // 获取下一级将解锁的功能
    func getNextLevelFeatures(currentLevel: Int) -> [UnlockableFeature] {
        let nextLevel = currentLevel + 1
        return UnlockableFeature.allCases.filter { $0.requiredLevel == nextLevel }
    }
    
    // 升级并解锁新功能
    func levelUp(to newLevel: Int) -> [UnlockableFeature] {
        guard let profile = getUserProfile() else { return [] }
        
        profile.setValue(Int32(newLevel), forKey: "currentLevel")
        
        do {
            try context.save()
            print("✅ 升级到 Lv\(newLevel)")
        } catch {
            print("❌ 升级失败: \(error)")
        }
        
        return getNextLevelFeatures(currentLevel: newLevel - 1)
    }
    
    // 记录锁定功能点击
    func logLockedFeatureClick(feature: UnlockableFeature) {
        print("🔒 用户尝试访问未解锁功能: \(feature.rawValue)")
        print("   需要等级: Lv\(feature.requiredLevel)")
        print("   当前等级: Lv\(getCurrentLevel())")
    }
    
    // 批量解锁功能（升级时调用）
    func featuresUnlocked(for level: Int) -> [UnlockableFeature] {
        return UnlockableFeature.allCases.filter { $0.requiredLevel == level }
    }
    
    // 记录解锁事件
    func logUnlockEvent(features: [UnlockableFeature]) {
        for feature in features {
            print("🎉 解锁新功能: \(feature.rawValue)")
        }
    }
    
    private func getUserProfile() -> NSManagedObject? {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "UserProfile")
        request.fetchLimit = 1
        
        do {
            let results = try context.fetch(request)
            return results.first as? NSManagedObject
        } catch {
            print("获取用户档案失败: \(error)")
            return nil
        }
    }
}
