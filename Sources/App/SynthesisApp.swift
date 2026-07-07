import SwiftUI
import SwiftData
#if os(macOS)
import AppKit
#endif

enum AppPersistence {
    static func makeContainer(
        applicationSupportDirectory: URL = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!,
        bundleIdentifier: String = Bundle.main.bundleIdentifier ?? "com.jayden77.posture"
    ) throws -> ModelContainer {
        let url = storeURL(
            applicationSupportDirectory: applicationSupportDirectory,
            bundleIdentifier: bundleIdentifier
        )
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let configuration = ModelConfiguration("Synthesis", url: url)
        return try ModelContainer(
            for: PostureSession.self,
            UserSettings.self,
            WaterEntry.self,
            configurations: configuration
        )
    }

    static func storeURL(applicationSupportDirectory: URL, bundleIdentifier: String) -> URL {
        applicationSupportDirectory
            .appendingPathComponent(bundleIdentifier, isDirectory: true)
            .appendingPathComponent("Synthesis.store")
    }

    @MainActor
    static func loadOrCreateSettings(in context: ModelContext) throws -> UserSettings {
        if let settings = try context.fetch(FetchDescriptor<UserSettings>()).first {
            return settings
        }

        let settings = UserSettings()
        context.insert(settings)
        try context.save()
        return settings
    }
}

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
        let container = try! AppPersistence.makeContainer()
        NotificationModule.shared.configure(container: container)

        let context = container.mainContext
        let settings = try! AppPersistence.loadOrCreateSettings(in: context)

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
