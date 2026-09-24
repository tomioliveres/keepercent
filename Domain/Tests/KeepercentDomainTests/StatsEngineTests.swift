import Foundation
import Testing
@testable import KeepercentDomain

private let referenceDate = Date(timeIntervalSince1970: 0)

/// Builds a `Shot` with sensible defaults, so each test only states the
/// fields it actually cares about. Matches the builder style in
/// ShotTests.swift.
private func shot(
    attackingSide: AttackingSide = .rival,
    shooter: Player? = nil,
    facingGoalkeeper: Player? = nil,
    originPoint: CourtPoint? = nil,
    isSevenMeters: Bool = false,
    target: GoalTarget = .inside(GoalZone(row: .middle, column: .center)),
    outcome: ShotOutcome = .goal
) -> Shot {
    Shot(
        attackingSide: attackingSide,
        shooter: shooter,
        facingGoalkeeper: facingGoalkeeper,
        originPoint: originPoint,
        isSevenMeters: isSevenMeters,
        target: target,
        outcome: outcome,
        date: referenceDate
    )
}

/// A point that lands in the left wing, near zone — matching the demo
/// dataset's convention for stating an origin as metres from the goal.
private func point(xMeters: Double, yMeters: Double, geometry: CourtGeometry = .standard) -> CourtPoint {
    CourtPoint(x: xMeters / geometry.widthInMeters + 0.5, y: yMeters / geometry.depthInMeters)
}

private let leftWingNear = point(xMeters: -8, yMeters: 3)
private let rightWingNear = point(xMeters: 8, yMeters: 3)
private let leftWingNearZone = CourtZone(sector: .leftWing, depth: .near)
private let rightWingNearZone = CourtZone(sector: .rightWing, depth: .near)

@Suite("Tally")
struct TallyTests {

    @Test("rate is nil when nothing was attempted")
    func rateIsNilAtZeroAttempts() {
        let tally = Tally(successes: 0, attempts: 0)
        #expect(tally.rate == nil)
    }

    @Test("rate is the exact fraction of successes over attempts")
    func rateIsExactFraction() {
        let tally = Tally(successes: 3, attempts: 4)
        #expect(tally.rate == 0.75)
    }

    @Test("rate is zero, not nil, when every attempt failed")
    func rateIsZeroNotNilWhenNothingSucceeded() {
        let tally = Tally(successes: 0, attempts: 2)
        #expect(tally.rate == 0)
    }
}

@Suite("StatsEngine on an empty shot list")
struct EmptyEngineTests {
    private let engine = StatsEngine(shots: [])

    @Test("every outcome is zero-filled")
    func outcomeCountsAreZeroFilled() {
        let counts = engine.outcomeCounts
        for outcome in ShotOutcome.allCases {
            #expect(counts[outcome] == 0)
        }
    }

    @Test("effectiveness has no attempts and a nil rate")
    func effectivenessHasNoAttempts() {
        #expect(engine.effectiveness == Tally(successes: 0, attempts: 0))
    }

    @Test("save rate has no attempts and a nil rate")
    func saveRateHasNoAttempts() {
        #expect(engine.saveRate == Tally(successes: 0, attempts: 0))
    }

    @Test("per-origin, per-zone and per-pair breakdowns are empty")
    func breakdownsAreEmpty() {
        #expect(engine.effectivenessByOrigin.isEmpty)
        #expect(engine.effectivenessByGoalZone.isEmpty)
        #expect(engine.effectivenessByOriginTarget.isEmpty)
        #expect(engine.saveRateByGoalZone.isEmpty)
    }

    @Test("height and line distributions are zero-filled, not empty")
    func distributionsAreZeroFilled() {
        let heights = engine.heightDistribution
        for height in ShotHeight.allCases {
            #expect(heights[height] == 0)
        }
        let lines = engine.lineDistribution
        for line in ShotLine.allCases {
            #expect(lines[line] == 0)
        }
    }
}

