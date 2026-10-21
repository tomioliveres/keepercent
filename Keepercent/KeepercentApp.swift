// The app entry point. AppNavigationView opens on Matches and owns demo seeding.
// Debug launch routes continue to use their isolated, explicitly seeded store.

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
            } else if debugLaunch.data == .demoOwnRoster {
                do {
                    try DemoDataSeeder.seedOwnRosterVerification(into: isolated.mainContext)
                } catch {
                    fatalError("Failed to seed the own-roster debug fixture: \(error)")
                }
            } else if debugLaunch.data == .orphanSession {
                // Represent the retained state after a rival is deleted, without
                // deleting anything or opening the user's persistent store.
                isolated.mainContext.insert(
                    StoredSession(
                        date: DemoData.sessionDate,
                        kindCode: SessionKind.live.rawValue,
                        rivalTeam: nil
                    )
                )
                do {
                    try isolated.mainContext.save()
                } catch {
                    fatalError("Failed to seed the orphan-session debug fixture: \(error)")
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
                AppNavigationView()
            }
            #else
            AppNavigationView()
            #endif
        }
        .modelContainer(container)
    }
}
