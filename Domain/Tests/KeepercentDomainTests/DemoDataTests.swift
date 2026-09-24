import Foundation
import Testing
@testable import KeepercentDomain

/// The calendar day (UTC) a date falls on, so determinism tests compare
/// dates without depending on the local time zone the test happens to run
/// in.
private func utcDay(_ date: Date) -> DateComponents {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar.dateComponents([.year, .month, .day], from: date)
}

@Suite("DemoData roster is internally consistent")
struct DemoDataRosterTests {

    @Test("Shirt numbers are unique")
    func shirtNumbersAreUnique() {
        let numbers = DemoData.roster.map(\.number)
        #expect(Set(numbers).count == numbers.count)
    }

    @Test("The roster has a realistic size: 8-10 field players plus 2 goalkeepers")
    func rosterSizeIsRealistic() {
        let goalkeepers = DemoData.roster.filter(\.isGoalkeeper)
        let fieldPlayers = DemoData.roster.filter { !$0.isGoalkeeper }
        #expect(goalkeepers.count == 2)
        #expect(fieldPlayers.count >= 8)
        #expect(fieldPlayers.count <= 10)
    }

    @Test("Exactly the intended goalkeepers are flagged isGoalkeeper")
    func exactlyTheIntendedGoalkeepersAreFlagged() {
        let goalkeeperNumbers = Set(DemoData.roster.filter(\.isGoalkeeper).map(\.number))
        #expect(goalkeeperNumbers == [DemoData.goalkeeperMarcPuig.number, DemoData.goalkeeperDavidSoler.number])
    }

    @Test("Most roster players have a recorded handedness, a scouting-relevant detail")
    func mostPlayersHaveHandedness() {
        let withHandedness = DemoData.roster.filter { $0.handedness != nil }
        #expect(withHandedness.count >= DemoData.roster.count / 2)
    }
}

@Suite("DemoData shots respect the attacking-side invariant")
struct DemoDataShotSideInvariantTests {

    @Test("A .rival shot has a shooter and no facingGoalkeeper", arguments: DemoData.shots.filter { $0.attackingSide == .rival })
    func rivalShotHasShooterOnly(shot: Shot) throws {
        #expect(shot.shooter != nil)
        #expect(shot.facingGoalkeeper == nil)
    }

    @Test("An .own shot has a facingGoalkeeper and no shooter", arguments: DemoData.shots.filter { $0.attackingSide == .own })
    func ownShotHasFacingGoalkeeperOnly(shot: Shot) throws {
        #expect(shot.facingGoalkeeper != nil)
        #expect(shot.shooter == nil)
    }

    @Test("Every shot's shooter, when present, is not a goalkeeper")
    func shooterIsNeverAGoalkeeper() {
        for shot in DemoData.shots {
            guard let shooter = shot.shooter else { continue }
            #expect(!shooter.isGoalkeeper)
        }
    }

    @Test("Every shot's facingGoalkeeper, when present, is flagged as a goalkeeper")
    func facingGoalkeeperIsAlwaysAGoalkeeper() {
        for shot in DemoData.shots {
            guard let goalkeeper = shot.facingGoalkeeper else { continue }
            #expect(goalkeeper.isGoalkeeper)
        }
    }
}

@Suite("DemoData shot participants belong to the roster")
struct DemoDataParticipantsBelongToRosterTests {

    @Test("Every shooter referenced by a shot belongs to the roster")
    func everyShooterBelongsToRoster() {
        for shot in DemoData.shots {
            guard let shooter = shot.shooter else { continue }
            #expect(DemoData.roster.contains(shooter))
        }
    }

    @Test("Every facingGoalkeeper referenced by a shot belongs to the roster")
    func everyFacingGoalkeeperBelongsToRoster() {
        for shot in DemoData.shots {
            guard let goalkeeper = shot.facingGoalkeeper else { continue }
            #expect(DemoData.roster.contains(goalkeeper))
        }
    }
}

@Suite("DemoData origins resolve through CourtGeometry")
struct DemoDataOriginResolutionTests {

    @Test("Every non-7m shot has an origin that matches CourtGeometry.standard")
    func nonSevenMeterShotsHaveAMatchingOrigin() throws {
        for shot in DemoData.shots where !shot.isSevenMeters {
            let originPoint = try #require(shot.originPoint, "a non-7m demo shot must carry an origin point")
            let expectedZone = try #require(CourtGeometry.standard.zone(at: originPoint), "a demo take-off must be outside the 6m area")
            #expect(shot.origin == .zone(expectedZone))
        }
    }

    @Test("Every 7m shot has origin == .sevenMeters and no originPoint")
    func sevenMeterShotsHaveNoOriginPoint() {
        for shot in DemoData.shots where shot.isSevenMeters {
            #expect(shot.origin == .sevenMeters)
            #expect(shot.originPoint == nil)
        }
    }

    @Test("Every shot with an origin produces a non-nil line")
    func everyShotWithAnOriginProducesALine() {
        for shot in DemoData.shots where shot.origin != nil {
            #expect(shot.line != nil)
        }
    }
}

