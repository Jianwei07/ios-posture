import CoreMotion
import Foundation
import Observation

@Observable
final class PostureEngine {
    // Published state (read on MainActor)
    private(set) var currentPitch: Double = 0
    private(set) var currentRoll: Double = 0
    private(set) var currentYaw: Double = 0
    private(set) var postureState: PostureState = .good
    private(set) var isActive: Bool = false
    private(set) var calibrationProgress: Double = 0

    var classifier: PostureClassifier
    var neutralPitch: Double? { calibration.neutralPitch }

    private let manager = CMHeadphoneMotionManager()
    private var pitchFilter = MotionFilter()
    private var rollFilter = MotionFilter()
    private let calibration = CalibrationStore()
    private let motionQueue = OperationQueue()

    // Watchdog: CMHeadphoneMotionManager stops delivering motion when AirPods
    // are removed or disconnect, but never calls back. We detect "stopped"
    // by checking whether a sample arrived recently.
    private var lastMotionTime: Date?
    private var watchdog: Timer?
    private let motionTimeout: TimeInterval = 1.5

    init(classifier: PostureClassifier) {
        self.classifier = classifier
        motionQueue.name = "com.jayden77.posture.motion"
        motionQueue.maxConcurrentOperationCount = 1
    }

    func start() {
        guard manager.isDeviceMotionAvailable else { return }
        pitchFilter.reset()
        rollFilter.reset()
        calibration.reset()
        lastMotionTime = nil

        manager.startDeviceMotionUpdates(to: motionQueue) { [weak self] motion, error in
            guard let self, let motion, error == nil else { return }
            self.process(motion: motion)
        }

        startWatchdog()
    }

    func stop() {
        manager.stopDeviceMotionUpdates()
        watchdog?.invalidate()
        watchdog = nil
        DispatchQueue.main.async { self.isActive = false }
    }

    private func startWatchdog() {
        watchdog?.invalidate()
        watchdog = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self else { return }
            let receiving: Bool = {
                guard let last = self.lastMotionTime else { return false }
                return Date().timeIntervalSince(last) < self.motionTimeout
            }()
            if self.isActive != receiving {
                self.isActive = receiving
            }
        }
    }

    private func process(motion: CMDeviceMotion) {
        let rawPitch = motion.attitude.pitch * 180 / .pi
        let rawRoll  = motion.attitude.roll  * 180 / .pi
        let rawYaw   = motion.attitude.yaw   * 180 / .pi

        let smoothPitch = pitchFilter.filter(rawPitch)
        let smoothRoll  = rollFilter.filter(rawRoll)

        calibration.addSample(smoothPitch)

        let state = classifier.classify(
            filteredPitch: smoothPitch,
            neutralPitch: calibration.neutralPitch
        )

        DispatchQueue.main.async {
            self.lastMotionTime = Date()
            self.currentPitch = smoothPitch
            self.currentRoll = smoothRoll
            self.currentYaw = rawYaw
            self.postureState = state
            self.isActive = true
            self.calibrationProgress = self.calibration.progress
        }
    }
}
