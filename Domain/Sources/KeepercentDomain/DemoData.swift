// DemoData is a deterministic, realistic sample dataset for one scouted
// rival team: a roster and a session's worth of shots. It exists so the app
// has a one-tap "load demo data" action and the jury never opens an empty
// app (docs/mvp.md §8, §11).
//
// The dataset is not noise: it deliberately encodes one discoverable rival
// shooter tendency and one discoverable rival goalkeeper weakness, so the
// shooter card and the goalkeeper card both have a real pattern to show.
// Everything here is a pure value built from fixed inputs — no `Date()`, no
// randomness — so the dataset is identical on every launch and every test
// run.

import Foundation

public enum DemoData {}

// MARK: - Roster

extension DemoData {
    public static let rivalTeamName = "BM Serra"

    public static let goalkeeperMarcPuig = Player(number: 1, name: "Marc Puig", isGoalkeeper: true, handedness: .right)
    public static let rightBackJordiFerrer = Player(number: 3, name: "Jordi Ferrer", isGoalkeeper: false, handedness: .right)
    /// The demo's left-handed left back: her shots (see `shots` below) are
    /// deliberately skewed cross-shot and low, to the far corner, so a jury
    /// reading her card recognizes a real scouting pattern.
    public static let leftBackPauVidal = Player(number: 4, name: "Pau Vidal", isGoalkeeper: false, handedness: .left)
    public static let centerBackBrunoCamps = Player(number: 5, name: "Bruno Camps", isGoalkeeper: false, handedness: .right)
    public static let pivotAdriaCosta = Player(number: 6, name: "Adrià Costa", isGoalkeeper: false, handedness: .right)
    /// A left-handed right wing: a realistic and scouting-relevant detail
    /// (docs/mvp.md §5) rather than an arbitrary assignment.
    public static let rightWingMartiRoig = Player(number: 7, name: "Martí Roig", isGoalkeeper: false, handedness: .left)
    public static let leftWingEricNadal = Player(number: 8, name: "Eric Nadal", isGoalkeeper: false, handedness: .right)
    /// Handedness deliberately unrecorded: the optional chips are optional
    /// in real entry too, and the demo data should read that way.
    public static let rightBackOriolBosch = Player(number: 9, name: "Oriol Bosch", isGoalkeeper: false, handedness: nil)
    public static let centerBackGerardRiu = Player(number: 10, name: "Gerard Riu", isGoalkeeper: false, handedness: .right)
    public static let leftBackNilAmat = Player(number: 11, name: "Nil Amat", isGoalkeeper: false, handedness: .left)
    public static let goalkeeperDavidSoler = Player(number: 12, name: "David Soler", isGoalkeeper: true, handedness: .left)
    public static let pivotIkerSalas = Player(number: 14, name: "Iker Salas", isGoalkeeper: false, handedness: nil)

    /// The full scouted roster: 2 goalkeepers and 10 field players.
    public static let roster: [Player] = [
        goalkeeperMarcPuig,
        goalkeeperDavidSoler,
        rightBackJordiFerrer,
        leftBackPauVidal,
        centerBackBrunoCamps,
        pivotAdriaCosta,
        rightWingMartiRoig,
        leftWingEricNadal,
        rightBackOriolBosch,
        centerBackGerardRiu,
        leftBackNilAmat,
        pivotIkerSalas
    ]
}

// MARK: - Session

extension DemoData {
    public static let sessionKind = SessionKind.live

    /// The fixed date every demo shot is offset from. Built from explicit
    /// date components in UTC, rather than a raw epoch offset, so the base
    /// sits safely away from a day boundary regardless of when this file is
    /// read: the whole dataset stays on one calendar day.
    public static let sessionDate: Date = {
        var components = DateComponents()
        components.year = 2026
        components.month = 9
        components.day = 20
        components.hour = 18
        components.minute = 0
        components.timeZone = TimeZone(identifier: "UTC")
        return Calendar(identifier: .gregorian).date(from: components)!
    }()
}

// MARK: - Court origins

/// Representative meter offsets from the goal centre, one per `CourtZone`,
/// matching the positions real players occupy (docs/mvp.md §5.2). Kept as
/// named points rather than inlined magic numbers so the shot list below
/// reads as scouting notes, not coordinates.
private extension DemoData {
    static func point(xMeters: Double, yMeters: Double) -> CourtPoint {
        CourtPoint(x: xMeters / CourtGeometry.standard.widthInMeters + 0.5, y: yMeters / CourtGeometry.standard.depthInMeters)
    }

