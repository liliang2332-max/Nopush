import Foundation
import Combine

final class TimerViewModel: ObservableObject {
	enum State { case idle, running, paused, completed }

	@Published private(set) var state: State = .idle
	@Published private(set) var elapsedSeconds: Int = 0
	@Published private(set) var totalSeconds: Int = 0
	@Published var showDelayOffer: Bool = false

	private var timerCancellable: AnyCancellable?
	private let tick = 1.0

	var progress: Double { totalSeconds > 0 ? Double(elapsedSeconds) / Double(totalSeconds) : 0 }

	func configure(estimatedMinutes: Int) {
		totalSeconds = max(1, estimatedMinutes * 60)
		reset()
	}

	func start() {
		guard state != .running else { return }
		state = .running
		timerCancellable = Timer.publish(every: tick, on: .main, in: .common)
			.autoconnect()
			.sink { [weak self] _ in self?.tickForward() }
	}

	func pause() {
		guard state == .running else { return }
		state = .paused
		timerCancellable?.cancel()
	}

	func resume() { start() }

	func complete() {
		state = .completed
		timerCancellable?.cancel()
	}

	func reset() {
		state = .idle
		elapsedSeconds = 0
		showDelayOffer = false
		timerCancellable?.cancel()
	}

	private func tickForward() {
		guard state == .running else { return }
		elapsedSeconds += 1
		let percent = progress
		if percent >= 0.8 { showDelayOffer = true }
		if elapsedSeconds >= totalSeconds {
			complete()
		}
	}

	func applyDelay(minutes: Int) {
		totalSeconds += minutes * 60
		showDelayOffer = false
	}
}
