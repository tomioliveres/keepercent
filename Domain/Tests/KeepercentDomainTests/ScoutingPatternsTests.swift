import Foundation
import Testing
@testable import KeepercentDomain

private let referenceDate = Date(timeIntervalSince1970: 0)

private func point(xMeters: Double, yMeters: Double) -> CourtPoint {
    let geometry = CourtGeometry.standard
    return CourtPoint(x: xMeters / geometry.widthInMeters + 0.5, y: yMeters / geometry.depthInMeters)
}

private let leftBackNear = point(xMeters: -5, yMeters: 8)
private let leftBackFar = point(xMeters: -6, yMeters: 10)
private let rightBackNear = point(xMeters: 5, yMeters: 8)
private let centerNear = point(xMeters: 0, yMeters: 6)
private let centerFar = point(xMeters: 0, yMeters: 11)

private let leftHander = Player(number: 4, handedness: .left)
private let rightHander = Player(number: 3, handedness: .right)
private let goalkeeper = Player(number: 1, isGoalkeeper: true)

private func inside(_ row: GoalRow, _ column: GoalColumn) -> GoalTarget {
    .inside(GoalZone(row: row, column: column))
}

/// A rival shot with sensible defaults, so each test states only what it
/// is about. `minute` orders shots in time for the repeat-after-scoring rule.
private func shot(
    by shooter: Player = leftHander,
    from originPoint: CourtPoint? = centerNear,
    sevenMeters: Bool = false,
    to target: GoalTarget = inside(.middle, .center),
    outcome: ShotOutcome = .goal,
    delivery: ShotDelivery? = nil,
    approach: ShotApproach? = nil,
    minute: Double = 0
) -> Shot {
    Shot(
        attackingSide: .rival,
        shooter: shooter,
        originPoint: originPoint,
        isSevenMeters: sevenMeters,
        target: target,
        outcome: outcome,
        delivery: delivery,
        approach: approach,
        date: referenceDate.addingTimeInterval(minute * 60)
    )
}

/// A shot the own team took against the rival goalkeeper.
private func faced(
    from originPoint: CourtPoint? = centerNear,
    sevenMeters: Bool = false,
    to target: GoalTarget = inside(.middle, .center),
    outcome: ShotOutcome,
    delivery: ShotDelivery? = nil
) -> Shot {
    Shot(
        attackingSide: .own,
        facingGoalkeeper: goalkeeper,
        originPoint: originPoint,
        isSevenMeters: sevenMeters,
        target: target,
        outcome: outcome,
        delivery: delivery,
        date: referenceDate
    )
}

private func repeated(_ count: Int, _ make: () -> Shot) -> [Shot] {
    (0..<count).map { _ in make() }
}

private func shooterPatterns(_ shots: [Shot]) -> [ScoutingPattern] {
    StatsEngine(shots: shots).shooterPatterns()
}

private func goalkeeperPatterns(_ shots: [Shot]) -> [ScoutingPattern] {
    StatsEngine(shots: shots).goalkeeperPatterns()
}

private func find(_ kind: ScoutingPatternKind, in patterns: [ScoutingPattern]) -> ScoutingPattern? {
    patterns.first { $0.kind == kind }
}

@Suite("Scouting patterns: thresholds")
struct ScoutingPatternThresholdTests {
    @Test("Thresholds are the documented values")
    func documentedValues() {
        #expect(ScoutingPattern.minimumSample == 5)
        #expect(ScoutingPattern.dominantShare == 0.6)
        #expect(ScoutingPattern.lineShare == 0.7)
        #expect(ScoutingPattern.comparisonMinimumSample == 4)
        #expect(ScoutingPattern.comparisonGap == 0.3)
        #expect(ScoutingPattern.minimumRepeatPairs == 4)
        #expect(ScoutingPattern.repeatShare == 0.6)
    }

    @Test("An empty engine finds no pattern from either perspective")
    func emptyEngine() {
        #expect(shooterPatterns([]).isEmpty)
        #expect(goalkeeperPatterns([]).isEmpty)
    }
}

@Suite("Scouting patterns: line")
struct ScoutingPatternLineTests {
    @Test("7 cross-court of 10 line shots fires, neutral shots stay out of the sample")
    func crossCourtFires() throws {
        let shots = repeated(7) { shot(from: leftBackNear, to: inside(.bottom, .right)) }
            + repeated(3) { shot(from: leftBackNear, to: inside(.bottom, .left), outcome: .saved) }
            + repeated(4) { shot(from: centerNear, to: inside(.top, .center)) }
        let pattern = try #require(find(.line(.crossShot), in: shooterPatterns(shots)))
        #expect(pattern.tally == Tally(successes: 7, attempts: 10))
        #expect(pattern.conversion == Tally(successes: 7, attempts: 7))
    }