    static let leftWingNear = point(xMeters: -8, yMeters: 3)
    static let leftWingFar = point(xMeters: -10, yMeters: 7)
    static let leftBackNear = point(xMeters: -5, yMeters: 8)
    static let leftBackFar = point(xMeters: -6, yMeters: 10)
    static let centerNear = point(xMeters: 0, yMeters: 6)
    static let centerFar = point(xMeters: 0, yMeters: 11)
    static let rightBackNear = point(xMeters: 5, yMeters: 8)
    static let rightBackFar = point(xMeters: 6, yMeters: 10)
    static let rightWingNear = point(xMeters: 8, yMeters: 3)
    static let rightWingFar = point(xMeters: 10, yMeters: 7)
}

// MARK: - Shots

private extension DemoData {
    /// One shot, `minutesFromStart` after `sessionDate`, so the whole
    /// dataset's dates live in one place instead of forty separate literals.
    static func shot(
        attackingSide: AttackingSide,
        shooter: Player? = nil,
        facingGoalkeeper: Player? = nil,
        originPoint: CourtPoint? = nil,
        isSevenMeters: Bool = false,
        target: GoalTarget,
        outcome: ShotOutcome,
        delivery: ShotDelivery? = nil,
        approach: ShotApproach? = nil,
        minutesFromStart: Double
    ) -> Shot {
        Shot(
            attackingSide: attackingSide,
            shooter: shooter,
            facingGoalkeeper: facingGoalkeeper,
            originPoint: originPoint,
            isSevenMeters: isSevenMeters,
            target: target,
            outcome: outcome,
            delivery: delivery,
            approach: approach,
            date: sessionDate.addingTimeInterval(minutesFromStart * 60)
        )
    }
}