@Suite("StatsEngine filters")
struct FilterTests {

    @Test("shots(by:) keeps only rival shots from that shooter number")
    func filtersByShooterNumber() {
        let shooter7 = Player(number: 7)
        let shooter9 = Player(number: 9)
        let engine = StatsEngine(shots: [
            shot(attackingSide: .rival, shooter: shooter7),
            shot(attackingSide: .rival, shooter: shooter9),
            shot(attackingSide: .own, facingGoalkeeper: shooter7)
        ])
        let filtered = engine.shots(by: 7)
        #expect(filtered.shots.count == 1)
        #expect(filtered.shots.first?.shooter == shooter7)
    }

    @Test("shots(facing:) keeps only own-side shots against that goalkeeper number")
    func filtersByGoalkeeperNumber() {
        let goalkeeper1 = Player(number: 1)
        let goalkeeper2 = Player(number: 2)
        let engine = StatsEngine(shots: [
            shot(attackingSide: .own, facingGoalkeeper: goalkeeper1),
            shot(attackingSide: .own, facingGoalkeeper: goalkeeper2),
            shot(attackingSide: .rival, shooter: goalkeeper1)
        ])
        let filtered = engine.shots(facing: 1)
        #expect(filtered.shots.count == 1)
        #expect(filtered.shots.first?.facingGoalkeeper == goalkeeper1)
    }

    @Test("a shirt number shared by a rival shooter and an own goalkeeper never leaks across sides")
    func sameNumberDoesNotLeakAcrossSides() {
        let sharedNumber = 4
        let engine = StatsEngine(shots: [
            shot(attackingSide: .rival, shooter: Player(number: sharedNumber)),
            shot(attackingSide: .own, facingGoalkeeper: Player(number: sharedNumber))
        ])
        #expect(engine.shots(by: sharedNumber).shots.count == 1)
        #expect(engine.shots(facing: sharedNumber).shots.count == 1)
        #expect(engine.shots(by: sharedNumber).shots.first?.attackingSide == .rival)
        #expect(engine.shots(facing: sharedNumber).shots.first?.attackingSide == .own)
    }

    @Test("shots(from:) keeps only shots with that exact origin")
    func filtersByOrigin() {
        let engine = StatsEngine(shots: [
            shot(originPoint: leftWingNear),
            shot(originPoint: rightWingNear),
            shot(isSevenMeters: true)
        ])
        let filtered = engine.shots(from: .zone(leftWingNearZone))
        #expect(filtered.shots.count == 1)
        #expect(filtered.shots.first?.origin == .zone(leftWingNearZone))
    }

    @Test("filters chain: shooter then origin narrows further")
    func filtersChain() {
        let shooter7 = Player(number: 7)
        let engine = StatsEngine(shots: [
            shot(attackingSide: .rival, shooter: shooter7, originPoint: leftWingNear),
            shot(attackingSide: .rival, shooter: shooter7, originPoint: rightWingNear),
            shot(attackingSide: .rival, shooter: Player(number: 9), originPoint: leftWingNear)
        ])
        let chained = engine.shots(by: 7).shots(from: .zone(leftWingNearZone))
        #expect(chained.shots.count == 1)
    }

    @Test("rivalShots and ownShots separate the two attacking sides")
    func rivalAndOwnAreSeparated() {
        let engine = StatsEngine(shots: [
            shot(attackingSide: .rival),
            shot(attackingSide: .rival),
            shot(attackingSide: .own)
        ])
        #expect(engine.rivalShots.shots.count == 2)
        #expect(engine.ownShots.shots.count == 1)
    }

    @Test("fieldShots excludes 7 m throws, sevenMeterShots keeps only them")
    func fieldAndSevenMeterAreSeparated() {
        let engine = StatsEngine(shots: [
            shot(originPoint: leftWingNear, isSevenMeters: false),
            shot(isSevenMeters: true),
            shot(isSevenMeters: true)
        ])
        #expect(engine.fieldShots.shots.count == 1)
        #expect(engine.sevenMeterShots.shots.count == 2)
    }
}