    @Test("6 of 10 is below the two-way share and does not fire")
    func belowShare() {
        let shots = repeated(6) { shot(from: leftBackNear, to: inside(.bottom, .right)) }
            + repeated(4) { shot(from: leftBackNear, to: inside(.bottom, .left)) }
        let patterns = shooterPatterns(shots)
        #expect(find(.line(.crossShot), in: patterns) == nil)
        #expect(find(.line(.nearPost), in: patterns) == nil)
    }

    @Test("4 of 4 is below the minimum sample and does not fire")
    func belowSample() {
        let shots = repeated(4) { shot(from: leftBackNear, to: inside(.bottom, .right)) }
        #expect(find(.line(.crossShot), in: shooterPatterns(shots)) == nil)
    }

    @Test("Misses with a side count toward the line, 7 m throws never do")
    func missesCountSevenMetersDoNot() throws {
        let shots = repeated(3) { shot(from: leftBackNear, to: inside(.top, .right)) }
            + repeated(2) { shot(from: leftBackNear, to: .out(.wideRight, .top), outcome: .out) }
            + repeated(5) { shot(from: nil, sevenMeters: true, to: inside(.top, .left)) }
        let pattern = try #require(find(.line(.crossShot), in: shooterPatterns(shots)))
        #expect(pattern.tally == Tally(successes: 5, attempts: 5))
        #expect(pattern.conversion == Tally(successes: 3, attempts: 5))
    }

    @Test("Each sector and hand reads its own line when the overall split is mixed")
    func perSectorAndHand() throws {
        let shots = repeated(5) { shot(by: leftHander, from: leftBackNear, to: inside(.bottom, .right)) }
            + repeated(5) { shot(by: rightHander, from: rightBackNear, to: inside(.bottom, .right)) }
        let patterns = shooterPatterns(shots)
        #expect(find(.line(.crossShot), in: patterns) == nil)
        let cross = try #require(find(.lineFromSector(.crossShot, sector: .leftBack, hand: .left), in: patterns))
        #expect(cross.tally == Tally(successes: 5, attempts: 5))
        let near = try #require(find(.lineFromSector(.nearPost, sector: .rightBack, hand: .right), in: patterns))
        #expect(near.tally == Tally(successes: 5, attempts: 5))
    }

    @Test("A sector pointing the same way as the overall line is not repeated")
    func noRepeatOfOverallDirection() {
        let shots = repeated(6) { shot(by: leftHander, from: leftBackNear, to: inside(.bottom, .right)) }
            + [shot(by: leftHander, from: leftBackNear, to: inside(.bottom, .left))]
            + [shot(by: rightHander, from: rightBackNear, to: inside(.bottom, .left))]
        let patterns = shooterPatterns(shots)
        #expect(find(.line(.crossShot), in: patterns)?.tally == Tally(successes: 7, attempts: 8))
        #expect(!patterns.contains { if case .lineFromSector = $0.kind { true } else { false } })
    }

    @Test("A sector holding every line shot does not repeat the overall pattern")
    func noDuplicateOfOverall() {
        let shots = repeated(5) { shot(by: leftHander, from: leftBackNear, to: inside(.bottom, .right)) }
        let patterns = shooterPatterns(shots)
        #expect(find(.line(.crossShot), in: patterns) != nil)
        #expect(!patterns.contains { if case .lineFromSector = $0.kind { true } else { false } })
    }
}

@Suite("Scouting patterns: height, side and origin")
struct ScoutingPatternCategoryTests {
    @Test("3 of 5 low fires at the three-way share, misses excluded from the sample")
    func heightAtShare() throws {
        let shots = repeated(3) { shot(to: inside(.bottom, .left)) }
            + repeated(2) { shot(to: inside(.middle, .center), outcome: .saved) }
            + repeated(3) { shot(to: .out(.over, .center), outcome: .out) }
        let pattern = try #require(find(.height(.bottom), in: shooterPatterns(shots)))
        #expect(pattern.tally == Tally(successes: 3, attempts: 5))
        #expect(pattern.conversion == Tally(successes: 3, attempts: 3))
    }

