import SwiftUI
import SwiftData

// Root: build the shared posture stack, gate first-run onboarding, and overlay
// the Disconnected screen whenever the IMU stream is unavailable.
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsArray: [UserSettings]

    @State private var app: AppModel?
    #if os(macOS)
    @State private var showRecalibrate = false
    #endif

    private var settings: UserSettings { settingsArray.first ?? UserSettings() }

    var body: some View {
        ZStack {
            Theme.Palette.bg.ignoresSafeArea()

            if let app {
                if settings.hasOnboarded {
                    MainShell()
                        .environment(app)
                        .overlay {
                            if app.session.state == .paused {
                                DisconnectedView()
                                    .transition(.opacity)
                            }
                        }
                        .animation(Theme.Motion.fade, value: app.isConnected)
                } else {
                    OnboardingFlow(
                        settings: settings,
                        onFinish: { settings.hasOnboarded = true; save() },
                        onSkip: { settings.hasOnboarded = true; save() }
                    )
                    .environment(app)
                }
            }

            #if targetEnvironment(simulator)
            if let sim = app?.simSource {
                SimulatorOverlay(source: sim)
            }
            #endif
        }
        .task { await setup() }
        .tint(Theme.Palette.accent)
        #if os(macOS)
        .onReceive(NotificationCenter.default.publisher(for: .recalibrateRequested)) { _ in
            showRecalibrate = true
        }
        .sheet(isPresented: $showRecalibrate) {
            if let app {
                CalibrateView(engine: app.engine, mode: .recalibrate) { baseline in
                    if let baseline {
                        settings.baselinePitch = baseline
                        save()
                    } else {
                        app.engine.seedBaseline(settings.baselinePitch)
                    }
                    showRecalibrate = false
                }
                .environment(app)
            }
        }
        #endif
    }

    private func setup() async {
        if settingsArray.isEmpty {
            modelContext.insert(UserSettings())
            try? modelContext.save()
        }
        if app == nil {
            let model = AppModel(settings: settings)
            model.start(modelContext: modelContext)
            app = model
        }
    }

    private func save() { try? modelContext.save() }
}

// The three-tab shell: Now · Trends · Settings.
struct MainShell: View {
    var body: some View {
        TabView {
            NowView()
                .tabItem { Label("Now", systemImage: "circle.fill") }
            TrendsView()
                .tabItem { Label("Trends", systemImage: "chart.bar.fill") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "slider.horizontal.3") }
        }
        .tint(Theme.Palette.accent)
    }
}
