import SwiftUI

struct AttributeCardView: View {
	let type: AttributeType
	let today: Int
	let total: Int

	var body: some View {
		ZStack {
			RoundedRectangle(cornerRadius: 16)
				.fill(type.gradient)
				.frame(height: 120)
				.shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)

			VStack(alignment: .leading, spacing: 8) {
				Text("\(type.icon) \(type.displayName)")
					.font(.headline)
					.foregroundColor(.white)
				Text("今日 +\(today)")
					.font(.subheadline)
					.foregroundColor(.white.opacity(0.9))
				Text("累计 \(total)")
					.font(.subheadline)
					.foregroundColor(.white.opacity(0.9))
			}
			.frame(maxWidth: .infinity, alignment: .leading)
			.padding()
		}
	}
}