    @Test("5 of 9 low is below the three-way share and does not fire")
    func heightBelowShare() {
        let shots = repeated(5) { shot(to: inside(.bottom, .left)) }
            + repeated(4) { shot(to: inside(.top, .center)) }
        #expect(find(.height(.bottom), in: shooterPatterns(shots)) == nil)
    }

    @Test("4 of 4 low is below the minimum sample and does not fire")
    func heightBelowSample() {
        let shots = repeated(4) { shot(to: inside(.bottom, .left)) }
        #expect(find(.height(.bottom), in: shooterPatterns(shots)) == nil)
    }

    @Test("A preferred side fires on 4 of 5 and ignores misses")
    func side() throws {
        let shots = repeated(4) { shot(to: inside(.top, .left)) }
            + [shot(to: inside(.top, .right))]
            + repeated(4) { shot(to: .out(.wideRight, .top), outcome: .out) }
        let pattern = try #require(find(.side(.left), in: shooterPatterns(shots)))
        #expect(pattern.tally == Tally(successes: 4, attempts: 5))
    }

    @Test("Origin dominance counts the share of field shots from one zone")
    func originDominance() throws {
        let shots = repeated(3) { shot(from: leftBackNear) }
            + repeated(2) { shot(from: centerFar, outcome: .saved) }
        let pattern = try #require(find(.origin(CourtZone(sector: .leftBack, depth: .near)), in: shooterPatterns(shots)))
        #expect(pattern.tally == Tally(successes: 3, attempts: 5))
        #expect(pattern.conversion == Tally(successes: 3, attempts: 3))
    }
}

@Suite("Scouting patterns: delivery, approach and 7 m")
struct ScoutingPatternContextTests {
    @Test("When standing, a dominant height fires with its own conversion")
    func deliveryHeight() throws {
        let shots = repeated(3) { shot(to: inside(.bottom, .left), delivery: .standing) }
            + [shot(to: inside(.bottom, .right), outcome: .saved, delivery: .standing)]
            + [shot(to: inside(.top, .center), delivery: .standing)]
            + repeated(5) { shot(to: inside(.top, .center), delivery: .jump) }
        let patterns = shooterPatterns(shots)
        let pattern = try #require(find(.deliveryHeight(.standing, .bottom), in: patterns))
        #expect(pattern.tally == Tally(successes: 4, attempts: 5))
        #expect(pattern.conversion == Tally(successes: 3, attempts: 4))
        #expect(find(.deliveryHeight(.jump, .top), in: patterns)?.tally == Tally(successes: 5, attempts: 5))
    }

    @Test("4 standing shots are below the minimum sample")
    func deliveryBelowSample() {
        let shots = repeated(4) { shot(to: inside(.bottom, .left), delivery: .standing) }
        #expect(find(.deliveryHeight(.standing, .bottom), in: shooterPatterns(shots)) == nil)
    }

    @Test("Coming from the left, a dominant side fires")
    func approachSide() throws {
        let shots = repeated(4) { shot(to: inside(.top, .right), approach: .fromLeft) }
            + [shot(to: inside(.top, .left), approach: .fromLeft)]
            + repeated(3) { shot(to: inside(.top, .left), approach: .straight) }
        let patterns = shooterPatterns(shots)
        #expect(find(.approachSide(.fromLeft, .right), in: patterns)?.tally == Tally(successes: 4, attempts: 5))
        #expect(!patterns.contains { if case .approachSide(.straight, _) = $0.kind { true } else { false } })
    }

    @Test("7 m tendencies read only 7 m throws, field tendencies never include them")
    func sevenMeters() throws {
        let shots = repeated(4) { shot(from: nil, sevenMeters: true, to: inside(.bottom, .left)) }
            + [shot(from: nil, sevenMeters: true, to: inside(.top, .right), outcome: .saved)]
        let patterns = shooterPatterns(shots)
        #expect(find(.sevenMeterSide(.left), in: patterns)?.tally == Tally(successes: 4, attempts: 5))
        #expect(find(.sevenMeterHeight(.bottom), in: patterns)?.tally == Tally(successes: 4, attempts: 5))
        #expect(find(.side(.left), in: patterns) == nil)
        #expect(find(.height(.bottom), in: patterns) == nil)
    }
}

