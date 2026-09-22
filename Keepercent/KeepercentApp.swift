// The app entry point. Opens on TeamsView (T3.1 item 7) — the teams list
// plus roster editor is now the app's real front door. ContentView is kept
// as the T2.x GoalView/CourtView hand-verification scaffold, reachable
// from TeamsView's toolbar rather than as the launch screen; see
// TeamsView.swift's header comment for why. See docs/mvp.md.

import SwiftUI
import SwiftData

@main
struct KeepercentApp: App {
    var body: some Scene {
        WindowGroup {
            TeamsView()
        }
        .modelContainer(KeepercentSchema.makeContainer())
    }
}
