// StoredSession is the SwiftData shell for a scouting session against one
// rival team. See docs/mvp.md §4, §5 and §8.

import Foundation
import SwiftData
import KeepercentDomain

@Model
final class StoredSession {
    var date: Date
    /// `SessionKind.rawValue` (see Shot.swift for why the raw enum value IS
    /// the persistence code for these small string enums).
    var kindCode: String
    /// The rival team this session scouts. Optional so that deleting the
    /// team can nullify it: a non-optional to-one reference has nothing
    /// valid to fall back to. Its inverse is `StoredRivalTeam.sessions`,
    /// which owns the delete rule for that direction.
    var rivalTeam: StoredRivalTeam?
    /// Deleting a session deletes its own recorded shots: a shot only
    /// exists as part of exactly one session.
    @Relationship(deleteRule: .cascade)
    var shots: [StoredShot]

    init(date: Date, kindCode: String, rivalTeam: StoredRivalTeam?, shots: [StoredShot] = []) {
        self.date = date
        self.kindCode = kindCode
        self.rivalTeam = rivalTeam
        self.shots = shots
    }

    /// The domain value this code represents; nil for an unrecognized code
    /// (see `StoredShot.domainShot` for the same nil-on-corruption
    /// contract, applied there to a whole shot).
    var kind: SessionKind? {
        SessionKind(rawValue: kindCode)
    }
}