@Suite("Scouting patterns: comparisons and repeats")
struct ScoutingPatternComparisonTests {
    @Test("Near vs far conversion fires on a large enough gap")
    func distanceFires() throws {
        let shots = repeated(3) { shot(from: leftBackNear) }
            + [shot(from: leftBackNear, outcome: .saved)]
            + repeated(4) { shot(from: leftBackFar, outcome: .saved) }
        let pattern = try #require(find(.distance, in: shooterPatterns(shots)))
        #expect(pattern.tally == Tally(successes: 3, attempts: 4))
        #expect(pattern.contrast == Tally(successes: 0, attempts: 4))
    }

    @Test("A gap of exactly 0.3 fires despite floating-point rounding")
    func distanceAtGap() {
        // 7/10 - 2/5 is 0.29999999999999993 in Double arithmetic.
        let shots = repeated(7) { shot(from: leftBackNear) }
            + repeated(3) { shot(from: leftBackNear, outcome: .saved) }
            + repeated(2) { shot(from: centerFar) }
            + repeated(3) { shot(from: centerFar, outcome: .saved) }
        #expect(find(.distance, in: shooterPatterns(shots)) != nil)
    }

    @Test("A gap below 0.3 or a side under 4 shots does not fire")
    func distanceBelowThresholds() {
        let smallGap = repeated(2) { shot(from: leftBackNear) }
            + repeated(2) { shot(from: leftBackNear, outcome: .saved) }
            + [shot(from: leftBackFar)]
            + repeated(3) { shot(from: leftBackFar, outcome: .saved) }
        #expect(find(.distance, in: shooterPatterns(smallGap)) == nil)

        let smallSample = repeated(3) { shot(from: leftBackNear) }
            + repeated(4) { shot(from: leftBackFar, outcome: .saved) }
        #expect(find(.distance, in: shooterPatterns(smallSample)) == nil)
    }

    @Test("Repeat after scoring follows each shooter's own date order")
    func repeatAfterGoal() throws {
        // Listed out of time order and interleaved with another shooter: a
        // naive list walk would pair the wrong shots.
        let topLeft = inside(.top, .left)
        let bottomRight = inside(.bottom, .right)
        let shots = [
            shot(by: leftHander, to: topLeft, minute: 3),
            shot(by: rightHander, to: bottomRight, minute: 0),
            shot(by: leftHander, to: topLeft, minute: 0),
            shot(by: rightHander, to: topLeft, minute: 1),
            shot(by: leftHander, to: topLeft, minute: 1),
            shot(by: leftHander, to: bottomRight, minute: 4),
            shot(by: leftHander, to: topLeft, outcome: .saved, minute: 2),
            shot(by: leftHander, to: bottomRight, outcome: .saved, minute: 5)
        ]
        // Left-hander in time order: TL(g) TL(g) TL(s) TL(g) BR(g) BR(s)
        //   → pairs after a goal: TL→TL yes, TL→TL yes, TL→BR no, BR→BR yes.
        // Right-hander: BR(g) → TL no.
        let pattern = try #require(find(.repeatAfterGoal, in: shooterPatterns(shots)))
        #expect(pattern.tally == Tally(successes: 3, attempts: 5))
    }

    @Test("Half the pairs repeating is a coin flip, not a pattern")
    func repeatAtHalfDoesNotFire() {
        let topLeft = inside(.top, .left)
        let bottomRight = inside(.bottom, .right)
        // Goals in time order: TL TL BR BR TL → pairs: TL→TL yes, TL→BR no,
        // BR→BR yes, BR→TL no. 2 of 4 repeat.
        let targets = [topLeft, topLeft, bottomRight, bottomRight, topLeft]
        let shots = targets.enumerated().map { shot(to: $1, minute: Double($0)) }
        #expect(find(.repeatAfterGoal, in: shooterPatterns(shots)) == nil)
    }

    @Test("Fewer than 4 pairs after a goal does not fire")
    func repeatBelowSample() {
        let topLeft = inside(.top, .left)
        let shots = (0..<4).map { shot(to: topLeft, minute: Double($0)) }
        #expect(find(.repeatAfterGoal, in: shooterPatterns(shots)) == nil)
    }
}

@Suite("Scouting patterns: goalkeeper")
struct ScoutingPatternGoalkeeperTests {
    @Test("A weak height is the share of goals conceded there; saves stay out")
    func concededHeight() throws {
        let shots = repeated(3) { faced(to: inside(.bottom, .left), outcome: .goal) }
            + repeated(2) { faced(to: inside(.top, .left), outcome: .goal) }
            + repeated(6) { faced(to: inside(.top, .right), outcome: .saved) }
        let patterns = goalkeeperPatterns(shots)
        #expect(find(.concededHeight(.bottom), in: patterns)?.tally == Tally(successes: 3, attempts: 5))
        #expect(find(.concededSide(.left), in: patterns)?.tally == Tally(successes: 5, attempts: 5))
    }

