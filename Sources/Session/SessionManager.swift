import Foundation
import SwiftData
import Observation

// Owns the single 1Hz heartbeat that drives the whole session: connect/pause
// detection, the session clock, downsampled persistence, and reminder ticks.
@Observable
final class SessionManager {
    private(set) var state: SessionState = .idle
    private(set) var activeSessionSeconds: Double = 0   // cumulative in-ear time

    let engine: PostureEngine
    private let scheduler: ReminderScheduler
    private var modelContext: ModelContext?

    private var currentSession: PostureSession?
    private var heartbeat: Timer?
    private var endedManually = false
    private var pausedAt: Date?

    // A break of at least this long (AirPods out) is treated as "the user
    // got up and walked" — resets the walk reminder interval on resume.
    private let breakResetsWalkSeconds: TimeInterval = 300

    // Piggybacks the existing 1Hz heartbeat — no separate timer. AppModel
    // uses this to drive the ambient menu bar glyph.
    var onHeartbeat: ((SessionState, PostureState) -> Void)?

    // Running accumulators → accurate score without storing every second.
    private var pitchSum = 0.0
    private var sampleCount = 0
    private var poorCount = 0
    private var secondsSinceRecord = 0
    private let recordEverySeconds = 30   // downsample persisted readings

    init(engine: PostureEngine, scheduler: ReminderScheduler) {
        self.engine = engine
        self.scheduler = scheduler
    }

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // Start the heartbeat. Called once when the view appears.
    func begin() {
        engine.source.onAvailabilityChanged = { [weak self] _ in self?.evaluate() }
        engine.source.startMonitoring()
        heartbeat?.invalidate()
        heartbeat = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.evaluate()
        }
    }

    func endSession() {
        guard state == .active || state == .paused else { return }
        finalizeSession()
        engine.stop()
        state = .idle
        activeSessionSeconds = 0
        endedManually = true
        pausedAt = nil
        scheduler.reset()
    }

    // The single heartbeat. Runs every second.
    private func evaluate() {
        let available = engine.isHeadphoneMotionConnected
        let receiving = engine.isReceiving()

        switch state {
        case .idle:
            if available && !endedManually { startSession() }

        case .active:
            if !available || !receiving {
                pauseSession()
            } else {
                tickActive()
            }

        case .paused:
            if available { startSession() }   // reconnected → recalibrate
        }

        if !available { endedManually = false }  // AirPods removed → allow auto-start again

        onHeartbeat?(state, engine.postureState)
    }

    private func startSession() {
        if let pausedAt, Date.now.timeIntervalSince(pausedAt) >= breakResetsWalkSeconds {
            scheduler.noteBreakTaken(sessionSeconds: activeSessionSeconds)
        }
        pausedAt = nil

        if currentSession == nil {
            let s = PostureSession()
            modelContext?.insert(s)
            currentSession = s
        }
        engine.start()
        state = .active
    }

    private func pauseSession() {
        state = .paused
        pausedAt = .now
        engine.stop()
    }

    private func tickActive() {
        // Don't count time / score until calibrated, and don't count it on
        // the strength of the post-start() spin-up grace alone: if the
        // stream is connected but stalled (no disconnect event, samples just
        // stopped), evaluate() resumes .paused -> .active via startSession(),
        // and isReceiving() reports true for up to spinUpGraceSeconds even
        // though nothing has actually arrived yet. Requiring a real sample
        // (engine.lastSampleAt != nil, which start() clears) means this tick
        // is a no-op until the stream proves it's actually alive again —
        // stale currentPitch/postureState from before the stall never gets
        // counted as active time or fed to the reminder scheduler.
        guard engine.neutralPitch != nil, engine.lastSampleAt != nil else { return }

        activeSessionSeconds += 1
        pitchSum += engine.currentPitch
        sampleCount += 1
        if engine.postureState == .slouch { poorCount += 1 }

        secondsSinceRecord += 1
        if secondsSinceRecord >= recordEverySeconds {
            secondsSinceRecord = 0
            currentSession?.readings.append(
                PostureReading(pitch: engine.currentPitch, classification: engine.postureState)
            )
        }

        scheduler.tick(postureState: engine.postureState, sessionSeconds: activeSessionSeconds)
    }

    private func finalizeSession() {
        guard let session = currentSession else { return }
        session.endTime = .now
        if sampleCount > 0 {
            session.avgPitch = pitchSum / Double(sampleCount)
            session.poorPosturePct = Double(poorCount) / Double(sampleCount)
            session.score = max(0, 100 - Int(session.poorPosturePct * 100))
        }
        try? modelContext?.save()
        currentSession = nil
        pitchSum = 0; sampleCount = 0; poorCount = 0; secondsSinceRecord = 0
    }
}
