import Foundation
import SwiftUI

// 勋章类型枚举
enum BadgeType: String, CaseIterable {
    case purist = "纯粹者"      // 不用延时包完成
    case challenger = "挑战者"   // 用延时包完成
    
    var icon: String {
        switch self {
        case .purist:
            return "🏆"
        case .challenger:
            return "⚔️"
        }
    }
    
    var color: Color {
        switch self {
        case .purist:
            return .green
        case .challenger:
            return .orange
        }
    }
    
    var description: String {
        switch self {
        case .purist:
            return "在时间内完成，未使用延时包"
        case .challenger:
            return "使用延时包挑战并完成"
        }
    }
}