    @Test("4 goals conceded are below the minimum sample")
    func concededBelowSample() {
        let shots = repeated(4) { faced(to: inside(.bottom, .left), outcome: .goal) }
        #expect(goalkeeperPatterns(shots).isEmpty)
    }

    @Test("Standing vs jump save rates fire on a gap of 0.3 or more")
    func deliverySaves() throws {
        let shots = repeated(4) { faced(outcome: .saved, delivery: .standing) }
            + [faced(outcome: .goal, delivery: .jump)]
            + repeated(3) { faced(outcome: .goal, delivery: .jump) }
            + [faced(outcome: .saved, delivery: .jump)]
        let pattern = try #require(find(.deliverySaves, in: goalkeeperPatterns(shots)))
        #expect(pattern.tally == Tally(successes: 4, attempts: 4))
        #expect(pattern.contrast == Tally(successes: 1, attempts: 5))
    }

    @Test("7 m save record needs the minimum sample of 7 m shots on target")
    func sevenMeterSaves() {
        let four = repeated(4) { faced(from: nil, sevenMeters: true, outcome: .saved) }
        #expect(find(.sevenMeterSaves, in: goalkeeperPatterns(four)) == nil)
        let five = four + [faced(from: nil, sevenMeters: true, outcome: .goal)]
        #expect(find(.sevenMeterSaves, in: goalkeeperPatterns(five))?.tally == Tally(successes: 4, attempts: 5))
        #expect(find(.concededSide(.center), in: goalkeeperPatterns(five)) == nil)
    }
}

@Suite("Scouting patterns: ranking")
struct ScoutingPatternRankingTests {
    private func pattern(_ kind: ScoutingPatternKind, _ successes: Int, _ attempts: Int) -> ScoutingPattern {
        ScoutingPattern(kind: kind, tally: Tally(successes: successes, attempts: attempts))
    }

    @Test("Ranks by strength, then sample size, then a fixed kind order")
    func deterministicOrder() {
        let side = pattern(.side(.left), 3, 5)
        let height = pattern(.height(.bottom), 3, 5)
        let biggerSample = pattern(.origin(CourtZone(sector: .center, depth: .near)), 6, 10)
        let strongest = pattern(.line(.crossShot), 4, 5)
        let expected = [strongest, biggerSample, height, side]
        #expect(StatsEngine.ranked([side, height, biggerSample, strongest]) == expected)
        #expect(StatsEngine.ranked([height, strongest, side, biggerSample]) == expected)
    }

    @Test("A comparison ranks by its gap, a 7 m record by how far it leans")
    func strength() {
        let distance = ScoutingPattern(
            kind: .distance,
            tally: Tally(successes: 3, attempts: 4),
            contrast: Tally(successes: 0, attempts: 4)
        )
        #expect(distance.strength == 0.75)
        #expect(pattern(.sevenMeterSaves, 1, 5).strength == 0.8)
    }
}

@Suite("Scouting patterns: demo data")
struct ScoutingPatternDemoTests {
    @Test("Demo shooter and goalkeeper both show consistent patterns")
    func demoPatterns() {
        let engine = StatsEngine(shots: DemoData.shots)
        let shooter = engine.shots(by: DemoData.leftBackPauVidal.number).shooterPatterns()
        let goalkeeper = engine.shots(facing: DemoData.goalkeeperMarcPuig.number).goalkeeperPatterns()
        #expect(!shooter.isEmpty)
        #expect(!goalkeeper.isEmpty)
        for pattern in shooter + goalkeeper {
            #expect(pattern.tally.successes <= pattern.tally.attempts)
            // Comparisons and repeats have their own floor of 4; every
            // single-sample tendency needs the general minimum of 5.
            switch pattern.kind {
            case .distance, .deliverySaves, .repeatAfterGoal:
                #expect(pattern.tally.attempts >= ScoutingPattern.comparisonMinimumSample)
            default:
                #expect(pattern.tally.attempts >= ScoutingPattern.minimumSample)
            }
            if let conversion = pattern.conversion {
                #expect(conversion.successes <= conversion.attempts)
            }
        }
    }
}
