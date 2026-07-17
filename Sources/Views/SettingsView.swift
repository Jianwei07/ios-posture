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

                    sectionLabel("Alerts")
                    alertsCard

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
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
                .toggleStyle(.switch)
            }
            .scrollContentBackground(.hidden)
            .background(Theme.Palette.bg.ignoresSafeArea())
            .navigationTitle("Settings")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
        .sheet(isPresented: $showCalibrate, onDismiss: {
            if app.engine.neutralPitch == nil, settings.baselinePitch != nil {
                app.engine.seedBaseline(settings.baselinePitch)
            }
        }) {
            CalibrateView(engine: app.engine, mode: .recalibrate) { baseline in
                if let b = baseline { settings.baselinePitch = b; save() }
                else { app.engine.seedBaseline(settings.baselinePitch) }
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
                Text("Compatible AirPods").font(Theme.Font.body(14).weight(.semibold)).foregroundStyle(Theme.Palette.ink)
                Text(connected ? "connected · tracking" : "not connected")
                    .font(Theme.Font.caption(11))
                    .foregroundStyle(connected ? Theme.Palette.accent : Theme.Palette.inkFaint)
            }
            Spacer()
        }
        .padding(12)
        .card()
    }

    // Alerts pane (design board section 03): master switch, the three-level
    // alert ladder, nudge timing, quiet hours.
    private var alertsCard: some View {
        let master = settings.softAlertsEnabled
        return VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: Binding(get: { settings.softAlertsEnabled },
                                 set: { settings.softAlertsEnabled = $0; save() })) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Soft alerts").font(Theme.Font.body(14).weight(.semibold)).foregroundStyle(Theme.Palette.ink)
                    Text("menu bar dot · chime · banner").font(Theme.Font.caption(11)).foregroundStyle(Theme.Palette.inkFaint)
                }
            }
            .tint(Theme.Palette.aligned)

            Divider()

            Group {
                // Level 1 is informational — the menu-bar dot never turns off.
                HStack {
                    alertRowTitle("Menu bar dot", caption: "always on · follows your posture")
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.Palette.aligned)
                }

                Toggle(isOn: Binding(get: { settings.chimeOnSustainedDrift },
                                     set: { settings.chimeOnSustainedDrift = $0; save() })) {
                    alertRowTitle("AirPods chime", caption: "on sustained drift")
                }
                .tint(Theme.Palette.aligned)

                Toggle(isOn: Binding(get: { settings.escalateLongSlouches },
                                     set: { settings.escalateLongSlouches = $0; save() })) {
                    alertRowTitle("Notification banner", caption: "if slouching continues past 6 min")
                }
                .tint(Theme.Palette.aligned)

                Stepper(value: Binding(get: { settings.nudgeAfterDriftSeconds },
                                       set: { settings.nudgeAfterDriftSeconds = $0; save() }),
                        in: 1...10, step: 1) {
                    HStack {
                        alertRowTitle("Nudge after sustained drift", caption: "how long drift lasts before the chime")
                        Spacer()
                        Text("\(Int(settings.nudgeAfterDriftSeconds)) sec")
                            .font(Theme.Font.number(14))
                            .foregroundStyle(Theme.Palette.accent)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        alertRowTitle("Chime volume", caption: "relative to your AirPods volume")
                        Spacer()
                        Text("\(Int((settings.chimeVolume * 100).rounded()))%")
                            .font(Theme.Font.number(14))
                            .foregroundStyle(Theme.Palette.accent)
                    }
                    Slider(value: Binding(
                        get: { settings.chimeVolume },
                        set: { settings.chimeVolume = min(1, max(0, $0)); save() }
                    ), in: 0...1, step: 0.05)
                    .tint(Theme.Palette.accent)
                }

                Toggle(isOn: Binding(get: { settings.quietHoursEnabled },
                                     set: { settings.quietHoursEnabled = $0; save() })) {
                    alertRowTitle("Quiet hours",
                                  caption: settings.quietHoursEnabled ? "no chimes or banners" : quietHoursCaption)
                }
                .tint(Theme.Palette.aligned)

                if settings.quietHoursEnabled {
                    HStack(spacing: 16) {
                        quietHoursPicker("From", minutes: Binding(
                            get: { settings.quietHoursStartMinutes },
                            set: { settings.quietHoursStartMinutes = $0; save() }
                        ))
                        quietHoursPicker("To", minutes: Binding(
                            get: { settings.quietHoursEndMinutes },
                            set: { settings.quietHoursEndMinutes = $0; save() }
                        ))
                        Spacer(minLength: 0)
                    }
                    .datePickerStyle(.compact)
                }
            }
            .disabled(!master)
            .opacity(master ? 1 : 0.45)
        }
        .padding(12)
        .card()
    }

    private func alertRowTitle(_ title: String, caption: String?) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(title).font(Theme.Font.body(14).weight(.semibold)).foregroundStyle(Theme.Palette.ink)
            if let caption {
                Text(caption).font(Theme.Font.caption(11)).foregroundStyle(Theme.Palette.inkFaint)
            }
        }
    }

    private var quietHoursCaption: String {
        let f = { (m: Int) in
            self.timeDate(fromMinutes: m).formatted(.dateTime.hour().minute())
        }
        return "\(f(settings.quietHoursStartMinutes)) – \(f(settings.quietHoursEndMinutes))"
    }

    private func quietHoursPicker(_ label: String, minutes: Binding<Int>) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .font(Theme.Font.caption(12))
                .foregroundStyle(Theme.Palette.inkSoft)
            DatePicker(label, selection: Binding(
                get: { timeDate(fromMinutes: minutes.wrappedValue) },
                set: { minutes.wrappedValue = minutesOfDay(from: $0) }
            ), displayedComponents: .hourAndMinute)
            .labelsHidden()
        }
    }

    private func timeDate(fromMinutes m: Int) -> Date {
        Calendar.current.date(bySettingHour: m / 60, minute: m % 60, second: 0, of: .now) ?? .now
    }

    private func minutesOfDay(from date: Date) -> Int {
        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (c.hour ?? 0) * 60 + (c.minute ?? 0)
    }

    private var sensitivityCard: some View {
        VStack(spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Nudges when you lean past").font(Theme.Font.caption()).foregroundStyle(Theme.Palette.inkFaint)
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
        .card()
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
                    .font(Theme.Font.number(14))
                    .foregroundStyle(Theme.Palette.accent)
            }
            Slider(value: Binding(
                get: { settings.dailyWaterTargetMl },
                set: { settings.dailyWaterTargetMl = $0; save() }
            ), in: 1000...4000, step: 250)
            .tint(Theme.Palette.accent)
        }
        .padding(12)
        .card()
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
                    .font(Theme.Font.number(14))
                    .foregroundStyle(Theme.Palette.drift)
            }
            Slider(value: Binding(
                get: { Double(settings.dailyStepTarget) },
                set: { settings.dailyStepTarget = Int($0); save() }
            ), in: 2000...15000, step: 500)
            .tint(Theme.Palette.drift)
        }
        .padding(12)
        .card()
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
        .card()
    }
}
