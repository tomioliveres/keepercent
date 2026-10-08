// StoredShot is the SwiftData shell for KeepercentDomain.Shot: it stores
// only primitive codes and coordinates, and delegates every interpretation
// back to the domain (GoalTarget, ShotOutcome, AttackingSide, ShotDelivery,
// ShotApproach). See CLAUDE.md ("persist primitives, expose enums") and
// docs/mvp.md §5, §5.2, §8.
//
// `Shot` itself derives `origin` and `line` from `originPoint` and
// `isSevenMeters` (see Shot.swift); this layer never recomputes them.

import Foundation
import SwiftData
import KeepercentDomain

@Model
final class StoredShot {
    var shooterSnapshot: StoredMatchParticipant?
    var goalkeeperSnapshot: StoredMatchParticipant?
    var ownShooterSnapshot: StoredMatchParticipant?
    var ownGoalkeeperSnapshot: StoredMatchParticipant?
    var ownShooter: StoredPlayer?
    var ownGoalkeeper: StoredPlayer?
    var date: Date
    /// `AttackingSide.rawValue`.
    var attackingSideCode: String
    /// The raw normalized tap (`CourtPoint`), split into two primitives so
    /// SwiftData never has to model the struct itself. Both nil for a 7 m
    /// throw, matching `Shot.originPoint`'s own invariant.
    var originX: Double?
    var originY: Double?
    var isSevenMeters: Bool
    /// `GoalTarget.code` (see GoalTarget.swift for the compound "kind.value"
    /// format this compresses to).
    var targetCode: String
    /// `ShotOutcome.rawValue`.
    var outcomeCode: String
    /// `ShotDelivery.rawValue`, optional in the domain too.
    var deliveryCode: String?
    /// `ShotApproach.rawValue`, optional in the domain too.
    var approachCode: String?
    /// The rival shooter, when the rival attacks. A shot references a
    /// roster player without owning it, so deleting a shot never touches
    /// the roster. The reverse direction is handled by
    /// `StoredPlayer.shotsTaken`, which declares this property's inverse
    /// and nullifies it when the player is deleted.
    var shooter: StoredPlayer?
    /// The rival goalkeeper faced, when the own team attacks. Its inverse
    /// is `StoredPlayer.shotsFaced`.
    var facingGoalkeeper: StoredPlayer?

    init(
        date: Date,
        attackingSideCode: String,
        originX: Double?,
        originY: Double?,
        isSevenMeters: Bool,
        targetCode: String,
        outcomeCode: String,
        deliveryCode: String?,
        approachCode: String?,
        shooter: StoredPlayer?,
        facingGoalkeeper: StoredPlayer?,
        ownShooter: StoredPlayer? = nil,
        ownGoalkeeper: StoredPlayer? = nil
    ) {
        self.date = date
        self.attackingSideCode = attackingSideCode
        self.originX = originX
        self.originY = originY
        self.isSevenMeters = isSevenMeters
        self.targetCode = targetCode
        self.outcomeCode = outcomeCode
        self.deliveryCode = deliveryCode
        self.approachCode = approachCode
        self.shooter = shooter
        self.facingGoalkeeper = facingGoalkeeper
        self.ownShooter = attackingSideCode == AttackingSide.own.rawValue ? ownShooter : nil
        self.ownGoalkeeper = attackingSideCode == AttackingSide.rival.rawValue ? ownGoalkeeper : nil
    }

    /// Convenience initializer from the domain value, so the field-by-field
    /// code mapping is written in exactly one place.
    convenience init(_ shot: Shot, shooter: StoredPlayer?, facingGoalkeeper: StoredPlayer?,
                     ownShooter: StoredPlayer? = nil, ownGoalkeeper: StoredPlayer? = nil) {
        self.init(
            date: shot.date,
            attackingSideCode: shot.attackingSide.rawValue,
            originX: shot.originPoint?.x,
            originY: shot.originPoint?.y,
            isSevenMeters: shot.isSevenMeters,
            targetCode: shot.target.code,
            outcomeCode: shot.outcome.rawValue,
            deliveryCode: shot.delivery?.rawValue,
            approachCode: shot.approach?.rawValue,
            shooter: shooter,
            facingGoalkeeper: facingGoalkeeper,
            ownShooter: shot.ownShooter == nil ? nil : ownShooter,
            ownGoalkeeper: shot.ownGoalkeeper == nil ? nil : ownGoalkeeper
        )
    }

    /// The domain value this row represents, or nil when the row is
    /// corrupt. The decoding rules themselves live in the domain
    /// (`Shot.init?(attackingSideCode:...)`), where `swift test` can prove
    /// them; this property only hands over the stored primitives.
    var domainShot: Shot? {
        Shot(
            attackingSideCode: attackingSideCode,
            shooter: shooterSnapshot?.domainPlayer,
            facingGoalkeeper: goalkeeperSnapshot?.domainPlayer,
            ownShooter: ownShooterSnapshot?.domainPlayer,
            ownGoalkeeper: ownGoalkeeperSnapshot?.domainPlayer,
            originX: originX,
            originY: originY,
            isSevenMeters: isSevenMeters,
            targetCode: targetCode,
            outcomeCode: outcomeCode,
            deliveryCode: deliveryCode,
            approachCode: approachCode,
            date: date
        )
    }
}
