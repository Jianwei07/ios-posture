import SwiftUI
import SwiftData

// Settings — the knobs. Nudge style · escalate · sensitivity · recalibrate.
// See design.md.
struct SettingsView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsArray: [UserSettings]

    @State private var showCalibrate = false

    private var settings: UserSettings { settingsArray.first ?? UserSettings() }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    airpodsRow

                    sectionLabel("Nudge style")
                    segmented(NudgeStyle.allCases, selected: settings.nudgeStyle, label: \.label) {
                        settings.nudgeStyle = $0; save()
                    }

                    escalateRow

                    sectionLabel("Slouch sensitivity")
                    sensitivityCard

                    sectionLabel("Plant mascot")
                    PlantPicker(selected: Binding(
                        get: { settings.selectedPlant },
                        set: { settings.selectedPlant = $0; save() }
                    ))

                    sectionLabel("Water target")
                    waterTargetRow

                    sectionLabel("Walk target")
                    stepTargetRow

                    sunlightRow

                    Button { recalibrate() } label: {
                        Text("Recalibrate baseline")
                            .font(Theme.Font.body(15).weight(.semibold))
                            .foregroundStyle(Theme.Palette.ink)
                            .frame(maxWidth: .infinity).padding(.vertical, 13)
                            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.chip)
                                .stroke(Theme.Palette.inkFaint.opacity(0.5)))
                    }
                    .pressable()
                    .padding(.top, 4)

                    Text("All posture data stays on your device. No account, no cloud.")
                        .font(Theme.Font.caption()).foregroundStyle(Theme.Palette.inkFaint)
                        .padding(.top, 8)
                }
                .padding(20)
            }
            .scrollContentBackground(.hidden)
            .background(Theme.Palette.bg.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showCalibrate) {
            CalibrateView(engine: app.engine, mode: .recalibrate) { baseline in
                settings.baselinePitch = baseline; save()
                showCalibrate = false
            }
        }
    }

    // MARK: Rows

    private var airpodsRow: some View {
        let connected = app.isConnected
        return HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 8).stroke(Theme.Palette.inkFaint.opacity(0.5))
                .frame(width: 30, height: 30)
                .overlay(Circle().fill(connected ? Theme.Palette.accent : Theme.Palette.inkFaint).frame(width: 7, height: 7))
            VStack(alignment: .leading, spacing: 1) {
                Text("AirPods Pro").font(Theme.Font.body(14).weight(.semibold)).foregroundStyle(Theme.Palette.ink)
                Text(connected ? "connected · tracking" : "not connected")
                    .font(Theme.Font.caption(11))
                    .foregroundStyle(connected ? Theme.Palette.accent : Theme.Palette.inkFaint)
            }
            Spacer()
        }
        .padding(12)
        .background(Theme.Palette.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.chip))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.chip).stroke(Theme.Palette.ink.opacity(0.06)))
    }

    private var escalateRow: some View {
        Toggle(isOn: Binding(get: { settings.escalateLongSlouches },
                             set: { settings.escalateLongSlouches = $0; save() })) {
            VStack(alignment: .leading, spacing: 1) {
                Text("Escalate long slouches").font(Theme.Font.body(14).weight(.semibold)).foregroundStyle(Theme.Palette.ink)
                Text("banner after 6 min").font(Theme.Font.caption(11)).foregroundStyle(Theme.Palette.inkFaint)
            }
        }
        .tint(Theme.Palette.aligned)
        .padding(12)
        .background(Theme.Palette.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.chip))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.chip).stroke(Theme.Palette.ink.opacity(0.06)))
    }

    private var sensitivityCard: some View {
        VStack(spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("triggers past").font(Theme.Font.caption()).foregroundStyle(Theme.Palette.inkFaint)
                Spacer()
                Text("\(Int(settings.sensitivity.degrees))°")
                    .font(Theme.Font.number(16)).foregroundStyle(Theme.Palette.accent)
            }
            segmented(Sensitivity.allCases, selected: settings.sensitivity, label: \.label) {
                settings.sensitivity = $0
                app.applySettings(settings)
                save()
            }
        }
        .padding(12)
        .background(Theme.Palette.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.chip))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.chip).stroke(Theme.Palette.ink.opacity(0.06)))
    }

    // MARK: Components

    private func sectionLabel(_ t: String) -> some View {
        Text(t.uppercased())
            .font(Theme.Font.label()).tracking(0.5)
            .foregroundStyle(Theme.Palette.inkFaint)
    }

    private func segmented<T: Hashable>(_ options: [T], selected: T,
                                        label: KeyPath<T, String>,
                                        onSelect: @escaping (T) -> Void) -> some View {
        HStack(spacing: 6) {
            ForEach(options, id: \.self) { opt in
                let isOn = opt == selected
                Button { onSelect(opt) } label: {
                    Text(opt[keyPath: label])
                        .font(Theme.Font.caption(13).weight(.semibold))
                        .foregroundStyle(isOn ? Theme.Palette.surface : Theme.Palette.ink)
                        .frame(maxWidth: .infinity).padding(.vertical, 9)
                        .background(isOn ? Theme.Palette.ink : .clear,
                                    in: RoundedRectangle(cornerRadius: 9))
                        .overlay(RoundedRectangle(cornerRadius: 9)
                            .stroke(isOn ? .clear : Theme.Palette.inkFaint.opacity(0.4)))
                }
                .pressable()
            }
        }
    }

    private func recalibrate() {
        app.engine.recalibrate()
        showCalibrate = true
    }

    private var waterTargetRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Daily goal")
                    .font(Theme.Font.body(14).weight(.semibold))
                    .foregroundStyle(Theme.Palette.ink)
                Spacer()
                Text(String(format: "%.2fL", settings.dailyWaterTargetMl / 1000))
                    .font(Theme.Font.number(15))
                    .foregroundStyle(Theme.Palette.accent)
            }
            Slider(value: Binding(
                get: { settings.dailyWaterTargetMl },
                set: { settings.dailyWaterTargetMl = $0; save() }
            ), in: 1000...4000, step: 250)
            .tint(Theme.Palette.accent)
        }
        .padding(12)
        .background(Theme.Palette.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.chip))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.chip).stroke(Theme.Palette.ink.opacity(0.06)))
    }

    private func save() { try? modelContext.save() }

    private var stepTargetRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Daily steps")
                    .font(Theme.Font.body(14).weight(.semibold))
                    .foregroundStyle(Theme.Palette.ink)
                Spacer()
                Text("\(settings.dailyStepTarget)")
                    .font(Theme.Font.number(15))
                    .foregroundStyle(Theme.Palette.drift)
            }
            Slider(value: Binding(
                get: { Double(settings.dailyStepTarget) },
                set: { settings.dailyStepTarget = Int($0); save() }
            ), in: 2000...15000, step: 500)
            .tint(Theme.Palette.drift)
        }
        .padding(12)
        .background(Theme.Palette.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.chip))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.chip).stroke(Theme.Palette.ink.opacity(0.06)))
    }

    private var sunlightRow: some View {
        Toggle(isOn: Binding(
            get: { settings.sunlightEnabled },
            set: {
                settings.sunlightEnabled = $0; save()
                if $0 {
                    Task { await app.sunlightScheduler.scheduleForToday() }
                } else {
                    app.sunlightScheduler.cancel()
                }
            }
        )) {
            VStack(alignment: .leading, spacing: 1) {
                Text("Sunlight nudges")
                    .font(Theme.Font.body(14).weight(.semibold))
                    .foregroundStyle(Theme.Palette.ink)
                Text("daylight-aware reminders")
                    .font(Theme.Font.caption(11))
                    .foregroundStyle(Theme.Palette.inkFaint)
            }
        }
        .tint(Theme.Palette.aligned)
        .padding(12)
        .background(Theme.Palette.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.chip))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.chip).stroke(Theme.Palette.ink.opacity(0.06)))
    }
}
