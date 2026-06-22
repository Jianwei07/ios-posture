import SwiftUI
import SwiftData

@main
struct SynthesisApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: [PostureSession.self, UserSettings.self, WaterEntry.self])
        }
    }
}
