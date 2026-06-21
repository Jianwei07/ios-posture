import SwiftUI
import SwiftData
import Charts

struct HistoryView: View {
    @Query(sort: \PostureSession.startTime, order: .reverse)
    private var sessions: [PostureSession]

    var body: some View {
        NavigationStack {
            Group {
                if sessions.isEmpty {
                    ContentUnavailableView(
                        "No Sessions Yet",
                        systemImage: "figure.stand",
                        description: Text("Complete a session with AirPods Pro to see history.")
                    )
                } else {
                    List(sessions) { session in
                        NavigationLink(destination: SessionDetailView(session: session)) {
                            SessionRowView(session: session)
                        }
                    }
                }
            }
            .navigationTitle("History")
        }
    }
}

struct SessionRowView: View {
    let session: PostureSession

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.startTime, style: .date)
                    .font(.subheadline.bold())
                Text(session.startTime, style: .time)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                ScoreBadge(score: session.score)
                Text(formatDuration(session.durationSeconds))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        return "\(mins)m"
    }
}

struct ScoreBadge: View {
    let score: Int

    var body: some View {
        Text("\(score)")
            .font(.caption.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color, in: Capsule())
    }

    private var color: Color {
        switch score {
        case 80...: return .green
        case 50..<80: return .orange
        default: return .red
        }
    }
}

struct SessionDetailView: View {
    let session: PostureSession

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                statsRow
                pitchChart
            }
            .padding()
        }
        .navigationTitle(session.startTime.formatted(date: .abbreviated, time: .shortened))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var statsRow: some View {
        Grid(horizontalSpacing: 16) {
            GridRow {
                statCell(label: "Score", value: "\(session.score)")
                statCell(label: "Avg Pitch", value: String(format: "%.1f°", session.avgPitch))
                statCell(label: "Poor", value: "\(Int(session.poorPosturePct * 100))%")
            }
        }
    }

    private func statCell(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.title3.bold())
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
    }

    private var pitchChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Pitch over time")
                .font(.subheadline.bold())

            Chart(session.readings.suffix(300), id: \.timestamp) { reading in
                LineMark(
                    x: .value("Time", reading.timestamp),
                    y: .value("Pitch", reading.pitch)
                )
                .foregroundStyle(color(for: reading.classification))
            }
            .chartYAxis {
                AxisMarks(values: [-30, -20, -10, 0, 10, 20])
            }
            .frame(height: 200)
        }
    }

    private func color(for classification: String) -> Color {
        switch classification {
        case "poor":    return .red
        case "warning": return .orange
        default:        return .green
        }
    }
}