extension DemoData {
    /// One demo session's worth of shots against `rivalTeamName`: both
    /// attacking sides, every `ShotOutcome`, a handful of 7 m throws, and
    /// origins spread across every court zone.
    public static let shots: [Shot] = [
        // MARK: Pau Vidal (#4) — the tendency: cross-shot, low, far corner.
        shot(
            attackingSide: .rival, shooter: leftBackPauVidal,
            originPoint: leftBackNear,
            target: .inside(GoalZone(row: .bottom, column: .right)), outcome: .goal,
            delivery: .jump, approach: .fromLeft, minutesFromStart: 0
        ),
        shot(
            attackingSide: .rival, shooter: leftBackPauVidal,
            originPoint: leftBackFar,
            target: .inside(GoalZone(row: .bottom, column: .right)), outcome: .goal,
            delivery: .jump, minutesFromStart: 2
        ),
        shot(
            attackingSide: .rival, shooter: leftBackPauVidal,
            originPoint: leftBackNear,
            target: .inside(GoalZone(row: .bottom, column: .right)), outcome: .saved,
            delivery: .standing, approach: .fromLeft, minutesFromStart: 4
        ),
        shot(
            attackingSide: .rival, shooter: leftBackPauVidal,
            originPoint: leftBackFar,
            target: .inside(GoalZone(row: .middle, column: .right)), outcome: .goal,
            delivery: .jump, approach: .fromLeft, minutesFromStart: 6
        ),
        shot(
            attackingSide: .rival, shooter: leftBackPauVidal,
            originPoint: leftBackNear,
            target: .inside(GoalZone(row: .bottom, column: .right)), outcome: .goal,
            minutesFromStart: 8
        ),
        shot(
            attackingSide: .rival, shooter: leftBackPauVidal,
            originPoint: leftWingNear,
            target: .post(.rightPostBottom), outcome: .post,
            delivery: .jump, minutesFromStart: 10
        ),
        shot(
            attackingSide: .rival, shooter: leftBackPauVidal,
            originPoint: leftBackNear,
            target: .inside(GoalZone(row: .top, column: .left)), outcome: .saved,
            delivery: .jump, approach: .fromLeft, minutesFromStart: 12
        ),
        shot(
            attackingSide: .rival, shooter: leftBackPauVidal,
            originPoint: leftBackFar,
            target: .out(.wideRight), outcome: .out,
            minutesFromStart: 14
        ),

        // MARK: Other rival shooters — variety of zones, targets and outcomes.
        shot(
            attackingSide: .rival, shooter: rightBackJordiFerrer,
            originPoint: rightWingNear,
            target: .inside(GoalZone(row: .top, column: .right)), outcome: .saved,
            delivery: .jump, approach: .fromRight, minutesFromStart: 16
        ),
        shot(
            attackingSide: .rival, shooter: rightBackJordiFerrer,
            originPoint: rightWingFar,
            target: .out(.wideRight), outcome: .out,
            minutesFromStart: 18
        ),
        shot(
            attackingSide: .rival, shooter: pivotAdriaCosta,
            originPoint: centerFar,
            target: .inside(GoalZone(row: .middle, column: .center)), outcome: .goal,
            delivery: .standing, approach: .straight, minutesFromStart: 20
        ),
        shot(
            attackingSide: .rival, shooter: pivotAdriaCosta,
            originPoint: centerNear,
            target: .post(.crossbarCenter), outcome: .post,
            minutesFromStart: 22
        ),
        shot(
            attackingSide: .rival, shooter: rightWingMartiRoig,
            originPoint: rightWingNear,
            target: .inside(GoalZone(row: .bottom, column: .left)), outcome: .goal,
            delivery: .jump, approach: .fromRight, minutesFromStart: 24
        ),
        shot(
            attackingSide: .rival, shooter: rightWingMartiRoig,
            originPoint: rightWingFar,
            target: .inside(GoalZone(row: .bottom, column: .left)), outcome: .saved,
            delivery: .jump, minutesFromStart: 26
        ),
        shot(
            attackingSide: .rival, shooter: leftWingEricNadal,
            originPoint: leftWingNear,
            target: .inside(GoalZone(row: .middle, column: .left)), outcome: .goal,
            delivery: .jump, approach: .fromLeft, minutesFromStart: 28
        ),
        shot(
            attackingSide: .rival, shooter: rightBackOriolBosch,
            originPoint: rightBackNear,
            target: .inside(GoalZone(row: .top, column: .center)), outcome: .saved,
            minutesFromStart: 30
        ),
        shot(
            attackingSide: .rival, shooter: centerBackGerardRiu,
            originPoint: rightBackFar,
            target: .out(.over), outcome: .out,
            delivery: .jump, minutesFromStart: 32
        ),
        shot(
            attackingSide: .rival, shooter: leftBackNilAmat,
            originPoint: centerNear,
            target: .inside(GoalZone(row: .bottom, column: .center)), outcome: .goal,
            delivery: .standing, minutesFromStart: 34
        ),
        shot(
            attackingSide: .rival, shooter: pivotIkerSalas,
            isSevenMeters: true,
            target: .inside(GoalZone(row: .top, column: .right)), outcome: .saved,
            minutesFromStart: 36
        ),
        shot(
            attackingSide: .rival, shooter: centerBackBrunoCamps,
            isSevenMeters: true,
            target: .inside(GoalZone(row: .bottom, column: .center)), outcome: .goal,
            delivery: .standing, minutesFromStart: 38
        ),

        // MARK: Marc Puig (#1) — the weakness: concedes low, on his left.
        shot(
            attackingSide: .own, facingGoalkeeper: goalkeeperMarcPuig,
            originPoint: leftBackNear,
            target: .inside(GoalZone(row: .bottom, column: .left)), outcome: .goal,
            delivery: .jump, approach: .fromLeft, minutesFromStart: 40
        ),
        shot(
            attackingSide: .own, facingGoalkeeper: goalkeeperMarcPuig,
            originPoint: rightWingNear,
            target: .inside(GoalZone(row: .bottom, column: .left)), outcome: .goal,
            delivery: .standing, approach: .fromRight, minutesFromStart: 42
        ),
        shot(
            attackingSide: .own, facingGoalkeeper: goalkeeperMarcPuig,
            originPoint: centerNear,
            target: .inside(GoalZone(row: .bottom, column: .left)), outcome: .goal,
            minutesFromStart: 44
        ),
        shot(
            attackingSide: .own, facingGoalkeeper: goalkeeperMarcPuig,
            originPoint: leftWingNear,
            target: .post(.leftPostBottom), outcome: .post,
            minutesFromStart: 46
        ),
        shot(
            attackingSide: .own, facingGoalkeeper: goalkeeperMarcPuig,
            originPoint: rightBackFar,
            target: .inside(GoalZone(row: .bottom, column: .left)), outcome: .goal,
            delivery: .jump, minutesFromStart: 48
        ),
        shot(
            attackingSide: .own, facingGoalkeeper: goalkeeperMarcPuig,
            originPoint: leftBackFar,
            target: .inside(GoalZone(row: .bottom, column: .left)), outcome: .saved,
            delivery: .jump, approach: .fromLeft, minutesFromStart: 50
        ),
        shot(
            attackingSide: .own, facingGoalkeeper: goalkeeperMarcPuig,
            originPoint: centerFar,
            target: .inside(GoalZone(row: .middle, column: .left)), outcome: .goal,
            minutesFromStart: 52
        ),
        shot(
            attackingSide: .own, facingGoalkeeper: goalkeeperMarcPuig,
            originPoint: rightWingFar,
            target: .inside(GoalZone(row: .top, column: .right)), outcome: .saved,
            delivery: .jump, approach: .fromRight, minutesFromStart: 54
        ),
        shot(
            attackingSide: .own, facingGoalkeeper: goalkeeperMarcPuig,
            originPoint: leftWingFar,
            target: .out(.wideLeft), outcome: .out,
            minutesFromStart: 56
        ),
        shot(
            attackingSide: .own, facingGoalkeeper: goalkeeperMarcPuig,
            isSevenMeters: true,
            target: .inside(GoalZone(row: .bottom, column: .left)), outcome: .goal,
            minutesFromStart: 58
        ),
        shot(
            attackingSide: .own, facingGoalkeeper: goalkeeperMarcPuig,
            originPoint: centerNear,
            target: .inside(GoalZone(row: .bottom, column: .center)), outcome: .goal,
            delivery: .standing, minutesFromStart: 60
        ),
        shot(
            attackingSide: .own, facingGoalkeeper: goalkeeperMarcPuig,
            originPoint: leftBackNear,
            target: .inside(GoalZone(row: .bottom, column: .left)), outcome: .goal,
            delivery: .jump, approach: .fromLeft, minutesFromStart: 62
        ),
        shot(
            attackingSide: .own, facingGoalkeeper: goalkeeperMarcPuig,
            originPoint: centerFar,
            target: .inside(GoalZone(row: .middle, column: .center)), outcome: .saved,
            minutesFromStart: 64
        ),
        shot(
            attackingSide: .own, facingGoalkeeper: goalkeeperMarcPuig,
            originPoint: leftWingNear,
            target: .inside(GoalZone(row: .top, column: .left)), outcome: .saved,
            delivery: .jump, minutesFromStart: 66
        ),

        // MARK: David Soler (#12) — the control group: no strong tendency.
        shot(
            attackingSide: .own, facingGoalkeeper: goalkeeperDavidSoler,
            originPoint: centerNear,
            target: .inside(GoalZone(row: .middle, column: .center)), outcome: .saved,
            minutesFromStart: 68
        ),
        shot(
            attackingSide: .own, facingGoalkeeper: goalkeeperDavidSoler,
            originPoint: rightBackNear,
            target: .inside(GoalZone(row: .top, column: .right)), outcome: .goal,
            delivery: .jump, approach: .fromRight, minutesFromStart: 70
        ),
        shot(
            attackingSide: .own, facingGoalkeeper: goalkeeperDavidSoler,
            originPoint: rightWingNear,
            target: .inside(GoalZone(row: .bottom, column: .right)), outcome: .goal,
            minutesFromStart: 72
        ),
        shot(
            attackingSide: .own, facingGoalkeeper: goalkeeperDavidSoler,
            originPoint: centerFar,
            target: .post(.crossbarCenter), outcome: .post,
            minutesFromStart: 74
        ),
        shot(
            attackingSide: .own, facingGoalkeeper: goalkeeperDavidSoler,
            originPoint: leftBackFar,
            target: .out(.over), outcome: .out,
            delivery: .standing, minutesFromStart: 76
        ),
        shot(
            attackingSide: .own, facingGoalkeeper: goalkeeperDavidSoler,
            isSevenMeters: true,
            target: .inside(GoalZone(row: .middle, column: .left)), outcome: .saved,
            minutesFromStart: 78
        )
    ]
}
