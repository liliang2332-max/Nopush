import Foundation

enum Rating: String { case S, A, B, C }

struct RatingRules {
	func rating(for actualMinutes: Int, estimatedMinutes: Int) -> Rating {
		guard estimatedMinutes > 0 else { return .C }
		let r = Double(actualMinutes) / Double(estimatedMinutes)
		if r <= 1.0 { return .S }
		if r <= 1.2 { return .A }
		if r <= 1.5 { return .B }
		return .C
	}

	func expForRating(_ rating: Rating) -> Int {
		switch rating {
		case .S: return 25
		case .A: return 15
		case .B: return 10
		case .C: return 5
		}
	}

	func downgraded(from rating: Rating) -> Rating {
		switch rating {
		case .S: return .A
		case .A: return .B
		case .B: return .C
		case .C: return .C
		}
	}
}
