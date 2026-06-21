import SwiftUI
import SwiftData
import CoreMotion

struct SessionActiveView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsArray: [UserSettings]

    @State private var engine: PostureEngine?
    @State private var sessionManager: SessionManager?
    @State private var scheduler: ReminderScheduler?
    @State private var overlayMessage: String?
    @State private var showOverlay = false
    @State private var connectionCheckTimer: Timer?
    @State private var wasEngineActive = false

    private var settings: UserSettings {
        settingsArray.first ?? UserSettings()
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                postureIndicator
                readingsGrid
                sessionControls
            }
            .padding()
            .navigationTitle("Posture")
            .overlay(alignment: .top) {
                if showOverlay, let msg = overlayMessage {
                    overlayBanner(message: msg)
                }
            }
        }
        .task { await setup() }
        .onDisappear { connectionCheckTimer?.invalidate() }
        .onReceive(
            NotificationCenter.default.publisher(for: NotificationModule.overlayNotification)
        ) { note in
            if let type = note.object as? ReminderType {
                showBanner(type.title)
            }
        }
    }

    // MARK: Subviews

    private var postureIndicator: some View {
        let state = engine?.postureState ?? .good
        let isActive = engine?.isActive ?? false
        let calibProgress = engine?.calibrationProgress ?? 0

        return VStack(spacing: 8) {
            Circle()
                .fill(isActive ? color(for: state) : Color.gray.opacity(0.3))
                .frame(width: 120, height: 120)
                .shadow(color: (isActive ? color(for: state) : Color.gray).opacity(0.3), radius: 20)
                .animation(.easeInOut(duration: 0.3), value: state)
                .animation(.easeInOut(duration: 0.3), value: isActive)

            if isActive {
                Text(state.label)
                    .font(.title2.bold())
                    .foregroundStyle(color(for: state))
            } else if calibProgress > 0 && calibProgress < 1 {
                Text("Calibrating \(Int(calibProgress * 100))%")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            } else {
                Text("Insert AirPods Pro")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var readingsGrid: some View {
        Grid(horizontalSpacing: 24, verticalSpacing: 12) {
            GridRow {
                readingCell(
                    label: "Pitch",
                    value: engine.map { String(format: "%.1f°", $0.currentPitch) } ?? "--"
                )
                readingCell(
                    label: "Session",
                    value: sessionManager.map { formatTime($0.activeSessionSeconds) } ?? "0:00"
                )
            }
        }
    }

    private func readingCell(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.title3.monospacedDigit())
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
    }

    private var sessionControls: some View {
        let state = sessionManager?.state ?? .idle
        return Group {
            if state == .active || state == .paused {
                Button("End Session", role: .destructive) {
                    sessionManager?.endSession()
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private func overlayBanner(message: String) -> some View {
        Text(message)
            .font(.subheadline.bold())
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial, in: Capsule())
            .padding(.top, 8)
            .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: Helpers

    private func color(for state: PostureState) -> Color {
        switch state {
        case .good:    return .green
        case .warning: return .orange
        case .poor:    return .red
        }
    }

    private func formatTime(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }

    private func showBanner(_ message: String) {
        overlayMessage = message
        withAnimation { showOverlay = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            withAnimation { showOverlay = false }
        }
    }

    private func setup() async {
        if settingsArray.isEmpty {
            let s = UserSettings()
            modelContext.insert(s)
            try? modelContext.save()
        }

        let classifier = PostureClassifier(
            poorPitchThreshold: settings.poorPitchThreshold,
            warningPitchThreshold: settings.warningPitchThreshold,
            forwardHeadThreshold: settings.forwardHeadThreshold
        )
        let eng = PostureEngine(classifier: classifier)
        let mgr = SessionManager(engine: eng)
        mgr.configure(modelContext: modelContext)
        let sched = ReminderScheduler(settings: settings)

        engine = eng
        sessionManager = mgr
        scheduler = sched

        await NotificationModule.shared.requestPermission()

        startConnectionPolling(mgr: mgr, eng: eng, sched: sched)
    }

    private func startConnectionPolling(mgr: SessionManager, eng: PostureEngine, sched: ReminderScheduler) {
        connectionCheckTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            let isNowActive = eng.isActive

            if !wasEngineActive && isNowActive {
                mgr.onAirPodsConnected()
            } else if wasEngineActive && !isNowActive {
                mgr.onAirPodsDisconnected()
            }
            wasEngineActive = isNowActive

            // Calibration complete
            if mgr.state == .calibrating && eng.calibrationProgress >= 1.0 {
                mgr.onCalibrationComplete()
            }

            // Tick scheduler
            if mgr.state == .active {
                sched.tick(postureState: eng.postureState, sessionSeconds: mgr.activeSessionSeconds)
            }
        }
    }
}
