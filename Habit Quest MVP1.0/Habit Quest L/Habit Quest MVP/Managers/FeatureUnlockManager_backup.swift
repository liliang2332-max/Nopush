import Foundation
import CoreData

// 可解锁功能枚举
enum UnlockableFeature: String, CaseIterable, Hashable {
    case delayPackage = "延时包购买"
    case timeCoinAdvanced = "时间币高级操作"
    case advancedStats = "高级统计趋势"
    
    var requiredLevel: Int {
        switch self {
        case .delayPackage: return 2
        case .timeCoinAdvanced: return 3
        case .advancedStats: return 4
        }
    }
    
    var icon: String {
        switch self {
        case .delayPackage: return "clock.badge.plus"
        case .timeCoinAdvanced: return "timer"
        case .advancedStats: return "chart.line.uptrend.xyaxis"
        }
    }
    
    var description: String {
        switch self {
        case .delayPackage: return "购买延时包延长任务时间"
        case .timeCoinAdvanced: return "使用时间币暂停或调整任务"
        case .advancedStats: return "查看四维属性趋势图与详细数据"
        }
    }
}

// 功能解锁管理器
class FeatureUnlockManager {
    static let shared = FeatureUnlockManager()
    private let context: NSManagedObjectContext
    
    private init() {
        self.context = PersistenceController.shared.container.viewContext
    }
    
    // MARK: - 检查功能是否解锁
    func isUnlocked(_ feature: UnlockableFeature) -> Bool {
        let currentLevel = getCurrentLevel()
        return currentLevel >= feature.requiredLevel
    }
    
    // MARK: - 获取当前等级
    func getCurrentLevel() -> Int {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "UserProfile")
        do {
            if let results = try context.fetch(request) as? [NSManagedObject],
               let profile = results.first {
                return (profile.value(forKey: "level") as? Int) ?? 1
            }
        } catch {
            print("Failed to fetch user level: \(error)")
        }
        return 1
    }
    
    // MARK: - 获取某等级解锁的所有功能
    func featuresUnlockedAt(level: Int) -> [UnlockableFeature] {
        return UnlockableFeature.allCases.filter { $0.requiredLevel == level }
    }
    
    // MARK: - 获取下一个待解锁的功能
    func nextLockedFeature() -> UnlockableFeature? {
        let currentLevel = getCurrentLevel()
        return UnlockableFeature.allCases.first { $0.requiredLevel > currentLevel }
    }
    
    // MARK: - 记录解锁事件（埋点）
    func logUnlockEvent(feature: UnlockableFeature) {
        print("📊 [Analytics] Feature Unlocked: \(feature.rawValue) at level \(feature.requiredLevel)")
        // 可扩展：发送到分析平台
    }
    
    // MARK: - 记录点击锁定功能事件（埋点）
    func logLockedFeatureClick(feature: UnlockableFeature) {
        print("📊 [Analytics] Locked Feature Clicked: \(feature.rawValue), Required Level: \(feature.requiredLevel)")
        // 可扩展：记录用户对特定功能的兴趣
    }
}

