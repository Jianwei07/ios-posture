import CoreMotion
import Foundation
import Observation

// MARK: - Motion source seam
// Posture detection reads a stream of head-pitch samples (degrees). The source
// is swappable: real AirPods on device, a simulated source on Simulator/in tests.

protocol MotionSource: AnyObject {
    var isAvailable: Bool { get }
    var isConnected: Bool { get }
    var onAvailabilityChanged: ((Bool) -> Void)? { get set }
    func startMonitoring()
    func start(onSample: @escaping (Double) -> Void)  // emits pitch in degrees
    func stop()
}

// Real AirPods via CoreMotion. Connect/disconnect via the delegate (pattern
// from github.com/tldev/dorso). Device only.
final class HeadphoneMotionSource: NSObject, MotionSource, CMHeadphoneMotionManagerDelegate {
    private let manager = CMHeadphoneMotionManager()
    private let queue = OperationQueue()
    private var connected = false
    var onAvailabilityChanged: ((Bool) -> Void)?

    override init() {
        super.init()
        queue.name = "com.jayden77.posture.motion"
        queue.maxConcurrentOperationCount = 1
        manager.delegate = self
    }

    var isAvailable: Bool { manager.isDeviceMotionAvailable }
    var isConnected: Bool { connected }

    func startMonitoring() {
        guard manager.isDeviceMotionAvailable else { return }
        manager.startConnectionStatusUpdates()
    }

    func start(onSample: @escaping (Double) -> Void) {
        guard manager.isDeviceMotionAvailable else { return }
        manager.startDeviceMotionUpdates(to: queue) { motion, error in
            guard let motion, error == nil else { return }
            if !self.connected {
                self.connected = true
                self.onAvailabilityChanged?(true)
            }
            onSample(motion.attitude.pitch * 180 / .pi)
        }
    }

    func stop() {
        manager.stopDeviceMotionUpdates()
    }

    // Delegate push — AirPods connected / removed.
    func headphoneMotionManagerDidConnect(_ manager: CMHeadphoneMotionManager) {
        connected = true
        onAvailabilityChanged?(true)
    }
    func headphoneMotionManagerDidDisconnect(_ manager: CMHeadphoneMotionManager) {
        connected = false
        onAvailabilityChanged?(false)
    }
}

// MARK: - PostureEngine

@Observable
final class PostureEngine {
    private(set) var currentPitch: Double = 0
    private(set) var postureState: PostureState = .aligned
    private(set) var calibrationProgress: Double = 0
    private(set) var neutralPitch: Double?
    private(set) var lastSampleAt: Date?
    private(set) var calibrationSpread: Double = 0

    var classifier: PostureClassifier
    var isHeadphoneMotionAvailable: Bool { source.isAvailable }
    var isHeadphoneMotionConnected: Bool { source.isConnected }

    let source: MotionSource
    private var pitchFilter = MotionFilter()

    // Calibration only runs after recalibrate() — never silently on start().
    private var calibrationSamples: [Double] = []
    private let calibrationTarget = 100   // ~5s @ 20Hz
    private let maxCalibrationSpread: Double = 4.0  // degrees; reject if head moved too much
    private var isCalibrating = false

    init(classifier: PostureClassifier = PostureClassifier(), source: MotionSource) {
        self.classifier = classifier
        self.source = source
    }

    // Forward angle (deg below baseline) of the current smoothed pitch. 0 until calibrated.
    var forwardAngle: Double {
        guard let n = neutralPitch else { return 0 }
        return classifier.forwardAngle(filteredPitch: currentPitch, neutralPitch: n)
    }

    // Seed a persisted baseline so a reconnecting session skips re-calibration.
    func seedBaseline(_ pitch: Double?) {
        neutralPitch = pitch
        calibrationProgress = pitch == nil ? 0 : 1
        isCalibrating = false
    }

    // Force a fresh 5-second baseline capture (Recalibrate / onboarding).
    func recalibrate() {
        calibrationSamples = []
        neutralPitch = nil
        calibrationProgress = 0
        calibrationSpread = 0
        isCalibrating = true
    }

    // Cancel an in-flight calibration — stops source, rejects late samples.
    func cancelCalibration() {
        isCalibrating = false
        calibrationSamples = []
        calibrationProgress = 0
        calibrationSpread = 0
        stop()
    }

    func start() {
        guard source.isAvailable else { return }
        pitchFilter.reset()
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

    // Runs on the motion source's queue. Only the filter (single-owner there)
    // touches engine state off-main; everything else hops to main so
    // calibration/classification state has exactly one writer thread —
    // recalibrate()/cancelCalibration() also mutate it from main.
    private func process(pitch rawPitch: Double) {
        let smoothPitch = pitchFilter.filter(rawPitch)
        DispatchQueue.main.async { [weak self] in
            self?.ingest(smoothPitch: smoothPitch)
        }
    }

    private func ingest(smoothPitch: Double) {
        if isCalibrating, neutralPitch == nil {
            calibrationSamples.append(smoothPitch)
            if calibrationSamples.count >= calibrationTarget {
                let spread = (calibrationSamples.max() ?? 0) - (calibrationSamples.min() ?? 0)
                calibrationSpread = spread
                if spread <= maxCalibrationSpread {
                    neutralPitch = calibrationSamples.reduce(0, +) / Double(calibrationSamples.count)
                }
                isCalibrating = false
            }
        }

        let state = classifier.classify(filteredPitch: smoothPitch, neutralPitch: neutralPitch)

        lastSampleAt = Date()
        currentPitch = smoothPitch
        postureState = state
        calibrationProgress = min(1, Double(calibrationSamples.count) / Double(calibrationTarget))
    }
}
