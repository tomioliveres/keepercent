// The app entry point. Kept intentionally minimal: real UI (court, goal,
// shot entry) starts in a later task. See docs/mvp.md.

import SwiftUI
import SwiftData

@main
struct KeepercentApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(KeepercentSchema.makeContainer())
    }
}
