import Foundation
import SwiftData
import KeepercentDomain

enum MatchHistoryUpgrade {
    /// Called before seeding or showing UI. One save commits the entire backfill;
    /// failure rolls it back and is propagated, never replaced with an empty store.
    static func run(in context: ModelContext) throws {
        do {
            let players = try context.fetch(FetchDescriptor<StoredPlayer>())
            let sessions = try context.fetch(FetchDescriptor<StoredSession>())
            for player in players where player.personID == nil { player.personID = UUID() }
            for session in sessions {
                if session.matchID == nil { session.matchID = UUID() }
                guard session.historyUpgraded != true else { continue }
                // Only actual shot links establish historical participation. Today's
                // roster cannot prove who attended an older match with no shots.
                for shot in session.shots {
                    if let player = shot.shooter {
                        shot.shooterSnapshot = participant(for: player, in: session, context: context)
                    }
                    if let player = shot.facingGoalkeeper {
                        shot.goalkeeperSnapshot = participant(for: player, in: session, context: context)
                    }
                }
                _ = try MatchRoster(players: session.participants.map(\.domainPlayer))
                session.historyWasBackfilled = true
                session.historyUpgraded = true
            }
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }

    static func participant(for player: StoredPlayer, in session: StoredSession, context: ModelContext) -> StoredMatchParticipant {
        precondition(player.personID != nil)
        if let existing = session.participants.first(where: { $0.personID == player.personID }) { return existing }
        let snapshot = StoredMatchParticipant(player.domainPlayer)
        context.insert(snapshot)
        session.participants.append(snapshot)
        return snapshot
    }
}
