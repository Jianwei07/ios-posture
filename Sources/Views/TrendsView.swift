import SwiftUI
import SwiftData

// Trends — read-only history. Three KPIs + a stacked hourly timeline built from
// the downsampled PostureReadings. See design.md.
struct TrendsView: View {
    @Query(sort: \PostureSession.startTime, order: .reverse) private var sessions: [PostureSession]

    private var todayReadings: [PostureReading] {
        let start = Calendar.current.startOfDay(for: .now)
        return sessions.flatMap { $0.readings }.filter { $0.timestamp >= start }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Today").font(Theme.Font.title(22)).foregroundStyle(Theme.Palette.ink)
                        Spacer()
                        Text(Date.now.formatted(.dateTime.weekday(.abbreviated).month().day()))
                            .font(Theme.Font.body(13)).foregroundStyle(Theme.Palette.inkFaint)
                    }

                    HStack(spacing: 8) {
                        kpi(uprightPct, "upright", Theme.Palette.aligned)
                        kpi("\(nudges)", "nudges", Theme.Palette.drift)
                        kpi(bestRun, "best run", Theme.Palette.ink)
                    }

                    timelineCard

                    Text("Earlier this week")
                        .font(Theme.Font.caption()).foregroundStyle(Theme.Palette.inkFaint)
                    if weekSessions.isEmpty {
                        emptyRow("No earlier sessions yet")
                    } else {
                        ForEach(weekSessions) { s in sessionRow(s) }
                    }
                }
                .padding(20)
            }
            .scrollContentBackground(.hidden)
            .background(Theme.Palette.bg.ignoresSafeArea())
            .navigationTitle("Trends")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: KPIs

    private func kpi(_ value: String, _ label: String, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value).font(Theme.Font.number(17)).foregroundStyle(color)
            Text(label).font(Theme.Font.caption(10)).foregroundStyle(Theme.Palette.inkFaint)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 11)
        .background(Theme.Palette.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.chip))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.chip).stroke(Theme.Palette.ink.opacity(0.06)))
    }

    private var uprightPct: String {
        let r = todayReadings
        guard !r.isEmpty else { return "—" }
        let up = r.filter { $0.classification == PostureState.aligned.rawValue }.count
        return "\(Int(Double(up) / Double(r.count) * 100))%"
    }

    // Count of distinct slouch episodes today (transitions into slouch).
    private var nudges: Int {
        let r = todayReadings.sorted { $0.timestamp < $1.timestamp }
        var count = 0, wasSlouch = false
        for reading in r {
            let isSlouch = reading.classification == PostureState.slouch.rawValue
            if isSlouch && !wasSlouch { count += 1 }
            wasSlouch = isSlouch
        }
        return count
    }

    private var bestRun: String {
        let start = Calendar.current.startOfDay(for: .now)
        let today = sessions.filter { $0.startTime >= start }
        guard let longest = today.map(\.durationSeconds).max(), longest > 0 else { return "—" }
        let m = Int(longest) / 60
        return m >= 60 ? "\(m / 60)h\(String(format: "%02d", m % 60))" : "\(m)m"
    }

    // MARK: Timeline

    private var timelineCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("posture through the day")
                .font(Theme.Font.caption()).foregroundStyle(Theme.Palette.inkFaint)
            HStack(alignment: .bottom, spacing: 3) {
                ForEach(0..<12, id: \.self) { i in barColumn(hourBucket(i)) }
            }
            .frame(height: 96)
            HStack(spacing: 10) {
                legend(Theme.Palette.aligned, "up")
                legend(Theme.Palette.drift, "drift")
                legend(Theme.Palette.slouch, "slouch")
            }
            .padding(.top, 6)
            .overlay(Divider(), alignment: .top)
        }
        .padding(12)
        .background(Theme.Palette.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.card))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.card).stroke(Theme.Palette.ink.opacity(0.06)))
    }

    private func barColumn(_ pct: (up: Double, drift: Double, slouch: Double)) -> some View {
        let total = max(0.001, pct.up + pct.drift + pct.slouch)
        let hasData = pct.up + pct.drift + pct.slouch > 0.01
        return GeometryReader { geo in
            let h = geo.size.height
            VStack(spacing: 0) {
                Rectangle().fill(Theme.Palette.aligned).frame(height: h * pct.up / total)
                Rectangle().fill(Theme.Palette.drift).frame(height: h * pct.drift / total)
                Rectangle().fill(Theme.Palette.slouch).frame(height: h * pct.slouch / total)
            }
            .frame(maxHeight: .infinity, alignment: .bottom)
            .clipShape(RoundedRectangle(cornerRadius: 3))
            .opacity(hasData ? 1 : 0.12)
        }
        .frame(maxWidth: .infinity)
    }

    // Two-hour buckets (12 columns across the day) of aligned/drift/slouch share.
    private func hourBucket(_ index: Int) -> (up: Double, drift: Double, slouch: Double) {
        let cal = Calendar.current
        let inBucket = todayReadings.filter {
            let h = cal.component(.hour, from: $0.timestamp)
            return h / 2 == index
        }
        guard !inBucket.isEmpty else { return (0, 0, 0) }
        func share(_ s: PostureState) -> Double {
            Double(inBucket.filter { $0.classification == s.rawValue }.count) / Double(inBucket.count)
        }
        // layoutPriority needs non-zero to give the segment any height
        return (max(0.001, share(.aligned)), max(0.001, share(.drift)), max(0.001, share(.slouch)))
    }

    private func legend(_ c: Color, _ t: String) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2).fill(c).frame(width: 8, height: 8)
            Text(t).font(Theme.Font.caption(10)).foregroundStyle(Theme.Palette.inkSoft)
        }
    }

    // MARK: Week list

    private var weekSessions: [PostureSession] {
        let start = Calendar.current.startOfDay(for: .now)
        return sessions.filter { $0.endTime != nil && $0.startTime < start }.prefix(7).map { $0 }
    }

    private func sessionRow(_ s: PostureSession) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(s.startTime.formatted(.dateTime.weekday(.abbreviated).hour().minute()))
                    .font(Theme.Font.body(13)).foregroundStyle(Theme.Palette.ink)
                Text("\(Int(s.durationSeconds / 60)) min")
                    .font(Theme.Font.caption(11)).foregroundStyle(Theme.Palette.inkFaint)
            }
            Spacer()
            Text("\(s.score)")
                .font(Theme.Font.number(15)).foregroundStyle(scoreColor(s.score))
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(scoreColor(s.score).opacity(0.14), in: Capsule())
        }
        .padding(12)
        .background(Theme.Palette.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.chip))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.chip).stroke(Theme.Palette.ink.opacity(0.06)))
    }

    private func scoreColor(_ score: Int) -> Color {
        switch score {
        case 80...: return Theme.Palette.aligned
        case 55..<80: return Theme.Palette.drift
        default: return Theme.Palette.slouch
        }
    }

    private func emptyRow(_ text: String) -> some View {
        Text(text)
            .font(Theme.Font.body(13)).foregroundStyle(Theme.Palette.inkFaint)
            .frame(maxWidth: .infinity).padding(.vertical, 18)
            .background(Theme.Palette.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.chip))
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.chip)
                .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [5]))
                .foregroundStyle(Theme.Palette.ink.opacity(0.12)))
    }
}