@Suite("DemoData is a useful, varied demo, not filler")
struct DemoDataDiversityTests {

    @Test("The dataset has a realistic size, around 40 shots")
    func datasetHasARealisticSize() {
        #expect(DemoData.shots.count >= 35)
        #expect(DemoData.shots.count <= 50)
    }

    @Test("Both attacking sides are represented")
    func bothAttackingSidesAreRepresented() {
        #expect(DemoData.shots.contains { $0.attackingSide == .rival })
        #expect(DemoData.shots.contains { $0.attackingSide == .own })
    }

    @Test("More than one distinct outcome is represented")
    func multipleOutcomesAreRepresented() {
        let outcomes = Set(DemoData.shots.map(\.outcome))
        #expect(outcomes.count > 1)
    }

    @Test("At least a handful of 7m throws are represented")
    func sevenMeterThrowsAreRepresented() {
        let sevenMeterShots = DemoData.shots.filter(\.isSevenMeters)
        #expect(sevenMeterShots.count >= 2)
    }

    @Test("Some shots record delivery and approach, and some deliberately omit them")
    func optionalChipsAreBothPresentAndAbsent() {
        #expect(DemoData.shots.contains { $0.delivery != nil })
        #expect(DemoData.shots.contains { $0.delivery == nil })
        #expect(DemoData.shots.contains { $0.approach != nil })
        #expect(DemoData.shots.contains { $0.approach == nil })
    }

    @Test("Shots spread across several distinct court zones, not one corner")
    func shotsSpreadAcrossSeveralZones() {
        let zones: [CourtZone] = DemoData.shots.compactMap { shot in
            guard let originPoint = shot.originPoint else { return nil }
            return CourtGeometry.standard.zone(at: originPoint)
        }
        #expect(Set(zones).count >= 6)
    }
}

@Suite("DemoData encodes a discoverable rival shooter tendency")
struct DemoDataShooterTendencyTests {

    /// Pau Vidal, the demo's left-handed left back, overwhelmingly shoots
    /// cross-shot and low, to the far corner: a jury reading his shots
    /// should recognize the pattern, not see noise.
    private var pauVidalShots: [Shot] {
        DemoData.shots.filter { $0.shooter == DemoData.leftBackPauVidal }
    }

    @Test("Pau Vidal has a meaningful number of recorded shots")
    func pauVidalHasShots() {
        #expect(pauVidalShots.count >= 5)
    }

    @Test("Most of Pau Vidal's shots are cross-shots")
    func mostShotsAreCrossShots() {
        let crossShots = pauVidalShots.filter { $0.line == .crossShot }
        #expect(crossShots.count * 2 > pauVidalShots.count)
    }

    @Test("Most of Pau Vidal's shots with a known target height go low")
    func mostShotsWithKnownHeightGoLow() {
        let withHeight = pauVidalShots.compactMap { shot in
            ShotClassification.targetHeight(shot.target)
        }
        #expect(!withHeight.isEmpty)
        let low = withHeight.filter { $0 == .bottom }
        #expect(low.count * 2 > withHeight.count)
    }
}

@Suite("DemoData encodes a discoverable rival goalkeeper weakness")
struct DemoDataGoalkeeperWeaknessTests {

    /// Marc Puig, the demo's starting goalkeeper, concedes most of his
    /// goals low, on one side: a jury reading his card should recognize the
    /// weakness, not see noise.
    private var marcPuigGoalsConceded: [Shot] {
        DemoData.shots.filter { $0.facingGoalkeeper == DemoData.goalkeeperMarcPuig && $0.outcome == .goal }
    }

    @Test("Marc Puig has a meaningful number of goals conceded")
    func marcPuigHasGoalsConceded() {
        #expect(marcPuigGoalsConceded.count >= 5)
    }

    @Test("Most of Marc Puig's conceded goals land on the same side")
    func mostConcededGoalsLandOnTheSameSide() {
        let sides = marcPuigGoalsConceded.map { ShotClassification.targetSide($0.target) }
        let left = sides.filter { $0 == .left }
        #expect(left.count * 2 > sides.count)
    }

    @Test("Most of Marc Puig's conceded goals go low")
    func mostConcededGoalsGoLow() {
        let heights = marcPuigGoalsConceded.compactMap { ShotClassification.targetHeight($0.target) }
        #expect(!heights.isEmpty)
        let low = heights.filter { $0 == .bottom }
        #expect(low.count * 2 > heights.count)
    }
}

@Suite("DemoData is deterministic")
struct DemoDataDeterminismTests {

    @Test("Every shot's date falls on the same UTC calendar day as sessionDate")
    func everyShotFallsOnTheSameDay() {
        let expectedDay = utcDay(DemoData.sessionDate)
        for shot in DemoData.shots {
            let day = utcDay(shot.date)
            #expect(day.year == expectedDay.year)
            #expect(day.month == expectedDay.month)
            #expect(day.day == expectedDay.day)
        }
    }
}
