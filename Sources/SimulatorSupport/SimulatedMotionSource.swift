import Foundation

#if targetEnvironment(simulator)

// Fake motion source for Simulator + UI iteration. Pitch driven by a debug slider.
// Detached from PostureEngine so all simulator-only code lives in one removable folder.
// To remove: delete Sources/SimulatorSupport/ and strip #if targetEnvironment(simulator) blocks
// in AppModel.swift and ContentView.swift.
@Observable
final class SimulatedMotionSource: MotionSource {
    var simulatedPitch: Double = 0
    var available: Bool = true {
        didSet { onAvailabilityChanged?(available) }
    }
    @ObservationIgnored var onAvailabilityChanged: ((Bool) -> Void)?
    @ObservationIgnored private var timer: Timer?

    var isAvailable: Bool { available }

    func start(onSample: @escaping (Double) -> Void) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self, self.available else { return }
            onSample(self.simulatedPitch)
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }
}

#endif
