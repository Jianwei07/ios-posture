import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var settingsArray: [UserSettings]
    @Environment(\.modelContext) private var modelContext

    private var settings: UserSettings {
        if let s = settingsArray.first { return s }
        let s = UserSettings()
        modelContext.insert(s)
        return s
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Reminders") {
                    sliderRow("Water", value: Bindable(settings).baseWaterIntervalMin,
                              range: 15 ... 90, unit: " min")
                    sliderRow("Walk", value: Bindable(settings).baseWalkIntervalMin,
                              range: 20 ... 120, unit: " min")
                }

                Section {
                    Button("Reset to defaults", role: .destructive) {
                        settings.reset()
                        try? modelContext.save()
                    }
                }

                Section {
                    Text("All posture data stays on your device. No account, no cloud, no tracking.")
                        .font(Theme.Font.caption())
                        .foregroundStyle(Theme.Palette.inkSoft)
                        .listRowBackground(Color.clear)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.Palette.canvas.ignoresSafeArea())
            .navigationTitle("Settings")
            .tint(Theme.Palette.honey)
        }
    }

    private func sliderRow(_ label: String, value: Binding<Double>,
                           range: ClosedRange<Double>, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(Theme.Font.body())
                    .foregroundStyle(Theme.Palette.ink)
                Spacer()
                Text(String(format: "every %.0f\(unit)", value.wrappedValue))
                    .font(Theme.Font.number(15))
                    .foregroundStyle(Theme.Palette.inkSoft)
            }
            Slider(value: value, in: range, step: 5)
                .tint(Theme.Palette.honey)
        }
        .padding(.vertical, 2)
        .listRowBackground(Theme.Palette.surface)
    }
}
