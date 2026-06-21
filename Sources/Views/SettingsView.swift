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
                Section("Posture Thresholds") {
                    LabeledContent("Poor posture below") {
                        Text(String(format: "%.0f°", settings.poorPitchThreshold))
                            .foregroundStyle(.secondary)
                    }
                    Slider(
                        value: Bindable(settings).poorPitchThreshold,
                        in: -40 ... -5,
                        step: 1
                    )

                    LabeledContent("Warning below") {
                        Text(String(format: "%.0f°", settings.warningPitchThreshold))
                            .foregroundStyle(.secondary)
                    }
                    Slider(
                        value: Bindable(settings).warningPitchThreshold,
                        in: -30 ... -2,
                        step: 1
                    )

                    LabeledContent("Forward head above") {
                        Text(String(format: "%.0f°", settings.forwardHeadThreshold))
                            .foregroundStyle(.secondary)
                    }
                    Slider(
                        value: Bindable(settings).forwardHeadThreshold,
                        in: 5 ... 30,
                        step: 1
                    )
                }

                Section("Reminder Intervals") {
                    LabeledContent("Water reminder") {
                        Text(String(format: "%.0f min", settings.baseWaterIntervalMin))
                            .foregroundStyle(.secondary)
                    }
                    Slider(
                        value: Bindable(settings).baseWaterIntervalMin,
                        in: 15 ... 60,
                        step: 5
                    )
                }

                Section("Posture Alert") {
                    LabeledContent("Alert after poor posture for") {
                        Text(String(format: "%.0f s", settings.postureAlertSustainedSeconds))
                            .foregroundStyle(.secondary)
                    }
                    Slider(
                        value: Bindable(settings).postureAlertSustainedSeconds,
                        in: 10 ... 120,
                        step: 5
                    )
                }

                Section {
                    Button("Reset to Defaults", role: .destructive) {
                        settings.reset()
                        try? modelContext.save()
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}
