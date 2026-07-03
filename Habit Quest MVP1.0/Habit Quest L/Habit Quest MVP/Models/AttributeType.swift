import Foundation
import SwiftUI

// 四维属性类型枚举
enum AttributeType: String, CaseIterable, Codable {
    case strength = "力量"      // 💪 运动健身
    case intelligence = "智力"   // 🧠 学习工作
    case agility = "敏捷"        // ⚡ 时间管理
    case charisma = "魅力"       // ✨ 社交互动
    
    var icon: String {
        switch self {
        case .strength: return "💪"
        case .intelligence: return "🧠"
        case .agility: return "⚡"
        case .charisma: return "✨"
        }
    }
    
    var color: Color {
        switch self {
        case .strength: return Color(hex: "#FF6B6B")      // 红色
        case .intelligence: return Color(hex: "#4285F4")  // 蓝色
        case .agility: return Color(hex: "#4ECDC4")       // 绿色
        case .charisma: return Color(hex: "#A855F7")      // 紫色
        }
    }
    
    var gradientColors: [Color] {
        switch self {
        case .strength: return [Color(hex: "#FF6B6B"), Color(hex: "#FF8E8E")]
        case .intelligence: return [Color(hex: "#4285F4"), Color(hex: "#6AB7FF")]
        case .agility: return [Color(hex: "#4ECDC4"), Color(hex: "#7ED321")]
        case .charisma: return [Color(hex: "#A855F7"), Color(hex: "#C084FC")]
        }
    }
    
    var description: String {
        switch self {
        case .strength: return "运动健身，强健体魄"
        case .intelligence: return "学习工作，增长见识"
        case .agility: return "高效执行，拒绝拖延"
        case .charisma: return "社交互动，建立连接"
        }
    }
    
    var examples: String {
        switch self {
        case .strength: return "跑步、健身、瑜伽..."
        case .intelligence: return "阅读、学习、技能练习..."
        case .agility: return "按时完成、提前行动..."
        case .charisma: return "联系朋友、表达感谢..."
        }
    }
}

// Color扩展：支持十六进制颜色
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}



