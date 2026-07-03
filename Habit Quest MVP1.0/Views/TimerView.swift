import SwiftUI

struct TimerView: View {
	@StateObject private var vm = TimerViewModel()
	@State private var showingDelaySheet = false

	let estimatedMinutes: Int

	var body: some View {
		VStack(spacing: 24) {
			Text(timeString(vm.elapsedSeconds))
				.font(.system(size: 48, weight: .bold, design: .rounded))
				.monospacedDigit()

			progressBar

			HStack(spacing: 16) {
				Button(vm.state == .running ? "暂停" : (vm.state == .paused ? "继续" : "开始")) {
					switch vm.state {
					case .idle: vm.start()
					case .running: vm.pause()
					case .paused: vm.resume()
					case .completed: break
					}
				}
				.buttonStyle(.borderedProminent)

				Button("完成") { vm.complete() }
					.buttonStyle(.bordered)
			}
		}
		.padding()
		.navigationTitle("计时")
		.onAppear { vm.configure(estimatedMinutes: estimatedMinutes) }
		.onChange(of: vm.showDelayOffer) { newValue in
			if newValue { showingDelaySheet = true }
		}
		.sheet(isPresented: $showingDelaySheet) {
			DelayPackageSheet { minutes in
				vm.applyDelay(minutes: minutes)
			}
		}
	}

	private var progressBar: some View {
		GeometryReader { geo in
			ZStack(alignment: .leading) {
				RoundedRectangle(cornerRadius: 8)
					.fill(Color.gray.opacity(0.2))
					.frame(height: 16)

				let w = geo.size.width * vm.progress
				RoundedRectangle(cornerRadius: 8)
					.fill(progressColor(vm.progress))
					.frame(width: max(0, w), height: 16)
			}
		}
		.frame(height: 16)
	}

	private func progressColor(_ p: Double) -> Color {
		if p < 0.6 { return Color(hex: 0x4ECDC4) }
		if p < 0.8 { return Color(hex: 0xFFB84D) }
		return Color(hex: 0xFF6B6B)
	}

	private func timeString(_ seconds: Int) -> String {
		let m = seconds / 60
		let s = seconds % 60
		return String(format: "%02d:%02d", m, s)
	}
}

private struct DelayPackageSheet: View {
	var onBuy: (Int) -> Void
	@Environment(\.dismiss) private var dismiss

	var body: some View {
		NavigationStack {
			VStack(spacing: 16) {
				Text("购买延时包 +15 分钟？")
					.font(.headline)
				Text("提示：购买将触发评价降级")
					.font(.subheadline)
					.foregroundColor(.secondary)
				Spacer()
			}
			.padding()
			.toolbar {
				ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
				ToolbarItem(placement: .confirmationAction) { Button("购买") { onBuy(15); dismiss() } }
			}
		}
	}
}
