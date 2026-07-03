import SwiftUI

enum AttributeType: String, CaseIterable, Identifiable {
	case strength
	case intelligence
	case agility
	case charisma

	var id: String { rawValue }

	var displayName: String {
		switch self {
		case .strength: return "力量"
		case .intelligence: return "智力"
		case .agility: return "敏捷"
		case .charisma: return "魅力"
		}
	}

	var icon: String {
		switch self {
		case .strength: return "💪"
		case .intelligence: return "🧠"
		case .agility: return "⚡"
		case .charisma: return "✨"
		}
	}

	var gradient: LinearGradient {
		switch self {
		case .strength:
			return LinearGradient(colors: [Color(hex: 0xFF6B6B), Color(hex: 0xFF8E8E)], startPoint: .bottom, endPoint: .top)
		case .intelligence:
			return LinearGradient(colors: [Color(hex: 0x4285F4), Color(hex: 0x6AB7FF)], startPoint: .bottom, endPoint: .top)
		case .agility:
			return LinearGradient(colors: [Color(hex: 0x4ECDC4), Color(hex: 0x7ED321)], startPoint: .bottom, endPoint: .top)
		case .charisma:
			return LinearGradient(colors: [Color(hex: 0xA855F7), Color(hex: 0xC084FC)], startPoint: .bottom, endPoint: .top)
		}
	}
}

extension Color {
	init(hex: UInt, alpha: Double = 1.0) {
		let r = Double((hex >> 16) & 0xFF) / 255.0
		let g = Double((hex >> 8) & 0xFF) / 255.0
		let b = Double(hex & 0xFF) / 255.0
		self = Color(.sRGB, red: r, green: g, blue: b, opacity: alpha)
	}
}
