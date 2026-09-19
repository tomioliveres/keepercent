import Foundation
import Testing
@testable import KeepercentDomain

/// Builds a normalized point directly from a metric offset from the goal
/// centre, so tests state the intent (metres from the goal) rather than
/// hard-coding normalized magic numbers.
private func point(xMeters: Double, yMeters: Double, geometry: CourtGeometry = .standard) -> CourtPoint {
    CourtPoint(x: xMeters / geometry.widthInMeters + 0.5, y: yMeters / geometry.depthInMeters)
}

/// Builds a normalized point from the signed angle at the goal centre and a
/// fixed distance along the goal-facing axis, matching the geometry under
/// test (`angle = atan2(xMeters, yMeters)`).
private func point(angleDegrees: Double, yMeters: Double, geometry: CourtGeometry = .standard) -> CourtPoint {
    let angleRadians = angleDegrees * .pi / 180
    let xMeters = yMeters * tan(angleRadians)
    return point(xMeters: xMeters, yMeters: yMeters, geometry: geometry)
}

private func mirroredSector(_ sector: CourtSector) -> CourtSector {
    switch sector {
    case .leftWing: return .rightWing
    case .leftBack: return .rightBack
    case .center: return .center
    case .rightBack: return .leftBack
    case .rightWing: return .leftWing
    }
}

private func tolerant(_ a: Double, _ b: Double, tolerance: Double = 1e-9) -> Bool {
    abs(a - b) < tolerance
}

@Suite("CourtPoint clamping")
struct CourtPointClampingTests {

    @Test("In-range values are kept untouched")
    func inRangeValuesAreUntouched() {
        let p = CourtPoint(x: 0.3, y: 0.7)
        #expect(tolerant(p.x, 0.3))
        #expect(tolerant(p.y, 0.7))
    }

    @Test(
        "Out-of-range values clamp to 0...1",
        arguments: [
            (x: -0.5, y: 0.5, expectedX: 0.0, expectedY: 0.5),
            (x: 1.5, y: 0.5, expectedX: 1.0, expectedY: 0.5),
            (x: 0.5, y: -0.2, expectedX: 0.5, expectedY: 0.0),
            (x: 0.5, y: 1.2, expectedX: 0.5, expectedY: 1.0),
            (x: -10.0, y: 10.0, expectedX: 0.0, expectedY: 1.0)
        ]
    )
    func outOfRangeValuesClamp(input: (x: Double, y: Double, expectedX: Double, expectedY: Double)) {
        let p = CourtPoint(x: input.x, y: input.y)
        #expect(tolerant(p.x, input.expectedX))
        #expect(tolerant(p.y, input.expectedY))
    }

    @Test("A NaN coordinate resolves to the documented midpoint 0.5")
    func nanResolvesToMidpoint() {
        let p = CourtPoint(x: .nan, y: .nan)
        #expect(tolerant(p.x, 0.5))
        #expect(tolerant(p.y, 0.5))
        #expect(p.x.isFinite)
        #expect(p.y.isFinite)
    }

    @Test("Positive and negative infinity clamp like any other out-of-range value")
    func infinityClampsLikeAnyOtherValue() {
        let positive = CourtPoint(x: .infinity, y: .infinity)
        #expect(tolerant(positive.x, 1.0))
        #expect(tolerant(positive.y, 1.0))

        let negative = CourtPoint(x: -.infinity, y: -.infinity)
        #expect(tolerant(negative.x, 0.0))
        #expect(tolerant(negative.y, 0.0))
    }
}

@Suite("CourtGeometry sector boundaries")
struct CourtGeometrySectorBoundaryTests {

    let geometry = CourtGeometry.standard

    @Test("Exactly 18 degrees on either side is center (tie-break to the more central sector)")
    func eighteenDegreesIsCenter() {
        #expect(geometry.sector(at: point(angleDegrees: 18, yMeters: 5, geometry: geometry)) == .center)
        #expect(geometry.sector(at: point(angleDegrees: -18, yMeters: 5, geometry: geometry)) == .center)
    }

    @Test("Just past 18 degrees is a back, on both sides")
    func justPastEighteenDegreesIsBack() {
        #expect(geometry.sector(at: point(angleDegrees: 18.5, yMeters: 5, geometry: geometry)) == .rightBack)
        #expect(geometry.sector(at: point(angleDegrees: -18.5, yMeters: 5, geometry: geometry)) == .leftBack)
    }

