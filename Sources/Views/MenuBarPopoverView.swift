#if os(macOS)
import SwiftUI
import SwiftData

// Menu-bar popover (design board section 02, locked): 318 pt Sage card that
// answers "am I aligned · water & walk · are alerts on" at a glance, with
// Recalibrate / Open app / Quit in the footer. Window-style MenuBarExtra —
// the macOS equivalent of a transient NSPopover.
struct MenuBarPopoverView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openWindow) private var openWindow

    @Query private var settingsArray: [UserSettings]
    @Query(sort: \WaterEntry.timestamp, order: .reverse) private var waterEntries: [WaterEntry]

    private var settings: UserSettings? { settingsArray.first }

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 15)
                .padding(.top, 13)
                .padding(.bottom, 10)

            heroCard
                .padding(.horizontal, 15)

            HStack(spacing: 10) {
                waterCard
                walkCard
            }
            .padding(.horizontal, 15)
            .padding(.top, 10)

            softAlertsRow
                .padding(.horizontal, 15)
                .padding(.vertical, 10)

            footer
        }
        .frame(width: 318)
        .background(Theme.Palette.bg)
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 8) {
            Text("Posture")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Theme.Palette.ink)

            Spacer()

            HStack(spacing: 5) {
                Circle()
                    .fill(app.isConnected ? Theme.Palette.accent : Theme.Palette.inkFaint)
                    .frame(width: 6, height: 6)
                Text(app.isConnected ? "AirPods on" : "AirPods off")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(app.isConnected ? Theme.Palette.accent : Theme.Palette.inkFaint)
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 3)
            .background(
                Capsule().fill((app.isConnected ? Theme.Palette.accent : Theme.Palette.inkFaint).opacity(0.10))
            )
            .overlay(
                Capsule().stroke((app.isConnected ? Theme.Palette.accent : Theme.Palette.inkFaint).opacity(0.30))
            )

            Button {
                openWindow(id: "main")
                NSApp.activate(ignoringOtherApps: true)
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.Palette.inkSoft)
            }
            .buttonStyle(.plain)
            .help("Open app settings")
        }
    }

    // MARK: Hero

    private var stateColor: Color {
        switch app.menuBarState {
        case .idle:    return Theme.Palette.inkFaint
        case .aligned: return Theme.Palette.aligned
        case .drift:   return Theme.Palette.drift
        case .wilt:    return Theme.Palette.slouch
        }
    }

    private var stateWord: String {
        switch app.menuBarState {
        case .idle:    return "Not tracking"
        case .aligned: return "Aligned"
        case .drift:   return "Easing forward"
        case .wilt:    return "Wilting"
        }
    }

    private var stateSubcopy: String {
        switch app.menuBarState {
        case .idle:    return app.isConnected ? "Put AirPods in to start." : "Connect AirPods to start."
        case .aligned: return "Standing tall — nice."
        case .drift:   return "Gently sit tall."
        case .wilt:    return "Time to reset & water."
        }
    }

    private var stateStat: String? {
        switch app.menuBarState {
        case .idle:
            return nil
        case .aligned:
            return "\(Int(app.session.activeSessionSeconds / 60)) min upright today"
        case .drift, .wilt:
            return "−\(Int(app.engine.forwardAngle.rounded()))° · \(app.nonAlignedMinutes) min"
        }
    }

    private var heroCard: some View {
        HStack(spacing: 16) {
            PlantMascot(kind: settings?.selectedPlant ?? .sunflower,
                        bend: app.liveBend,
                        color: stateColor)
                .frame(width: 58, height: 76)
                .overlay {
                    if app.isWateredPerkActive { WaterPerkOverlay() }
                }
                .animation(Theme.Motion.fade, value: app.isWateredPerkActive)

            VStack(alignment: .leading, spacing: 1) {
                Text(stateWord)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(stateColor)
                Text(stateSubcopy)
                    .font(.system(size: 13.5))
                    .foregroundStyle(Theme.Palette.inkSoft)
                if let stat = stateStat {
                    Text(stat)
                        .font(.system(size: 13, weight: .semibold).monospacedDigit())
                        .foregroundStyle(Theme.Palette.inkFaint)
                        .padding(.top, 6)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Theme.Palette.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Theme.Palette.inkFaint.opacity(0.20))
        )
    }

    // MARK: Water / Walk

    private var todayWaterMl: Double {
        let start = Calendar.current.startOfDay(for: .now)
        return waterEntries.filter { $0.timestamp >= start }.reduce(0) { $0 + $1.volumeMl }
    }

    private var waterCard: some View {
        let targetMl = settings?.dailyWaterTargetMl ?? 2000
        let glasses = Int(todayWaterMl / 250)
        let targetGlasses = max(1, Int(targetMl / 250))

        return VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 9) {
                ProgressRing(progress: targetMl > 0 ? todayWaterMl / targetMl : 0,
                             color: Theme.Palette.accent)
                VStack(alignment: .leading, spacing: 0) {
                    Text("Water")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.Palette.inkSoft)
                    (Text("\(glasses)").font(.system(size: 15, weight: .bold).monospacedDigit())
                        + Text(" / \(targetGlasses)").font(.system(size: 12, weight: .semibold).monospacedDigit())
                            .foregroundStyle(Theme.Palette.inkFaint))
                        .foregroundStyle(Theme.Palette.ink)
                }
            }
            Button {
                app.noteWaterLogged()
                modelContext.insert(WaterEntry())
            } label: {
                Text("+ Glass")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 9).fill(Theme.Palette.accent))
            }
            .buttonStyle(.plain)
            .pressable()
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 13).fill(Theme.Palette.surface))
        .overlay(RoundedRectangle(cornerRadius: 13).stroke(Theme.Palette.inkFaint.opacity(0.20)))
    }

    private var walkCard: some View {
        let intervalMin = settings?.baseWalkIntervalMin ?? 45
        let minutesLeft = app.scheduler.minutesUntilWalk(sessionSeconds: app.session.activeSessionSeconds)
        let progress = intervalMin > 0 ? 1 - Double(minutesLeft) / intervalMin : 0

        return VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 9) {
                ProgressRing(progress: progress, color: Theme.Palette.drift)
                VStack(alignment: .leading, spacing: 0) {
                    Text("Walk")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.Palette.inkSoft)
                    (Text("in \(minutesLeft)").font(.system(size: 15, weight: .bold).monospacedDigit())
                        + Text(" min").font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Theme.Palette.inkFaint))
                        .foregroundStyle(Theme.Palette.ink)
                }
            }
            Text("Every \(Int(intervalMin))m")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.Palette.inkFaint)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 9).fill(Theme.Palette.ink.opacity(0.06)))
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 13).fill(Theme.Palette.surface))
        .overlay(RoundedRectangle(cornerRadius: 13).stroke(Theme.Palette.inkFaint.opacity(0.20)))
    }

    // MARK: Soft alerts

    private var softAlertsRow: some View {
        HStack(spacing: 10) {
            Text("Soft alerts")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.Palette.ink)
            Text("chime only")
                .font(.system(size: 12))
                .foregroundStyle(Theme.Palette.inkFaint)

            Spacer()

            HStack(spacing: 0) {
                segment("Gentle", isOn: settings?.softAlertsEnabled ?? true) {
                    settings?.softAlertsEnabled = true
                }
                segment("Off", isOn: !(settings?.softAlertsEnabled ?? true)) {
                    settings?.softAlertsEnabled = false
                }
            }
            .padding(2)
            .background(RoundedRectangle(cornerRadius: 9).fill(Theme.Palette.ink.opacity(0.08)))
        }
    }

    private func segment(_ label: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 11.5, weight: .semibold))
                .foregroundStyle(isOn ? Theme.Palette.accent : Theme.Palette.inkFaint)
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 7)
                        .fill(isOn ? Theme.Palette.surface : .clear)
                        .shadow(color: .black.opacity(isOn ? 0.08 : 0), radius: 1, y: 1)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: Footer

    private var footer: some View {
        HStack(spacing: 2) {
            footerButton("Recalibrate") {
                openWindow(id: "main")
                NSApp.activate(ignoringOtherApps: true)
                NotificationCenter.default.post(name: .recalibrateRequested, object: nil)
            }
            footerDivider
            footerButton("Open app", emphasized: true) {
                openWindow(id: "main")
                NSApp.activate(ignoringOtherApps: true)
            }
            footerDivider
            footerButton("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(8)
        .background(Theme.Palette.ink.opacity(0.04))
        .overlay(alignment: .top) {
            Rectangle().fill(Theme.Palette.inkFaint.opacity(0.25)).frame(height: 1)
        }
    }

    private var footerDivider: some View {
        Rectangle()
            .fill(Theme.Palette.inkFaint.opacity(0.35))
            .frame(width: 1, height: 16)
    }

    private func footerButton(_ label: String, emphasized: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12.5, weight: emphasized ? .semibold : .medium))
                .foregroundStyle(emphasized ? Theme.Palette.ink : Theme.Palette.inkSoft)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .contentShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

// Small determinate ring used by the water/walk cards.
private struct ProgressRing: View {
    let progress: Double
    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.18), lineWidth: 4)
            Circle()
                .trim(from: 0, to: min(1, max(0, progress)))
                .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: 30, height: 30)
    }
}
#endif
