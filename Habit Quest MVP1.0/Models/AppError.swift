import Foundation

enum AppError: Error, LocalizedError {
	case dataNotFound
	case saveFailed
	case deleteFailed
	case invalidInput(String)
	case insufficientEXP(current: Int, required: Int)

	var errorDescription: String? {
		switch self {
		case .dataNotFound:
			return "数据未找到"
		case .saveFailed:
			return "保存失败"
		case .deleteFailed:
			return "删除失败"
		case .invalidInput(let msg):
			return "输入无效：\(msg)"
		case .insufficientEXP(let current, let required):
			return "经验值不足（当前 \(current) / 需要 \(required)）"
		}
	}
}
