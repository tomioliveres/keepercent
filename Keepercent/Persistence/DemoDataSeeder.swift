// DemoDataSeeder loads KeepercentDomain.DemoData into a SwiftData store, so
// the app has a one-tap "load demo data" action and the jury never opens an
// empty app (docs/mvp.md §8, §11).
//
// A thin shell over the SwiftData primitives the mapping types already
// expose (`StoredPlayer.init(_:)`, `StoredShot.init(_:shooter:facingGoalkeeper:)`):
// the encoding itself lives next to those types, this file only wires the
// relationships and decides whether to insert at all.

import Foundation
import SwiftData
import KeepercentDomain

enum DemoDataSeeder {
    /// Inserts `DemoData`'s rival team, roster, session and shots into
    /// `context`. Idempotent: if a rival team with `DemoData.rivalTeamName`
    /// already exists, this returns immediately instead of inserting a
    /// second copy, so tapping the demo action twice never duplicates data.
    static func seed(into context: ModelContext) throws {
        let demoTeamName = DemoData.rivalTeamName
        var descriptor = FetchDescriptor<StoredRivalTeam>(
            predicate: #Predicate { $0.name == demoTeamName }
        )
        descriptor.fetchLimit = 1
        guard try context.fetch(descriptor).isEmpty else { return }

        // One StoredPlayer per roster entry, keyed by shirt number so the
        // shots below can look up the same row a shooter/goalkeeper maps to
        // without inserting a player more than once.
        let storedPlayers = DemoData.roster.map(StoredPlayer.init)
        let storedPlayersByNumber = Dictionary(uniqueKeysWithValues: storedPlayers.map { ($0.number, $0) })

        let team = StoredRivalTeam(name: demoTeamName, players: storedPlayers)
        let session = StoredSession(
            date: DemoData.sessionDate,
            kindCode: DemoData.sessionKind.rawValue,
            rivalTeam: team
        )
        session.shots = DemoData.shots.map { shot in
            StoredShot(
                shot,
                shooter: shot.shooter.flatMap { storedPlayersByNumber[$0.number] },
                facingGoalkeeper: shot.facingGoalkeeper.flatMap { storedPlayersByNumber[$0.number] }
            )
        }
        team.sessions = [session]

        // Inserting the team is enough: SwiftData follows its relationships
        // (players, sessions, and each session's shots) and inserts every
        // reachable object in the same graph.
        context.insert(team)
        try context.save()
    }
}
