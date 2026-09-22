// ShotEntry is the validated write path for recording a shot: the strict
// rule from T3.3 (docs/mvp.md §6, "Shot entry") that `Shot.init` itself
// deliberately does not enforce, because the stored-code decoding
// (`Shot.init?(attackingSideCode:...)`) and `DemoData` must keep reading
// existing rows through the plain, non-throwing initializer.
//
// `Shot.record` is therefore a separate static entry point built on top of
// `Shot.init`, not a second `init` or a change to the existing one: `init`
// and the decoder must stay non-throwing for those existing callers, while
// this is the one call site that needs to reject an invalid shot outright.
// It uses typed throws (`throws(ShotEntryError)`) so the UI can `switch`
// exhaustively over every rejection reason to choose its message.

import Foundation

/// What can go wrong recording a shot through the validated entry point,
/// with enough detail for the UI message T3.3 describes.
public enum ShotEntryError: Error, Equatable, Hashable, Sendable {
    /// A rival attack was recorded with no shooter.
    case missingShooter
    /// An own-team attack was recorded with no active rival goalkeeper.
    case missingRivalGoalkeeper
    /// A shot that is not a 7 m throw was recorded with no origin point.
    case missingOrigin
    /// The target lands inside the frame, which needs an explicit
    /// goal/saved answer that was not given.
    case missingOutcome
    /// The given outcome cannot be true for the given target: either it
    /// contradicts `target.impliedOutcome` (a post or a miss), or the
    /// target is inside the frame and the outcome is neither `.goal` nor
    /// `.saved`.
    case outcomeContradictsTarget
}

extension Shot {
    /// Records a shot through the strict rule T3.3 adds on top of the
    /// plain `Shot.init`: who took it and who they faced, whether an
    /// origin is required, and whether the outcome agrees with the target.
    ///
    /// Guards run in the order the entry flow itself asks the questions —
    /// who (shooter / active rival goalkeeper) -> where from (origin) ->
    /// where to / how it ended (outcome) — so when several rules are
    /// broken at once, the error the UI shows is always the first one in
    /// that order, never an arbitrary pick. This order is tested in
    /// `ShotEntryTests.swift`.
    ///
    /// Typed throws (`throws(ShotEntryError)`), unlike the plain `throws`
    /// `Roster` and `Session` use: this is the one call site in shot entry
    /// where the UI needs an exhaustive `switch` over every rejection
    /// reason to choose its message, and typed throws states that closed
    /// set at the signature instead of only at the `catch`.
    public static func record(
        attackingSide: AttackingSide,
        shooter: Player?,
        activeRivalGoalkeeper: Player?,
        originPoint: CourtPoint?,
        isSevenMeters: Bool = false,
        target: GoalTarget,
        outcome: ShotOutcome?,
        delivery: ShotDelivery? = nil,
        approach: ShotApproach? = nil,
        date: Date
    ) throws(ShotEntryError) -> Shot {
        // Who took the shot / who they faced. Own goalkeepers are out of
        // scope (docs/mvp.md §9), so a rival attack never carries a
        // `facingGoalkeeper`, even when one is set as active; and an own
        // attack never carries a `shooter`, even when one was passed in —
        // own players are not on any roster, so a contradictory shooter is
        // dropped the same way `Shot.init` drops `originPoint` for a 7 m
        // throw, rather than treated as an error the caller must avoid.
        let resolvedShooter: Player?
        let resolvedFacingGoalkeeper: Player?
        switch attackingSide {
        case .rival:
            guard let shooter else { throw .missingShooter }
            resolvedShooter = shooter
            resolvedFacingGoalkeeper = nil
        case .own:
            guard let activeRivalGoalkeeper else { throw .missingRivalGoalkeeper }
            resolvedShooter = nil
            resolvedFacingGoalkeeper = activeRivalGoalkeeper
        }

        // Where from.
        guard isSevenMeters || originPoint != nil else {
            throw .missingOrigin
        }

        // Where to / how it ended.
        let resolvedOutcome: ShotOutcome
        if let impliedOutcome = target.impliedOutcome {
            if let outcome, outcome != impliedOutcome {
                throw .outcomeContradictsTarget
            }
            resolvedOutcome = impliedOutcome
        } else {
            guard let outcome else { throw .missingOutcome }
            guard outcome == .goal || outcome == .saved else {
                throw .outcomeContradictsTarget
            }
            resolvedOutcome = outcome
        }

        return Shot(
            attackingSide: attackingSide,
            shooter: resolvedShooter,
            facingGoalkeeper: resolvedFacingGoalkeeper,
            originPoint: originPoint,
            isSevenMeters: isSevenMeters,
            target: target,
            outcome: resolvedOutcome,
            delivery: delivery,
            approach: approach,
            date: date
        )
    }
}
