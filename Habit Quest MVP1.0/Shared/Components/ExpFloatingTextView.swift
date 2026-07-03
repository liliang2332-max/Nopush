import SwiftUI

struct ExpFloatingTextView: View {
	let text: String
	@State private var animate = false

	var body: some View {
		Text(text)
			.font(.headline)
			.foregroundColor(text.hasPrefix("+") ? Color.green : Color.red)
			.opacity(animate ? 0 : 1)
			.offset(y: animate ? -30 : 0)
			.onAppear {
				withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
					animate = true
				}
			}
	}
}
