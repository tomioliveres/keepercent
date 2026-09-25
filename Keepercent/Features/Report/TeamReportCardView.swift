import SwiftUI
import KeepercentDomain

/// The same fixed-width SwiftUI drawing is used on screen and by ImageRenderer.
struct TeamReportCardView: View {
    let goalkeeperNumber: Int
    let engine: StatsEngine
    @Environment(\.colorScheme) private var colorScheme

    private var field: StatsEngine { engine.fieldShots }
    private var sevenMeters: Tally { engine.sevenMeterShots.saveRate }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("KEEPERCENT · TEAM REPORT")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Text("Where to shoot / where not to")
                    .font(.title3.bold())
                Text("Against goalkeeper #\(goalkeeperNumber)")
                    .font(.subheadline)
                Text("Shooter's view · left and right face the goal")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text("Field shots: \(field.shots.count) attempts · \(field.saveRate.attempts) on target")
                .font(.subheadline.weight(.semibold))

            if field.saveRate.attempts == 0 {
                Text("No field shots on target recorded. No shooting zones can be inferred yet.")
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Goal zones").font(.headline)
                    Text("Goals / saves, each from recorded shots on target")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ForEach(GoalRow.allCases, id: \.self) { row in
                        HStack(spacing: 6) {
                            ForEach(GoalColumn.allCases, id: \.self) { column in
                                zoneCell(GoalZone(row: row, column: column))
                            }
                        }
                    }
                }

                zoneList(title: "Where goals went in", entries: field.weakGoalZones(limit: 3), unit: "goals")
                zoneList(title: "Where shots were saved", entries: field.strongGoalZones(limit: 3), unit: "saves")
                Text("A zone can appear in both lists. These counts describe observed shots, not future outcomes.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()
            Text(sevenMeters.attempts == 0
                 ? "7 m throws: no shots on target recorded"
                 : "7 m throws: \(sevenMeters.attempts - sevenMeters.successes) goals · \(sevenMeters.successes) saves / \(sevenMeters.attempts) on target")
                .font(.caption)
            Text("Only shots faced by #\(goalkeeperNumber) are included. Frame hits and misses are not goal-zone samples.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(width: 320, alignment: .leading)
        .background(Color(.systemBackground))
        .foregroundStyle(.primary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.secondary.opacity(0.25)))
    }

    private func zoneCell(_ zone: GoalZone) -> some View {
        let tally = field.saveRateByGoalZone[zone]
        let goals = (tally?.attempts ?? 0) - (tally?.successes ?? 0)
        let saves = tally?.successes ?? 0
        return VStack(spacing: 3) {
            Text(zone.displayName)
                .font(.caption2)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(tally == nil ? "—" : "\(goals) / \(saves)")
                .font(.caption.bold().monospacedDigit())
        }
        .frame(maxWidth: .infinity)
        .frame(height: 54)
        .background(HeatmapColor.tint(for: tally, appearance: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .accessibilityLabel("\(zone.displayName): \(tally == nil ? "no on-target shots" : "\(goals) goals, \(saves) saves")")
    }

    private func zoneList(title: String, entries: [RankedTally<GoalZone>], unit: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.headline)
            if entries.isEmpty {
                Text("None recorded").foregroundStyle(.secondary)
            } else {
                ForEach(entries, id: \.key) { entry in
                    HStack {
                        Text(entry.key.displayName)
                        Spacer()
                        Text("\(entry.tally.successes) \(unit) / \(entry.tally.attempts) on target")
                            .monospacedDigit()
                    }
                    .font(.caption)
                }
            }
        }
    }
}
