import Foundation

// 计时器状态枚举
enum TimerState {
    case idle       // 待机
    case running    // 运行中
    case paused     // 暂停
    case completed  // 已完成
    case failed     // ✅ 新增：失败（超时）
    
    var buttonTitle: String {
        switch self {
        case .idle: return "开始"
        case .running: return "暂停"
        case .paused: return "继续"
        case .completed: return "完成"
        case .failed: return "已失败"  // ✅ 新增
        }
    }
    
    // ✅ 可选：添加状态描述
    var description: String {
        switch self {
        case .idle: return "准备开始"
        case .running: return "进行中"
        case .paused: return "已暂停"
        case .completed: return "已完成"
        case .failed: return "任务失败"
        }
    }
    
    // ✅ 可选：添加状态颜色（用于UI显示）
    var statusColor: String {
        switch self {
        case .idle: return "gray"
        case .running: return "blue"
        case .paused: return "orange"
        case .completed: return "green"
        case .failed: return "red"
        }
    }
}
