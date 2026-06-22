import CoreMotion
import Foundation
import Observation

// MARK: - Motion source seam
// Posture detection reads a stream of head-pitch samples (degrees). The source
// is swappable: real AirPods on device, a simulated source on Simulator/in tests.

protocol MotionSource: AnyObject {
    var isAvailable: Bool { get }
    var onAvailabilityChanged: ((Bool) -> Void)? { get set }
    func start(onSample: @escaping (Double) -> Void)  // emits pitch in degrees
    func stop()
}

// Real AirPods via CoreMotion. Connect/disconnect via the delegate (pattern
// from github.com/tldev/dorso). Device only.
final class HeadphoneMotionSource: NSObject, MotionSource, CMHeadphoneMotionManagerDelegate {
    private let manager = CMHeadphoneMotionManager()
    private let queue = OperationQueue()
    var onAvailabilityChanged: ((Bool) -> Void)?

    override init() {
        super.init()
        queue.name = "com.jayden77.posture.motion"
        queue.maxConcurrentOperationCount = 1
        manager.delegate = self
    }

    var isAvailable: Bool { manager.isDeviceMotionAvailable }

    func start(onSample: @escaping (Double) -> Void) {
        guard manager.isDeviceMotionAvailable else { return }
        manager.startDeviceMotionUpdates(to: queue) { motion, error in
            guard let motion, error == nil else { return }
            onSample(motion.attitude.pitch * 180 / .pi)
        }
    }

    func stop() {
        manager.stopDeviceMotionUpdates()
    }

    // Delegate push — AirPods connected / removed.
    func headphoneMotionManagerDidConnect(_ manager: CMHeadphoneMotionManager) {
        onAvailabilityChanged?(true)
    }
    func headphoneMotionManagerDidDisconnect(_ manager: CMHeadphoneMotionManager) {
        onAvailabilityChanged?(false)
    }
}

// Fake source for Simulator + UI iteration. Pitch driven by a debug slider.
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

// MARK: - PostureEngine

@Observable
final class PostureEngine {
    private(set) var currentPitch: Double = 0
    private(set) var postureState: PostureState = .good
    private(set) var calibrationProgress: Double = 0
    private(set) var neutralPitch: Double?
    private(set) var lastSampleAt: Date?

    var classifier: PostureClassifier
    var isHeadphoneMotionAvailable: Bool { source.isAvailable }

    let source: MotionSource
    private var pitchFilter = MotionFilter()

    // Inlined calibration: average the first N samples into a neutral baseline.
    private var calibrationSamples: [Double] = []
    private let calibrationTarget = 60   // ~3s @ 20Hz

    init(classifier: PostureClassifier = PostureClassifier(), source: MotionSource) {
        self.classifier = classifier
        self.source = source
    }

    func start() {
        guard source.isAvailable else { return }
        pitchFilter.reset()
        calibrationSamples = []
        neutralPitch = nil
        calibrationProgress = 0
        lastSampleAt = nil
        source.start { [weak self] pitch in self?.process(pitch: pitch) }
    }

    func stop() {
        source.stop()
    }

    // True while samples are arriving (AirPods in ear and streaming).
    func isReceiving(timeout: TimeInterval = 1.5) -> Bool {
        guard let last = lastSampleAt else { return false }
        return Date().timeIntervalSince(last) < timeout
    }

    private func process(pitch rawPitch: Double) {
        let smoothPitch = pitchFilter.filter(rawPitch)

        if neutralPitch == nil {
            calibrationSamples.append(smoothPitch)
            if calibrationSamples.count >= calibrationTarget {
                neutralPitch = calibrationSamples.reduce(0, +) / Double(calibrationSamples.count)
            }
        }

        let state = classifier.classify(filteredPitch: smoothPitch, neutralPitch: neutralPitch)

        DispatchQueue.main.async {
            self.lastSampleAt = Date()
            self.currentPitch = smoothPitch
            self.postureState = state
            self.calibrationProgress = min(1, Double(self.calibrationSamples.count) / Double(self.calibrationTarget))
        }
    }
}