@Suite("StatsEngine.effectiveness")
struct EffectivenessTests {

    @Test("counts goals over every shot regardless of origin")
    func countsAllShots() {
        let engine = StatsEngine(shots: [
            shot(outcome: .goal),
            shot(originPoint: nil, isSevenMeters: false, outcome: .saved),
            shot(outcome: .out)
        ])
        #expect(engine.effectiveness == Tally(successes: 1, attempts: 3))
    }

    @Test("a nil-origin shot counts toward overall effectiveness but not by-origin")
    func nilOriginCountsOverallOnlyNotByOrigin() {
        let engine = StatsEngine(shots: [
            shot(originPoint: nil, isSevenMeters: false, outcome: .goal),
            shot(originPoint: leftWingNear, outcome: .goal)
        ])
        #expect(engine.effectiveness == Tally(successes: 2, attempts: 2))
        #expect(engine.effectivenessByOrigin.count == 1)
        #expect(engine.effectivenessByOrigin[.zone(leftWingNearZone)] == Tally(successes: 1, attempts: 1))
    }

    @Test("effectivenessByOrigin only lists origins that actually have shots, keeping 7 m separate")
    func byOriginOnlyListsPresentOrigins() {
        let engine = StatsEngine(shots: [
            shot(originPoint: leftWingNear, outcome: .goal),
            shot(originPoint: leftWingNear, outcome: .saved),
            shot(isSevenMeters: true, outcome: .goal)
        ])
        let byOrigin = engine.effectivenessByOrigin
        #expect(byOrigin.count == 2)
        #expect(byOrigin[.zone(leftWingNearZone)] == Tally(successes: 1, attempts: 2))
        #expect(byOrigin[.sevenMeters] == Tally(successes: 1, attempts: 1))
        #expect(byOrigin[.zone(rightWingNearZone)] == nil)
    }

    @Test("effectivenessByGoalZone only considers .inside targets")
    func byGoalZoneOnlyConsidersInsideTargets() {
        let zone = GoalZone(row: .top, column: .left)
        let engine = StatsEngine(shots: [
            shot(target: .inside(zone), outcome: .goal),
            shot(target: .inside(zone), outcome: .saved),
            shot(target: .post(.crossbarCenter), outcome: .post),
            shot(target: .out(.wideLeft), outcome: .out)
        ])
        let byZone = engine.effectivenessByGoalZone
        #expect(byZone.count == 1)
        #expect(byZone[zone] == Tally(successes: 1, attempts: 2))
    }

    @Test("effectivenessByOriginTarget only pairs a non-nil origin with an .inside target")
    func byOriginTargetOnlyPairsRecordedOriginsWithInsideTargets() {
        let zone = GoalZone(row: .bottom, column: .right)
        let engine = StatsEngine(shots: [
            shot(originPoint: leftWingNear, target: .inside(zone), outcome: .goal),
            shot(originPoint: nil, isSevenMeters: false, target: .inside(zone), outcome: .goal),
            shot(originPoint: leftWingNear, target: .post(.crossbarCenter), outcome: .post)
        ])
        let byPair = engine.effectivenessByOriginTarget
        let pair = OriginTargetPair(origin: .zone(leftWingNearZone), zone: zone)
        #expect(byPair.count == 1)
        #expect(byPair[pair] == Tally(successes: 1, attempts: 1))
    }
}

@Suite("StatsEngine.saveRate")
struct SaveRateTests {

    @Test("ignores post and out outcomes")
    func ignoresPostAndOut() {
        let engine = StatsEngine(shots: [
            shot(outcome: .goal),
            shot(outcome: .saved),
            shot(outcome: .post),
            shot(outcome: .out)
        ])
        #expect(engine.saveRate == Tally(successes: 1, attempts: 2))
    }

