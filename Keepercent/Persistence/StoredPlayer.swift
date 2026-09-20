// StoredPlayer is the SwiftData shell for KeepercentDomain.Player: it stores
// only primitives (a raw handedness code, never the enum) and maps to and
// from the domain struct. See CLAUDE.md ("persist primitives, expose
// enums") and docs/mvp.md §5, §8.

import Foundation
import SwiftData
import KeepercentDomain

@Model
final class StoredPlayer {
    var number: Int
    var name: String?
    var isGoalkeeper: Bool
    /// `Handedness.rawValue`, or nil when unknown. Stored as a String, not
    /// the enum itself, so a future handedness case never forces a
    /// migration (the same reasoning `GoalTarget.code` documents for a
    /// compound code).
    var handednessCode: String?
    /// Shots this player took, and shots taken against them as goalkeeper.
    ///
    /// These exist to declare the INVERSE of `StoredShot.shooter` and
    /// `StoredShot.facingGoalkeeper`. Without an inverse a delete rule has
    /// no way to reach the referencing rows, so deleting a player would
    /// leave dangling references instead of nullifying them; Apple's
    /// SwiftData documentation calls the inverse key path essential for
    /// referential integrity. `.nullify` is the conservative choice for a
    /// scouting app: removing a player from a roster must never destroy
    /// the shots already recorded, it only forgets who took them.
    @Relationship(deleteRule: .nullify, inverse: \StoredShot.shooter)
    var shotsTaken: [StoredShot]
    @Relationship(deleteRule: .nullify, inverse: \StoredShot.facingGoalkeeper)
    var shotsFaced: [StoredShot]

    init(
        number: Int,
        name: String?,
        isGoalkeeper: Bool,
        handednessCode: String?,
        shotsTaken: [StoredShot] = [],
        shotsFaced: [StoredShot] = []
    ) {
        self.number = number
        self.name = name
        self.isGoalkeeper = isGoalkeeper
        self.handednessCode = handednessCode
        self.shotsTaken = shotsTaken
        self.shotsFaced = shotsFaced
    }

    /// Convenience initializer from the domain struct, so the field-by-field
    /// code mapping is written in exactly one place.
    convenience init(_ player: Player) {
        self.init(
            number: player.number,
            name: player.name,
            isGoalkeeper: player.isGoalkeeper,
            handednessCode: player.handedness?.rawValue
        )
    }

    /// The domain value this row represents. `Handedness` round-trips
    /// through its compiler-synthesized `init?(rawValue:)` (see
    /// Shot.swift); an unrecognized or missing code decodes to nil rather
    /// than invalidating the whole player, since handedness is optional in
    /// the domain too.
    var domainPlayer: Player {
        Player(
            number: number,
            name: name,
            isGoalkeeper: isGoalkeeper,
            handedness: handednessCode.flatMap(Handedness.init(rawValue:))
        )
    }
}
