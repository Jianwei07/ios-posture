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

    var body: some Scene {
        #if os(macOS)
        WindowGroup(id: "main") {
            appContent
                .frame(width: 440, height: 720)
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
            .modelContainer(for: [PostureSession.self, UserSettings.self, WaterEntry.self])
    }
}

#if os(macOS)
extension Notification.Name {
    static let recalibrateRequested = Notification.Name("synthesis.recalibrateRequested")
}
#endif
