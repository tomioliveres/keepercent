// StoredRivalTeam is the SwiftData shell for a scouted rival team's roster.
// See docs/mvp.md §5 (`RivalTeam -> Player`) and §8.

import Foundation
import SwiftData

@Model
final class StoredRivalTeam {
    var name: String
    var createdAt: Date
    /// Deleting a team deletes its roster: a player only exists as part of
    /// one scouted team, never independently of it.
    @Relationship(deleteRule: .cascade)
    var players: [StoredPlayer]
    /// Sessions scouted against this team.
    ///
    /// Declared to give `StoredSession.rivalTeam` an inverse: a delete rule
    /// can only reach referencing rows through one, so without it deleting
    /// a team would leave its sessions pointing at a row that no longer
    /// exists. `.nullify` rather than `.cascade` because recorded shots are
    /// the expensive thing in this app: deleting a team forgets who the
    /// opponent was, it never throws away the scouting.
    @Relationship(deleteRule: .nullify, inverse: \StoredSession.rivalTeam)
    var sessions: [StoredSession]

    init(
        name: String,
        createdAt: Date = .now,
        players: [StoredPlayer] = [],
        sessions: [StoredSession] = []
    ) {
        self.name = name
        self.createdAt = createdAt
        self.players = players
        self.sessions = sessions
    }
}
