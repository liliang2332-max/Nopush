import Foundation
import SwiftUI

// 评价等级枚举
enum RatingType: String, CaseIterable, Codable {
    case s = "S"
    case a = "A"
    case b = "B"
    case c = "C"
    
    var color: Color {
        switch self {
        case .s: return Color.yellow       // 金色
        case .a: return Color.gray         // 银色
        case .b: return Color.orange       // 铜色
        case .c: return Color.secondary    // 灰色
        }
    }
    
    var expReward: Int {
        switch self {
        case .s: return 20
        case .a: return 15
        case .b: return 10
        case .c: return 5
        }
    }
    
    var description: String {
        switch self {
        case .s: return "完美完成！"
        case .a: return "良好完成"
        case .b: return "基本完成"
        case .c: return "勉强完成"
        }
    }
    
    func downgrade() -> RatingType {
        switch self {
        case .s: return .a
        case .a: return .b
        case .b: return .c
        case .c: return .c
        }
    }
    
    var canPurchaseDelay: Bool {
        return self != .c
    }
    
    static func calculate(estimatedMinutes: Int, actualMinutes: Int) -> RatingType {
        let ratio = Double(actualMinutes) / Double(estimatedMinutes)
        
        if ratio <= 1.0 {
            return .s
        } else if ratio <= 1.2 {
            return .a
        } else if ratio <= 1.5 {
            return .b
        } else {
            return .c
        }
    }
}