    @Test("Exactly 54 degrees on either side is a back (tie-break to the more central sector)")
    func fiftyFourDegreesIsBack() {
        #expect(geometry.sector(at: point(angleDegrees: 54, yMeters: 5, geometry: geometry)) == .rightBack)
        #expect(geometry.sector(at: point(angleDegrees: -54, yMeters: 5, geometry: geometry)) == .leftBack)
    }

    @Test("Just past 54 degrees is a wing, on both sides")
    func justPastFiftyFourDegreesIsWing() {
        #expect(geometry.sector(at: point(angleDegrees: 54.5, yMeters: 5, geometry: geometry)) == .rightWing)
        #expect(geometry.sector(at: point(angleDegrees: -54.5, yMeters: 5, geometry: geometry)) == .leftWing)
    }
}

@Suite("CourtGeometry left/right matches the shooter's perspective")
struct CourtGeometryShooterPerspectiveTests {

    let geometry = CourtGeometry.standard

    @Test(
        "A point on the screen-left half never derives a right* sector",
        arguments: [0.0, 0.1, 0.2, 0.3, 0.4, 0.49]
    )
    func screenLeftNeverDerivesRightSector(x: Double) {
        for y in [0.05, 0.2, 0.4, 0.6, 0.9] {
            let sector = geometry.sector(at: CourtPoint(x: x, y: y))
            #expect(sector != .rightBack)
            #expect(sector != .rightWing)
        }
    }

    @Test(
        "A point on the screen-right half never derives a left* sector",
        arguments: [0.51, 0.6, 0.7, 0.8, 0.9, 1.0]
    )
    func screenRightNeverDerivesLeftSector(x: Double) {
        for y in [0.05, 0.2, 0.4, 0.6, 0.9] {
            let sector = geometry.sector(at: CourtPoint(x: x, y: y))
            #expect(sector != .leftBack)
            #expect(sector != .leftWing)
        }
    }
}

@Suite("CourtGeometry depth boundary")
struct CourtGeometryDepthBoundaryTests {

    let geometry = CourtGeometry.standard

    @Test("Straight out at exactly 9m is near")
    func exactlyNineMetersStraightOutIsNear() {
        let p = point(xMeters: 0, yMeters: 9, geometry: geometry)
        #expect(geometry.depth(at: p) == .near)
    }

    @Test("Just beyond 9m straight out is far")
    func justBeyondNineMetersStraightOutIsFar() {
        let p = point(xMeters: 0, yMeters: 9.1, geometry: geometry)
        #expect(geometry.depth(at: p) == .far)
    }

    // This is the test that pins the real 9m-line shape: the 9m line is two
    // quarter circles centred on the posts, not a circle centred on the goal
    // centre. A point straight out from a post is farther than 9m from the
    // goal CENTRE (9.12m here) but exactly 9m from the goal MOUTH segment,
    // and must therefore still be `.near`.
    @Test("A point beyond 9m from the goal centre but exactly 9m from the goal mouth is near")
    func goalMouthDistanceGovernsDepthNotGoalCentreDistance() {
        let p = point(xMeters: 1.5, yMeters: 9.0, geometry: geometry)
        let distanceFromCentre = (1.5 * 1.5 + 9.0 * 9.0).squareRoot()
        #expect(distanceFromCentre > geometry.nineMeterLine)
        #expect(geometry.depth(at: p) == .near)
    }
}

@Suite("CourtGeometry symmetry")
struct CourtGeometrySymmetryTests {

    let geometry = CourtGeometry.standard

    @Test(
        "Mirroring a point about the vertical centre line mirrors the sector and leaves depth unchanged",
        arguments: [
            (xMeters: -8.0, yMeters: 3.0),
            (xMeters: -5.0, yMeters: 8.0),
            (xMeters: 0.0, yMeters: 6.0),
            (xMeters: 6.0, yMeters: 10.0),
            (xMeters: 8.0, yMeters: 3.0)
        ]
    )
    func mirroringFlipsSectorAndPreservesDepth(input: (xMeters: Double, yMeters: Double)) {
        let original = point(xMeters: input.xMeters, yMeters: input.yMeters, geometry: geometry)
        let mirrored = CourtPoint(x: 1 - original.x, y: original.y)

        let originalSector = geometry.sector(at: original)
        let mirroredSectorResult = geometry.sector(at: mirrored)

        #expect(mirroredSectorResult == mirroredSector(originalSector))
        #expect(geometry.depth(at: mirrored) == geometry.depth(at: original))
    }
}

