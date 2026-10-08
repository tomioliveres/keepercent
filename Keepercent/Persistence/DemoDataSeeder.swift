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
    /// Verification-only companion to the rival fixture. Never attach today's
    /// own roster to existing matches or retrofit their unknown attribution.
    static func seedOwnRosterVerification(into context: ModelContext) throws {
        try seed(into: context)
        var descriptor = FetchDescriptor<StoredOwnTeam>()
        descriptor.fetchLimit = 1
        // Respect any configured club, including edits made during verification.
        guard try context.fetch(descriptor).isEmpty else { return }
        let club = StoredOwnTeam(
            name: DemoData.verificationOwnTeamName, createdAt: DemoData.sessionDate
        )
        club.players = DemoData.verificationOwnRoster.map(StoredPlayer.init)
        context.insert(club)
        try context.save()
    }

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
        // Fixed fixture identities are reproducible across isolated debug stores.
        for player in storedPlayers {
            player.personID = UUID(uuidString: String(format: "00000000-0000-0000-0001-%012d", player.number))!
        }
        let storedPlayersByNumber = Dictionary(uniqueKeysWithValues: storedPlayers.map { ($0.number, $0) })

        let team = StoredRivalTeam(name: demoTeamName, players: storedPlayers)
        let session = StoredSession(
            date: DemoData.sessionDate,
            kindCode: DemoData.sessionKind.rawValue,
            rivalTeam: team
        )
        session.matchID = UUID(uuidString: "00000000-0000-0000-0002-000000000001")!
        let second = StoredSession(date: DemoData.sessionDate, kindCode: SessionKind.video.rawValue, rivalTeam: team)
        second.matchID = UUID(uuidString: "00000000-0000-0000-0002-000000000002")!
        let empty = StoredSession(date: DemoData.sessionDate.addingTimeInterval(-86400), kindCode: SessionKind.live.rawValue, rivalTeam: team)
        empty.matchID = UUID(uuidString: "00000000-0000-0000-0002-000000000003")!
        for match in [session, second, empty] {
            match.participants = storedPlayers.map { StoredMatchParticipant($0.domainPlayer) }
        }
        // Match membership is a tested Domain fixture contract, not a second
        // partition implementation hidden in the persistence shell.
        for (match, indices) in zip([session, second, empty], DemoData.matchShotIndices) {
            for index in indices {
                let shot = DemoData.shots[index]
                let stored = StoredShot(
                    shot,
                    shooter: shot.shooter.flatMap { storedPlayersByNumber[$0.number] },
                    facingGoalkeeper: shot.facingGoalkeeper.flatMap { storedPlayersByNumber[$0.number] }
                )
                stored.shooterSnapshot = match.participants.first { $0.personID == stored.shooter?.personID }
                stored.goalkeeperSnapshot = match.participants.first { $0.personID == stored.facingGoalkeeper?.personID }
                match.shots.append(stored)
            }
        }
        team.sessions = [session, second, empty]

        // Inserting the team is enough: SwiftData follows its relationships
        // (players, sessions, and each session's shots) and inserts every
        // reachable object in the same graph.
        context.insert(team)
        try context.save()
    }
}
