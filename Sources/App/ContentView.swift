import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            SessionActiveView()
                .tabItem { Label("Session", systemImage: "figure.stand") }

            HistoryView()
                .tabItem { Label("History", systemImage: "chart.line.uptrend.xyaxis") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
        }
    }
}
