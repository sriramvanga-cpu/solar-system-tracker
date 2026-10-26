import Foundation
import Combine

@MainActor
final class SimulationClock: ObservableObject {
    @Published var date: Date = .now
    @Published var isPlaying = false
    /// Simulated days advanced per real second.
    @Published var speedDaysPerSecond: Double = 1

    static let speeds: [(label: String, days: Double)] = [
        ("1 d/s", 1),
        ("30 d/s", 30),
        ("1 y/s", 365.25),
    ]

    private var timer: Timer?

    func togglePlay() {
        isPlaying.toggle()
        if isPlaying { start() } else { stop() }
    }

    func pause() {
        isPlaying = false
        stop()
    }

    private func start() {
        stop()
        let t = Timer(timeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.isPlaying else { return }
                self.date = self.date.addingTimeInterval(self.speedDaysPerSecond * 86_400 / 30)
            }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func stop() {
        timer?.invalidate()
        timer = nil
    }

    deinit { timer?.invalidate() }
}
