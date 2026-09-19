// Deliberately minimal placeholder. Product UI (court and goal views) starts
// in a later task; this screen only proves the app target links and runs
// against KeepercentDomain. See docs/mvp.md.

import SwiftUI
import KeepercentDomain

struct ContentView: View {
    /// Pulled from the domain package to prove the local package link works
    /// at runtime, not just at build time.
    private let goalTargetCount = GoalTarget.allCases.count

    var body: some View {
        VStack(spacing: 8) {
            Text("Keepercent")
                .font(.largeTitle.bold())
            Text("\(goalTargetCount) possible goal targets modeled")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
