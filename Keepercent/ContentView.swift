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
// Since T3.1, the app's launch screen is TeamsView, not this file — this
// scaffold is reachable from there via a secondary toolbar action
// ("Drawing Scaffold (T2.x)"), unchanged otherwise.

import SwiftUI
import KeepercentDomain

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

            CourtView(selection: lastTappedOrigin) { origin in
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
