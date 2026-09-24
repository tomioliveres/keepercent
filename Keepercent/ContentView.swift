// Deliberately minimal scaffold. This is NOT the real shot-entry screen —
// that is T3.3. It exists only so GoalView's and CourtView's drawing and
// hit-testing — including selection highlighting (T2.3) — can be verified
// on the simulator right now, ahead of the real screen being built. It
// shows both views, keeps the last tapped target/origin as its own
// `@State` (this scaffold IS a container, so that is exactly where
// selection state belongs per CLAUDE.md's container/presentational rule),
// passes it back down as `selection` so a tap now also highlights, and
// prints the tapped value's code as plain text so a tap can still be
// verified without reading the drawing.
//
// Since T3.1, the app's launch screen is TeamsView, not this scaffold — it
// is reachable via the team's secondary toolbar action. The debug launch
// router below is separate from the scaffold and excluded from release.

import SwiftUI
import KeepercentDomain
#if DEBUG
import SwiftData
#endif

struct ContentView: View {
    /// Pulled from the domain package to prove the local package link works
    /// at runtime, not just at build time.
    private let goalTargetCount = GoalTarget.allCases.count

    /// The last tapped target, fed back into `GoalView` as `selection` so a
    /// tap now also highlights (T2.3), and shown as plain text (via
    /// `.code`) so a tap can still be verified on the simulator without
    /// reading the drawing.
    @State private var lastTappedTarget: GoalTarget?

    /// Same purpose as `lastTappedTarget` above, for `CourtView`.
    @State private var lastTappedOrigin: ShotOrigin?

    var body: some View {
        VStack(spacing: 16) {
            Text("Keepercent")
                .font(.largeTitle.bold())
            Text("\(goalTargetCount) possible goal targets modeled")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            GoalView(selection: lastTappedTarget) { target in
                lastTappedTarget = target
            }
            .padding(.horizontal)

            Text(lastTappedTarget.map { "Last tap: \($0.code)" } ?? "Tap the goal to try it")
                .font(.callout.monospaced())
                .foregroundStyle(.secondary)

            CourtView(selection: lastTappedOrigin) { origin, _ in
                lastTappedOrigin = origin
            }
            .padding(.horizontal)

            Text(lastTappedOrigin.map { "Last tap: \($0.code)" } ?? "Tap the court to try it")
                .font(.callout.monospaced())
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}

#if DEBUG
/// Routes a launch argument directly to an existing screen in an isolated
/// SwiftData store. Empty data keeps the requested route visible without
/// inventing a team, session, or player that does not exist.
struct DebugLaunchView: View {
    let configuration: DebugLaunchConfiguration
    @Query(sort: \StoredRivalTeam.name) private var teams: [StoredRivalTeam]

    private var team: StoredRivalTeam? { teams.first }

    var body: some View {
        Group {
            if configuration.screen == .teams {
                TeamsView(seedDemoDataOnAppear: false)
            } else {
                NavigationStack {
                    destination
                }
            }
        }
    }

    @ViewBuilder
    private var destination: some View {
        switch configuration.screen {
        case .teams:
            // Handled before creating the navigation stack.
            EmptyView()
        case .sessions:
            if let team, let session = team.sessions.sorted(by: { $0.date > $1.date }).first {
                SessionView(team: team, session: session)
            } else {
                unavailable("No Sessions", description: "No scouting sessions are available.")
            }
        case .scouting:
            if let team {
                TeamScoutingView(team: team)
            } else {
                unavailable("No Scouting Data", description: "Add a rival team to view scouting data.")
            }
        case .shooterCard:
            if let team, let number = team.sessions.flatMap(\.shots)
                .compactMap({ $0.shooter?.number }).sorted().first {
                ShooterCardView(team: team, playerNumber: number)
            } else {
                unavailable("No Shooter Data", description: "No rival shooter has recorded shots.")
            }
        case .goalkeeperCard:
            if let team, let number = team.sessions.flatMap(\.shots)
                .compactMap({ $0.facingGoalkeeper?.number }).sorted().first {
                GoalkeeperCardView(team: team, playerNumber: number)
            } else {
                unavailable("No Goalkeeper Data", description: "No rival goalkeeper has faced shots.")
            }
        }
    }

    private func unavailable(_ title: String, description: String) -> some View {
        ContentUnavailableView(title, systemImage: "chart.bar.xaxis", description: Text(description))
            .navigationTitle(title)
    }
}
#endif
