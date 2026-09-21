// Deliberately minimal scaffold. This is NOT the real shot-entry screen —
// that is T3.3. It exists only so GoalView's and CourtView's drawing and
// hit-testing can be verified on the simulator right now, ahead of the
// real screen being built. It shows both views and, as plain text, the
// code of the last target/origin that was tapped on each.

import SwiftUI
import KeepercentDomain

struct ContentView: View {
    /// Pulled from the domain package to prove the local package link works
    /// at runtime, not just at build time.
    private let goalTargetCount = GoalTarget.allCases.count

    /// The last tapped target's code (e.g. "inside.top.left"), shown as
    /// plain text so a tap can be verified on the simulator. This is a
    /// scaffold concern only — GoalView itself stays stateless.
    @State private var lastTappedTargetCode: String?

    /// The last tapped origin's code (e.g. "zone.leftWing.near" or
    /// "sevenMeters"), same purpose as `lastTappedTargetCode` above but for
    /// `CourtView`.
    @State private var lastTappedOriginCode: String?

    var body: some View {
        VStack(spacing: 16) {
            Text("Keepercent")
                .font(.largeTitle.bold())
            Text("\(goalTargetCount) possible goal targets modeled")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            GoalView { target in
                lastTappedTargetCode = target.code
            }
            .padding(.horizontal)

            Text(lastTappedTargetCode.map { "Last tap: \($0)" } ?? "Tap the goal to try it")
                .font(.callout.monospaced())
                .foregroundStyle(.secondary)

            CourtView { origin in
                lastTappedOriginCode = origin.code
            }
            .padding(.horizontal)

            Text(lastTappedOriginCode.map { "Last tap: \($0)" } ?? "Tap the court to try it")
                .font(.callout.monospaced())
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
