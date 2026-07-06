import SwiftUI
import SwiftData
#if os(macOS)
import AppKit
#endif

@main
struct SynthesisApp: App {
    // One explicit container (rather than the `.modelContainer(for:)`
    // convenience) so NotificationModule can share the same store the UI
    // observes — the "Log 250 ml" notification action writes here.
    private let container: ModelContainer

    // Built once at launch (not lazily inside ContentView) so the
    // MenuBarExtra scene — a sibling of the main window, not a descendant —
    // can also observe live posture state for its glyph.
    @State private var appModel: AppModel

    init() {
        let container = try! ModelContainer(for: PostureSession.self, UserSettings.self, WaterEntry.self)
        NotificationModule.shared.configure(container: container)

        let context = container.mainContext
        let settings = (try? context.fetch(FetchDescriptor<UserSettings>()))?.first ?? {
            let s = UserSettings()
            context.insert(s)
            try? context.save()
            return s
        }()

        self.container = container
        _appModel = State(initialValue: AppModel(settings: settings))
    }

    var body: some Scene {
        #if os(macOS)
        WindowGroup(id: "main") {
            appContent
                .frame(minWidth: 400, idealWidth: 440, maxWidth: 600,
                       minHeight: 640, idealHeight: 720, maxHeight: .infinity)
        }
        .windowResizability(.contentSize)
        .environment(appModel)
        .modelContainer(container)

        MenuBarExtra {
            MenuBarPopoverView()
        } label: {
            // NSImage-backed label: SwiftUI templates custom label views
            // (stripping color), so the state dot must come in via an
            // isTemplate=false NSImage. See MenuBarGlyph.
            Image(nsImage: MenuBarGlyph.image(for: appModel.menuBarState))
        }
        .menuBarExtraStyle(.window)
        .environment(appModel)
        .modelContainer(container)
        #else
        WindowGroup {
            appContent
        }
        .environment(appModel)
        .modelContainer(container)
        #endif
    }

    private var appContent: some View {
        ContentView()
    }
}

#if os(macOS)
extension Notification.Name {
    static let recalibrateRequested = Notification.Name("synthesis.recalibrateRequested")
}
#endif