    @Test("counts a saved shot even when its stored target looks inconsistent with a save")
    func countsSavedShotRegardlessOfTargetShape() {
        // The outcome alone decides "on target"; the target is not
        // re-validated against it (docs/mvp.md decision recorded in the task).
        let engine = StatsEngine(shots: [
            shot(target: .out(.wideLeft), outcome: .saved)
        ])
        #expect(engine.saveRate == Tally(successes: 1, attempts: 1))
    }

    @Test("saveRateByGoalZone only considers .inside targets")
    func byGoalZoneOnlyConsidersInsideTargets() {
        let zone = GoalZone(row: .middle, column: .right)
        let engine = StatsEngine(shots: [
            shot(target: .inside(zone), outcome: .saved),
            shot(target: .inside(zone), outcome: .goal),
            shot(target: .post(.crossbarCenter), outcome: .post)
        ])
        let byZone = engine.saveRateByGoalZone
        #expect(byZone.count == 1)
        #expect(byZone[zone] == Tally(successes: 1, attempts: 2))
    }

    @Test("saveRateByGoalZone keeps each zone's tally apart")
    func byGoalZoneKeepsZonesApart() {
        let topLeft = GoalZone(row: .top, column: .left)
        let bottomRight = GoalZone(row: .bottom, column: .right)
        let engine = StatsEngine(shots: [
            shot(target: .inside(topLeft), outcome: .saved),
            shot(target: .inside(topLeft), outcome: .saved),
            shot(target: .inside(bottomRight), outcome: .goal)
        ])
        let byZone = engine.saveRateByGoalZone
        #expect(byZone.count == 2)
        #expect(byZone[topLeft] == Tally(successes: 2, attempts: 2))
        #expect(byZone[bottomRight] == Tally(successes: 0, attempts: 1))
    }
}

@Suite("StatsEngine.heightDistribution and lineDistribution")
struct DistributionTests {

    @Test("heightDistribution is zero-filled and skips targets with no height")
    func heightDistributionIsZeroFilledAndSkipsMisses() {
        let engine = StatsEngine(shots: [
            shot(target: .inside(GoalZone(row: .top, column: .left)), outcome: .goal),
            shot(target: .out(.over), outcome: .out)
        ])
        let heights = engine.heightDistribution
        #expect(heights[.top] == 1)
        #expect(heights[.middle] == 0)
        #expect(heights[.bottom] == 0)
    }

    @Test("lineDistribution is zero-filled and skips shots with no line")
    func lineDistributionIsZeroFilledAndSkipsNoOrigin() {
        let engine = StatsEngine(shots: [
            shot(
                originPoint: leftWingNear,
                target: .inside(GoalZone(row: .middle, column: .right)),
                outcome: .goal
            ),
            shot(originPoint: nil, isSevenMeters: false, outcome: .goal)
        ])
        let lines = engine.lineDistribution
        #expect(lines[.crossShot] == 1)
        #expect(lines[.nearPost] == 0)
        #expect(lines[.neutral] == 0)
    }

    @Test("a 7 m throw reads as neutral, and fieldShots keeps it out")
    func sevenMeterThrowReadsAsNeutral() {
        let engine = StatsEngine(shots: [
            shot(isSevenMeters: true, target: .inside(GoalZone(row: .top, column: .left)), outcome: .goal)
        ])
        #expect(engine.lineDistribution[.neutral] == 1)
        #expect(engine.fieldShots.lineDistribution[.neutral] == 0)
    }
}

@Suite("StatsEngine over DemoData.shots")
struct DemoDataIntegrationTests {
    private let engine = StatsEngine(shots: DemoData.shots)

    @Test("outcome counts add up to the total number of shots")
    func outcomeCountsSumToTotal() {
        let total = engine.outcomeCounts.values.reduce(0, +)
        #expect(total == DemoData.shots.count)
    }

