import Foundation
import SwiftData
import Observation

@Observable
final class SessionManager {
    private(set) var state: SessionState = .idle
    private(set) var activeSessionSeconds: Double = 0  // cumulative in-ear time

    private var currentSession: PostureSession?
    private var clockTimer: Timer?
    private var modelContext: ModelContext?

    let engine: PostureEngine

    init(engine: PostureEngine) {
        self.engine = engine
    }

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func onAirPodsConnected() {
        switch state {
        case .idle:
            startCalibrating()
        case .paused:
            startCalibrating()  // re-calibrate on reconnect
        default:
            break
        }
    }

    func onAirPodsDisconnected() {
        switch state {
        case .calibrating, .active:
            pauseSession()
        default:
            break
        }
    }

    func onCalibrationComplete() {
        guard state == .calibrating else { return }
        state = .active
        startClock()
    }

    func endSession() {
        guard state == .active || state == .paused else { return }
        stopClock()
        engine.stop()
        finalizeSession()
        state = .ended
        // Reset for next session
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.state = .idle
            self.activeSessionSeconds = 0
        }
    }

    private func startCalibrating() {
        if currentSession == nil {
            currentSession = PostureSession()
            modelContext?.insert(currentSession!)
        }
        state = .calibrating
        engine.start()
    }

    private func pauseSession() {
        state = .paused
        stopClock()
        engine.stop()
    }

    private func startClock() {
        clockTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self, self.state == .active else { return }
            self.activeSessionSeconds += 1
            self.recordReading()
        }
    }

    private func stopClock() {
        clockTimer?.invalidate()
        clockTimer = nil
    }

    private func recordReading() {
        guard let session = currentSession else { return }
        let reading = PostureReading(
            pitch: engine.currentPitch,
            classification: engine.postureState
        )
        session.readings.append(reading)
    }

    private func finalizeSession() {
        guard let session = currentSession else { return }
        session.endTime = .now
        let readings = session.readings
        guard !readings.isEmpty else { return }
        let pitches = readings.map(\.pitch)
        session.avgPitch = pitches.reduce(0, +) / Double(pitches.count)
        let poorCount = readings.filter { $0.classification == PostureState.poor.rawValue }.count
        session.poorPosturePct = Double(poorCount) / Double(readings.count)
        session.score = max(0, 100 - Int(session.poorPosturePct * 100))
        try? modelContext?.save()
        currentSession = nil
    }
}
