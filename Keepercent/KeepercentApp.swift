// The app entry point. Opens on TeamsView (T3.1 item 7) — the teams list
// plus roster editor is now the app's real front door. ContentView is kept
// as the T2.x GoalView/CourtView hand-verification scaffold, reachable
// from TeamsView's toolbar rather than as the launch screen; see
// TeamsView.swift's header comment for why. See docs/mvp.md.

import SwiftUI
import SwiftData
import KeepercentDomain

@main
struct KeepercentApp: App {
    #if DEBUG
    private let debugLaunch = DebugLaunchConfiguration.parse(
        screen: UserDefaults.standard.string(forKey: "KPScreen"),
        data: UserDefaults.standard.string(forKey: "KPData")
    )
    #endif

    private let container: ModelContainer

    init() {
        #if DEBUG
        if let debugLaunch {
            // Never create or open the user's persistent store in argument mode.
            let isolated = KeepercentSchema.makeContainer(inMemory: true)
            if debugLaunch.data == .demo {
                do {
                    try DemoDataSeeder.seed(into: isolated.mainContext)
                } catch {
                    fatalError("Failed to seed the debug store: \(error)")
                }
            } else if debugLaunch.data == .emptyGoalkeeper {
                let goalkeeper = StoredPlayer(
                    number: 1, name: nil, isGoalkeeper: true, handednessCode: nil
                )
                isolated.mainContext.insert(
                    StoredRivalTeam(name: "Unscouted Rival", players: [goalkeeper])
                )
                do {
                    try isolated.mainContext.save()
                } catch {
                    fatalError("Failed to seed the zero-shot debug fixture: \(error)")
                }
            }
            container = isolated
        } else {
            container = KeepercentSchema.makeContainer()
        }
        #else
        container = KeepercentSchema.makeContainer()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            #if DEBUG
            if let debugLaunch {
                DebugLaunchView(configuration: debugLaunch)
            } else {
                TeamsView()
            }
            #else
            TeamsView()
            #endif
        }
        .modelContainer(container)
    }
}
