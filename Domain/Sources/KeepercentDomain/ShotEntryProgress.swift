/// Readiness of an unfinished entry, independent of the order of UI actions.
/// This does not replace `Shot.record`: only that validated write path creates
/// the shot. Incomplete drafts remain pending rather than becoming errors.
public struct ShotEntryProgress: Equatable, Sendable {
    public enum Step: Equatable, Sendable {
        case shooter, rivalGoalkeeper, origin, target, outcome
    }

    public let missingSteps: [Step]
    public let resolvedOutcome: ShotOutcome?
    public var isComplete: Bool { missingSteps.isEmpty }

    public init(
        attackingSide: AttackingSide,
        shooter: Player?,
        activeRivalGoalkeeper: Player?,
        originPoint: CourtPoint?,
        isSevenMeters: Bool = false,
        target: GoalTarget?,
        outcome: ShotOutcome?
    ) {
        var missing: [Step] = []
        switch attackingSide {
        case .rival: if shooter == nil { missing.append(.shooter) }
        case .own: if activeRivalGoalkeeper == nil { missing.append(.rivalGoalkeeper) }
        }
        if originPoint == nil && !isSevenMeters { missing.append(.origin) }
        if let target {
            if let implied = target.impliedOutcome {
                resolvedOutcome = implied
            } else if outcome == .goal || outcome == .saved {
                resolvedOutcome = outcome
            } else {
                resolvedOutcome = nil
                missing.append(.outcome)
            }
        } else {
            resolvedOutcome = nil
            missing.append(.target)
        }
        missingSteps = missing
    }
}