    @Test("per-origin attempts plus nil-origin shots add up to the total number of shots")
    func perOriginAttemptsPlusNilOriginSumToTotal() {
        let byOriginAttempts = engine.effectivenessByOrigin.values.reduce(0) { $0 + $1.attempts }
        let nilOriginCount = DemoData.shots.filter { $0.origin == nil }.count
        #expect(byOriginAttempts + nilOriginCount == DemoData.shots.count)
    }
}

@Suite("StatsEngine.saveRateByOrigin")
struct SaveRateByOriginTests {

    @Test("only origins with an on-target shot appear")
    func onlyOnTargetOriginsAppear() {
        let engine = StatsEngine(shots: [
            // Missed entirely: has an origin, but never on target, so it
            // must not show up as a 0% save rate.
            shot(originPoint: leftWingNear, target: .out(.wideLeft), outcome: .out),
            shot(originPoint: rightWingNear, outcome: .saved)
        ])
        let byOrigin = engine.saveRateByOrigin
        #expect(byOrigin.count == 1)
        #expect(byOrigin[.zone(leftWingNearZone)] == nil)
        #expect(byOrigin[.zone(rightWingNearZone)] == Tally(successes: 1, attempts: 1))
    }

    @Test("keeps each origin's tally apart, including the 7 m mark")
    func keepsOriginsApartIncludingSevenMeters() {
        let engine = StatsEngine(shots: [
            shot(originPoint: leftWingNear, outcome: .saved),
            shot(originPoint: leftWingNear, outcome: .goal),
            shot(isSevenMeters: true, outcome: .goal)
        ])
        let byOrigin = engine.saveRateByOrigin
        #expect(byOrigin.count == 2)
        #expect(byOrigin[.zone(leftWingNearZone)] == Tally(successes: 1, attempts: 2))
        #expect(byOrigin[.sevenMeters] == Tally(successes: 0, attempts: 1))
    }

    @Test("a shot with no origin is skipped")
    func skipsShotsWithNoOrigin() {
        let engine = StatsEngine(shots: [
            shot(originPoint: nil, isSevenMeters: false, outcome: .saved)
        ])
        #expect(engine.saveRateByOrigin.isEmpty)
    }
}

@Suite("StatsReading and the reading-driven tally lookups")
struct StatsReadingTests {

    @Test("StatsReading has exactly the shooter and goalkeeper cases")
    func hasBothCases() {
        #expect(StatsReading.allCases == [.effectiveness, .saveRate])
    }

    @Test("goalZoneTallies routes to the matching per-zone breakdown")
    func goalZoneTalliesRoutesByReading() {
        let zone = GoalZone(row: .top, column: .left)
        let engine = StatsEngine(shots: [
            shot(target: .inside(zone), outcome: .goal),
            shot(target: .inside(zone), outcome: .saved)
        ])
        #expect(engine.goalZoneTallies(.effectiveness) == engine.effectivenessByGoalZone)
        #expect(engine.goalZoneTallies(.saveRate) == engine.saveRateByGoalZone)
        #expect(engine.goalZoneTallies(.effectiveness)[zone] == Tally(successes: 1, attempts: 2))
        #expect(engine.goalZoneTallies(.saveRate)[zone] == Tally(successes: 1, attempts: 2))
    }

    @Test("originTallies routes to the matching per-origin breakdown")
    func originTalliesRoutesByReading() {
        let engine = StatsEngine(shots: [
            shot(originPoint: leftWingNear, outcome: .goal),
            shot(originPoint: leftWingNear, outcome: .saved)
        ])
        #expect(engine.originTallies(.effectiveness) == engine.effectivenessByOrigin)
        #expect(engine.originTallies(.saveRate) == engine.saveRateByOrigin)
        let origin = ShotOrigin.zone(leftWingNearZone)
        #expect(engine.originTallies(.effectiveness)[origin] == Tally(successes: 1, attempts: 2))
        #expect(engine.originTallies(.saveRate)[origin] == Tally(successes: 1, attempts: 2))
    }
}

