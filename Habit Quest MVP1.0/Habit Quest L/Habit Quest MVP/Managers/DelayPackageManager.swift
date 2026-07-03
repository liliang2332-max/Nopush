import Foundation
import CoreData

// 延时包管理器
class DelayPackageManager {
    private let context: NSManagedObjectContext
    private let basePrice = 50
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    // ✅ 新增：根据任务难度计算价格
    func calculatePrice(for habit: NSManagedObject) -> Int {
        let usageCount = getDailyUsageCount()
        let recursiveMultiplier = Int(pow(2.0, Double(usageCount)))
        
        // 获取任务的预估时间
        let estimatedMinutes = habit.value(forKey: "estimatedMinutes") as? Int16 ?? 30
        
        // 根据难度计算系数
        let difficultyMultiplier = getDifficultyMultiplier(estimatedMinutes: Int(estimatedMinutes))
        
        // 基础价格 × 递增倍数 × 难度系数
        let finalPrice = Double(basePrice * recursiveMultiplier) * difficultyMultiplier
        
        return Int(finalPrice)
    }
    
    // ✅ 新增：根据预估时间判定难度系数
    private func getDifficultyMultiplier(estimatedMinutes: Int) -> Double {
        switch estimatedMinutes {
        case ...15:
            // 简单任务（≤15分钟）：70%
            return 0.7
        case 16...45:
            // 中等任务（16-45分钟）：50%
            return 0.5
        default:
            // 困难任务（>45分钟）：30%
            return 0.3
        }
    }
    
    // 计算当前延时包价格（兼容旧接口）
    func calculateCurrentPrice() -> Int {
        let usageCount = getDailyUsageCount()
        return basePrice * Int(pow(2.0, Double(usageCount)))
    }
    
    // 获取今日已使用次数
    func getDailyUsageCount() -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "DelayPackageHistory")
        request.predicate = NSPredicate(
            format: "purchaseTime >= %@ AND purchaseTime < %@",
            today as NSDate,
            tomorrow as NSDate
        )
        
        do {
            return try context.count(for: request)
        } catch {
            print("Failed to get daily usage count: \(error)")
            return 0
        }
    }
    
    // 购买延时包
    func purchaseDelayPackage(
        currentRating: RatingType,
        currentEXP: Int,
        habit: NSManagedObject  // ✅ 新增：需要习惯对象来计算价格
    ) -> Result<(newRating: RatingType, cost: Int), DelayPackageError> {
        // ✅ 修改：使用新的定价方法
        let cost = calculatePrice(for: habit)
        
        // 检查经验值是否足够
        guard currentEXP >= cost else {
            return .failure(.insufficientEXP)
        }
        
        // 检查是否可以购买（C评价不能购买）
        guard currentRating.canPurchaseDelay else {
            return .failure(.cannotDowngrade)
        }
        
        // 创建购买记录
        let history = NSEntityDescription.insertNewObject(forEntityName: "DelayPackageHistory", into: context)
        history.setValue(UUID(), forKey: "id")
        history.setValue(Date(), forKey: "purchaseTime")
        history.setValue(Int32(cost), forKey: "cost")
        history.setValue(Int16(15), forKey: "delayMinutes")
        
        // 降级评价
        let newRating = currentRating.downgrade()
        
        do {
            try context.save()
            return .success((newRating: newRating, cost: cost))
        } catch {
            return .failure(.saveFailed)
        }
    }
}

// 延时包错误类型
enum DelayPackageError: Error, LocalizedError {
    case insufficientEXP
    case cannotDowngrade
    case saveFailed
    
    var errorDescription: String? {
        switch self {
        case .insufficientEXP:
            return "经验值不足"
        case .cannotDowngrade:
            return "C评价无法使用延时包"
        case .saveFailed:
            return "保存失败，请重试"
        }
    }
}
