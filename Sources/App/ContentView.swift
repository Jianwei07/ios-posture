import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "figure.stand") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
        }
        .tint(Theme.Palette.honey)
    }
}
