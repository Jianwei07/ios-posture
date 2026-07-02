import SwiftUI
import SwiftData
#if os(macOS)
import AppKit
#endif

@main
struct SynthesisApp: App {
    #if os(macOS)
    @Environment(\.openWindow) private var openWindow
    #endif

    // One explicit container (rather than the `.modelContainer(for:)`
    // convenience) so NotificationModule can share the same store the UI
    // observes — the "Log 250 ml" notification action writes here.
    private let container: ModelContainer

    init() {
        let container = try! ModelContainer(for: PostureSession.self, UserSettings.self, WaterEntry.self)
        NotificationModule.shared.configure(container: container)
        self.container = container
    }

    var body: some Scene {
        #if os(macOS)
        WindowGroup(id: "main") {
            appContent
                .frame(minWidth: 400, idealWidth: 440, maxWidth: 600,
                       minHeight: 640, idealHeight: 720, maxHeight: .infinity)
        }
        .windowResizability(.contentSize)

        MenuBarExtra("Synthesis", systemImage: "airpodspro") {
            Text("Synthesis")
                .font(.headline)
            Button("Open App") { openWindow(id: "main") }
            Button("Recalibrate") {
                openWindow(id: "main")
                NotificationCenter.default.post(name: .recalibrateRequested, object: nil)
            }
            Divider()
            Button("Quit") { NSApplication.shared.terminate(nil) }
        }
        #else
        WindowGroup {
            appContent
        }
        #endif
    }

    private var appContent: some View {
        ContentView()
            .modelContainer(container)
    }
}

#if os(macOS)
extension Notification.Name {
    static let recalibrateRequested = Notification.Name("synthesis.recalibrateRequested")
}
#endif
