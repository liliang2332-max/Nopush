import Foundation

struct DelayPricingService {
	/// 当日第 k 次购买价格：50 * 2^(k-1)，最大到第 4 次
	func priceForDailySequence(_ k: Int) -> Int {
		let clamped = max(1, min(4, k))
		return 50 * (1 << (clamped - 1))
	}

	/// 判断是否跨日，用于重置序号
	func isNewDay(previous: Date?, now: Date = Date(), calendar: Calendar = .current) -> Bool {
		guard let previous else { return true }
		return !calendar.isDate(previous, inSameDayAs: now)
	}
}
