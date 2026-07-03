import Foundation

// 可解锁功能枚举
enum UnlockableFeature: String, CaseIterable {
    case habitTemplates = "习惯模板库"
    case habitChain = "习惯链功能"
    case customAvatar = "个性化角色外观"
    case dataAnalysis = "数据深度分析"
    case customSounds = "自定义提醒音效"
    case advancedStats = "高级统计分析"
    case delayPackage = "延时包功能"  // ✅ 新增
    
    var requiredLevel: Int {
        switch self {
        case .habitTemplates:
            return 2
        case .habitChain:
            return 3
        case .customAvatar:
            return 4
        case .dataAnalysis:
            return 5
        case .customSounds:
            return 6
        case .advancedStats:
            return 4
        case .delayPackage:  // ✅ 新增
            return 1  // 默认解锁
        }
    }
    
    var icon: String {
        switch self {
        case .habitTemplates:
            return "doc.text.fill"
        case .habitChain:
            return "link"
        case .customAvatar:
            return "person.fill"
        case .dataAnalysis:
            return "chart.bar.fill"
        case .customSounds:
            return "speaker.wave.2.fill"
        case .advancedStats:
            return "chart.line.uptrend.xyaxis"
        case .delayPackage:  // ✅ 新增
            return "clock.arrow.circlepath"
        }
    }
    
    var description: String {
        switch self {
        case .habitTemplates:
            return "10+ 精选习惯模板，快速开始"
        case .habitChain:
            return "将新习惯附加到已有习惯后面"
        case .customAvatar:
            return "3个免费角色皮肤"
        case .dataAnalysis:
            return "查看历史趋势和深度分析"
        case .customSounds:
            return "个性化提醒音效"
        case .advancedStats:
            return "查看详细趋势图表和数据分析"
        case .delayPackage:  // ✅ 新增
            return "购买延时包延长任务时间"
        }
    }
}