@Suite("StatsEngine.goalEngine(forSelectedOrigin:)")
struct GoalEngineForSelectedOriginTests {

    @Test("nil selection reads field shots, excluding 7 m")
    func nilSelectionReadsFieldShots() {
        let engine = StatsEngine(shots: [
            shot(originPoint: leftWingNear),
            shot(isSevenMeters: true)
        ])
        let goalEngine = engine.goalEngine(forSelectedOrigin: nil)
        #expect(goalEngine == engine.fieldShots)
        #expect(goalEngine.shots.count == 1)
    }

    @Test("a selected zone narrows to exactly that origin's shots")
    func selectedZoneNarrowsToThatOrigin() {
        let engine = StatsEngine(shots: [
            shot(originPoint: leftWingNear),
            shot(originPoint: rightWingNear)
        ])
        let goalEngine = engine.goalEngine(forSelectedOrigin: .zone(leftWingNearZone))
        #expect(goalEngine == engine.shots(from: .zone(leftWingNearZone)))
        #expect(goalEngine.shots.count == 1)
    }

    @Test("selecting the 7 m mark stays apart, unlike nil")
    func selectingSevenMetersStaysApart() {
        let engine = StatsEngine(shots: [
            shot(originPoint: leftWingNear),
            shot(isSevenMeters: true)
        ])
        let goalEngine = engine.goalEngine(forSelectedOrigin: .sevenMeters)
        #expect(goalEngine == engine.shots(from: .sevenMeters))
        #expect(goalEngine.shots.count == 1)
    }
}

@Suite("StatsEngine.topGoalZones")
struct TopGoalZonesTests {
    private let topLeft = GoalZone(row: .top, column: .left)
    private let topCenter = GoalZone(row: .top, column: .center)
    private let topRight = GoalZone(row: .top, column: .right)
    private let middleLeft = GoalZone(row: .middle, column: .left)

    @Test("ranks by goal count, descending")
    func ranksByGoalCountDescending() throws {
        let engine = StatsEngine(shots: [
            shot(target: .inside(topLeft), outcome: .goal),
            shot(target: .inside(topRight), outcome: .goal),
            shot(target: .inside(topRight), outcome: .goal),
            shot(target: .inside(topRight), outcome: .saved)
        ])
        let ranked = engine.topGoalZones(limit: 3)
        let first = try #require(ranked.first)
        #expect(first.key == topRight)
        #expect(first.tally == Tally(successes: 2, attempts: 3))
        let second = try #require(ranked.dropFirst().first)
        #expect(second.key == topLeft)
        #expect(second.tally == Tally(successes: 1, attempts: 1))
    }

    @Test("ties on goal count break on fewer attempts, i.e. the higher rate")
    func tiesBreakOnFewerAttempts() throws {
        let engine = StatsEngine(shots: [
            // topLeft: 1 goal in 1 attempt (100%).
            shot(target: .inside(topLeft), outcome: .goal),
            // topRight: 1 goal in 2 attempts (50%).
            shot(target: .inside(topRight), outcome: .goal),
            shot(target: .inside(topRight), outcome: .saved)
        ])
        let ranked = engine.topGoalZones(limit: 2)
        let first = try #require(ranked.first)
        #expect(first.key == topLeft)
        let second = try #require(ranked.dropFirst().first)
        #expect(second.key == topRight)
    }

    @Test("ties on goals and attempts break on the zone's canonical order")
    func tiesBreakOnCanonicalOrder() throws {
        let engine = StatsEngine(shots: [
            // topCenter and topLeft tie: 1 goal in 1 attempt each.
            // topLeft precedes topCenter in GoalZone.allCases.
            shot(target: .inside(topCenter), outcome: .goal),
            shot(target: .inside(topLeft), outcome: .goal)
        ])
        let ranked = engine.topGoalZones(limit: 2)
        let first = try #require(ranked.first)
        #expect(first.key == topLeft)
        let second = try #require(ranked.dropFirst().first)
        #expect(second.key == topCenter)
    }

