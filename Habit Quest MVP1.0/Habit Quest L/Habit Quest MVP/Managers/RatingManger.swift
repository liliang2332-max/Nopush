import Foundation

// 评价管理器
class RatingManager {
    
    // 计算任务评价
    func calculateRating(estimatedMinutes: Int, actualMinutes: Int) -> RatingType {
        return RatingType.calculate(estimatedMinutes: estimatedMinutes, actualMinutes: actualMinutes)
    }
    
    // 计算经验值奖励
    func calculateExpReward(rating: RatingType, wasOnTime: Bool) -> Int {
        var exp = rating.expReward
        
        // S评价且按时完成，额外奖励5 EXP
        if rating == .s && wasOnTime {
            exp += 5
        }
        
        return exp
    }
    
    // 计算属性点数
    func calculateAttributePoints(rating: RatingType) -> Int {
        switch rating {
        case .s: return 25
        case .a: return 18
        case .b: return 12
        case .c: return 6
        }
    }
    
    // 评价降级
    func downgradeRating(_ rating: RatingType) -> RatingType {
        return rating.downgrade()
    }
    
    // 检查是否可以购买延时包
    func canPurchaseDelayPackage(for rating: RatingType) -> Bool {
        return rating.canPurchaseDelay
    }
    
    // 获取评价描述信息
    func getRatingInfo(rating: RatingType) -> (title: String, message: String, icon: String) {
        switch rating {
        case .s:
            return (
                "完美完成！",
                "获得额外奖励！你的执行力令人赞叹！",
                "star.fill"
            )
        case .a:
            return (
                "良好完成",
                "不错的表现，继续保持！",
                "checkmark.circle.fill"
            )
        case .b:
            return (
                "基本完成",
                "虽然用了延时，但完成比放弃更重要！",
                "checkmark.circle"
            )
        case .c:
            return (
                "勉强完成",
                "下次试着更好地规划时间吧",
                "clock"
            )
        }
    }
}