@Suite("CourtGeometry zone surjectivity")
struct CourtGeometryZoneSurjectivityTests {

    let geometry = CourtGeometry.standard

    @Test(
        "Every CourtZone is reachable from a representative point",
        arguments: [
            (xMeters: -8.0, yMeters: 3.0, zone: CourtZone(sector: .leftWing, depth: .near)),
            (xMeters: -10.0, yMeters: 7.0, zone: CourtZone(sector: .leftWing, depth: .far)),
            (xMeters: -5.0, yMeters: 8.0, zone: CourtZone(sector: .leftBack, depth: .near)),
            (xMeters: -6.0, yMeters: 10.0, zone: CourtZone(sector: .leftBack, depth: .far)),
            (xMeters: 0.0, yMeters: 6.0, zone: CourtZone(sector: .center, depth: .near)),
            (xMeters: 0.0, yMeters: 11.0, zone: CourtZone(sector: .center, depth: .far)),
            (xMeters: 5.0, yMeters: 8.0, zone: CourtZone(sector: .rightBack, depth: .near)),
            (xMeters: 6.0, yMeters: 10.0, zone: CourtZone(sector: .rightBack, depth: .far)),
            (xMeters: 8.0, yMeters: 3.0, zone: CourtZone(sector: .rightWing, depth: .near)),
            (xMeters: 10.0, yMeters: 7.0, zone: CourtZone(sector: .rightWing, depth: .far))
        ]
    )
    func everyZoneIsReachable(input: (xMeters: Double, yMeters: Double, zone: CourtZone)) {
        let p = point(xMeters: input.xMeters, yMeters: input.yMeters, geometry: geometry)
        #expect(geometry.zone(at: p) == input.zone)
    }
}

@Suite("CourtGeometry realistic playing positions")
struct CourtGeometryRealisticPositionTests {

    let geometry = CourtGeometry.standard

    @Test("A wing at the 6m-line corner near the touchline is wing/near")
    func wingAtSixMeterCornerIsWingNear() {
        let p = point(xMeters: -9.0, yMeters: 3.0, geometry: geometry)
        #expect(geometry.zone(at: p) == CourtZone(sector: .leftWing, depth: .near))
    }

    @Test("A pivot in front of goal around 6m is center/near")
    func pivotInFrontOfGoalIsCenterNear() {
        let p = point(xMeters: 0.0, yMeters: 6.0, geometry: geometry)
        #expect(geometry.zone(at: p) == CourtZone(sector: .center, depth: .near))
    }

    @Test("A back around 10m out and 5m to the side is back/far")
    func backTenMetersOutFiveMetersToTheSideIsBackFar() {
        let p = point(xMeters: -5.0, yMeters: 10.0, geometry: geometry)
        #expect(geometry.zone(at: p) == CourtZone(sector: .leftBack, depth: .far))
    }

    @Test("A centre back at 11m straight out is center/far")
    func centreBackAtElevenMetersIsCenterFar() {
        let p = point(xMeters: 0.0, yMeters: 11.0, geometry: geometry)
        #expect(geometry.zone(at: p) == CourtZone(sector: .center, depth: .far))
    }

    @Test("The degenerate goal-centre tap (0,0) resolves to center/near")
    func goalCentreTapResolvesToCenterNear() {
        let p = point(xMeters: 0.0, yMeters: 0.0, geometry: geometry)
        #expect(geometry.zone(at: p) == CourtZone(sector: .center, depth: .near))
    }
}

@Suite("CourtGeometry seven meter point")
struct CourtGeometrySevenMeterPointTests {

    let geometry = CourtGeometry.standard

    @Test("sevenMeterPoint lies on the centre line and derives to center/near")
    func sevenMeterPointLiesOnCentreLine() {
        let p = geometry.sevenMeterPoint
        #expect(tolerant(p.x, 0.5))
        #expect(geometry.zone(at: p) == CourtZone(sector: .center, depth: .near))
    }
}