    @Test("a zone with attempts but no goals is not ranked")
    func zeroGoalZoneIsExcluded() {
        let engine = StatsEngine(shots: [
            shot(target: .inside(topLeft), outcome: .goal),
            shot(target: .inside(topRight), outcome: .saved),
            shot(target: .inside(topRight), outcome: .saved)
        ])
        let ranked = engine.topGoalZones(limit: 3)
        #expect(ranked.count == 1)
        #expect(!ranked.contains { $0.key == topRight })
    }

    @Test("limit caps the number of ranked zones returned")
    func limitCapsCount() {
        let engine = StatsEngine(shots: [
            shot(target: .inside(topLeft), outcome: .goal),
            shot(target: .inside(topCenter), outcome: .goal),
            shot(target: .inside(topRight), outcome: .goal),
            shot(target: .inside(middleLeft), outcome: .goal)
        ])
        let ranked = engine.topGoalZones(limit: 3)
        #expect(ranked.count == 3)
    }

    @Test("an empty engine ranks no zones")
    func emptyEngineRanksNothing() {
        let engine = StatsEngine(shots: [])
        #expect(engine.topGoalZones(limit: 3).isEmpty)
    }
}

@Suite("StatsEngine.topOrigins")
struct TopOriginsTests {

    @Test("ranks by goal count, descending, reusing effectivenessByOrigin")
    func ranksByGoalCountDescending() throws {
        let engine = StatsEngine(shots: [
            shot(originPoint: leftWingNear, outcome: .goal),
            shot(originPoint: rightWingNear, outcome: .goal),
            shot(originPoint: rightWingNear, outcome: .goal),
            shot(originPoint: rightWingNear, outcome: .saved)
        ])
        let ranked = engine.topOrigins(limit: 2)
        let first = try #require(ranked.first)
        #expect(first.key == .zone(rightWingNearZone))
        #expect(first.tally == Tally(successes: 2, attempts: 3))
        let second = try #require(ranked.dropFirst().first)
        #expect(second.key == .zone(leftWingNearZone))
    }

    @Test("the 7 m mark ranks alongside court zones, by the same rules")
    func sevenMetersRanksAlongsideZones() throws {
        let engine = StatsEngine(shots: [
            shot(isSevenMeters: true, outcome: .goal),
            shot(originPoint: leftWingNear, outcome: .goal),
            shot(originPoint: leftWingNear, outcome: .saved)
        ])
        // sevenMeters: 1/1 (100%), leftWingNear: 1/2 (50%) — sevenMeters wins the tie-break.
        let ranked = engine.topOrigins(limit: 2)
        let first = try #require(ranked.first)
        #expect(first.key == .sevenMeters)
    }

    @Test("an origin with attempts but no goals is not ranked")
    func zeroGoalOriginIsExcluded() {
        let engine = StatsEngine(shots: [
            shot(originPoint: leftWingNear, outcome: .goal),
            shot(originPoint: rightWingNear, outcome: .saved)
        ])
        let ranked = engine.topOrigins(limit: 3)
        #expect(ranked.count == 1)
        #expect(!ranked.contains { $0.key == .zone(rightWingNearZone) })
    }

    @Test("limit caps the number of ranked origins returned")
    func limitCapsCount() {
        let engine = StatsEngine(shots: [
            shot(originPoint: leftWingNear, outcome: .goal),
            shot(originPoint: rightWingNear, outcome: .goal),
            shot(isSevenMeters: true, outcome: .goal)
        ])
        let ranked = engine.topOrigins(limit: 1)
        #expect(ranked.count == 1)
    }

    @Test("an empty engine ranks no origins")
    func emptyEngineRanksNothing() {
        let engine = StatsEngine(shots: [])
        #expect(engine.topOrigins(limit: 3).isEmpty)
    }
}
