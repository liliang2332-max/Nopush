import Foundation
import CoreData

// 时间币管理器
class TimeCoinManager {
    private let context: NSManagedObjectContext
    private let weeklyAllocation = 5  // 每周发放5个
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    // 获取用户档案
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
    
    // 检查并重置时间币（每周一重置）
    func checkAndResetTimeCoins() {
        guard let profile = getUserProfile() else { return }
        
        let calendar = Calendar.current
        let now = Date()
        
        // 获取上次重置时间
        let lastReset = profile.value(forKey: "lastTimeCoinReset") as? Date
        
        // 判断是否需要重置
        var shouldReset = false
        
        if let lastReset = lastReset {
            // 检查是否跨周了
            let lastWeek = calendar.component(.weekOfYear, from: lastReset)
            let currentWeek = calendar.component(.weekOfYear, from: now)
            let lastYear = calendar.component(.year, from: lastReset)
            let currentYear = calendar.component(.year, from: now)
            
            shouldReset = (currentYear > lastYear) || (currentYear == lastYear && currentWeek > lastWeek)
        } else {
            // 第一次使用，需要初始化
            shouldReset = true
        }
        
        if shouldReset {
            profile.setValue(weeklyAllocation, forKey: "timeCoins")
            profile.setValue(now, forKey: "lastTimeCoinReset")
            
            do {
                try context.save()
                print("✅ 时间币已重置为 \(weeklyAllocation) 个")
            } catch {
                print("❌ 重置时间币失败: \(error)")
            }
        }
    }
    
    // 获取当前时间币数量
    func getCurrentTimeCoins() -> Int {
        // 先检查是否需要重置
        checkAndResetTimeCoins()
        
        guard let profile = getUserProfile() else { return 0 }
        return Int(profile.value(forKey: "timeCoins") as? Int32 ?? 5)
    }
    
    // 更新时间币数量
    private func updateTimeCoins(to amount: Int) {
        guard let profile = getUserProfile() else { return }
        
        profile.setValue(Int32(amount), forKey: "timeCoins")
        
        do {
            try context.save()
        } catch {
            print("❌ 更新时间币失败: \(error)")
        }
    }
    
    // 使用时间币
    func useTimeCoins(amount: Int) -> Result<Int, TimeCoinError> {
        guard let profile = getUserProfile() else {
            return .failure(.profileNotFound)
        }
        
        let current = Int(profile.value(forKey: "timeCoins") as? Int32 ?? 0)
        
        // 检查是否足够
        guard current >= amount else {
            return .failure(.insufficientCoins)
        }
        
        // 扣除时间币
        let newAmount = current - amount
        updateTimeCoins(to: newAmount)
        
        print("✅ 使用了 \(amount) 个时间币，剩余 \(newAmount) 个")
        return .success(newAmount)
    }
    
    // ✅ 新增：延长暂停（消耗1个时间币）
    func extendPause() -> Result<Int, TimeCoinError> {
        return useTimeCoins(amount: 1)
    }
    
    // 暂停任务/保存进度（消耗2个时间币）
    func pauseTask() -> Result<Int, TimeCoinError> {
        return useTimeCoins(amount: 2)
    }
    
    // 调整任务（消耗3个时间币）
    func adjustTask() -> Result<Int, TimeCoinError> {
        return useTimeCoins(amount: 3)
    }
}

// 时间币错误类型
enum TimeCoinError: Error, LocalizedError {
    case insufficientCoins
    case profileNotFound
    case saveFailed
    
    var errorDescription: String? {
        switch self {
        case .insufficientCoins:
            return "时间币不足"
        case .profileNotFound:
            return "用户档案未找到"
        case .saveFailed:
            return "保存失败，请重试"
        }
    }
}
