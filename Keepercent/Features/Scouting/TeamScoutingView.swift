// TeamScoutingView is the CONTAINER that hosts T4.2's linked court/goal
// view for a whole rival team, so it can be run by hand until T4.3/T4.4
// narrow it to one shooter / one goalkeeper (CLAUDE.md container/
// presentational split: this file owns the SwiftData reads, its child
// `LinkedZonesView` only ever sees a `StatsEngine`).
//
// Shots come from every session recorded against this team, decoded
// through `StoredShot.domainShot` — a corrupt row decodes to nil and is
// dropped rather than skewing the stats (same contract `ShotLogView` and
// `RosterEditorView` already rely on).
//
// The reading picker decides which side of the engine feeds the view:
// Effectiveness reads `rivalShots` (the shooter card's data — goals scored
// BY the rival), Save rate reads `ownShots` (the goalkeeper card's data —
// shots faced BY the own team's keeper), matching `StatsEngine`'s own
// `attackingSide` filters.

import SwiftUI
import KeepercentDomain

struct TeamScoutingView: View {
    let team: StoredRivalTeam

    @State private var reading: StatsReading = .effectiveness
    @State private var selection: ShotOrigin?

    /// Every shot recorded across this team's sessions, decoded from
    /// SwiftData. Built fresh from `team.sessions` rather than cached in
    /// `@State`: this container has no write path of its own, so there is
    /// nothing to keep in sync besides what SwiftData already tracks.
    private var engine: StatsEngine {
        let shots = team.sessions.flatMap { $0.shots.compactMap(\.domainShot) }
        return StatsEngine(shots: shots)
    }

    /// The engine `LinkedZonesView` actually reads: the rival's own shots
    /// for the shooter card's reading, the own team's for the goalkeeper
    /// card's — see this file's header comment.
    private var readingEngine: StatsEngine {
        switch reading {
        case .effectiveness: return engine.rivalShots
        case .saveRate: return engine.ownShots
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Picker("Reading", selection: $reading) {
                    Text("Effectiveness").tag(StatsReading.effectiveness)
                    Text("Save rate").tag(StatsReading.saveRate)
                }
                .pickerStyle(.segmented)
                // Switching readings changes which shots the goal side
                // (and the charts under it) show; a leftover origin
                // selected under the OTHER reading would silently narrow
                // a filter the scout never chose under this one.
                .onChange(of: reading) { selection = nil }

                LinkedZonesView(engine: readingEngine, reading: reading, selection: $selection)
            }
            .padding()
        }
        .navigationTitle("Scouting")
    }
}
