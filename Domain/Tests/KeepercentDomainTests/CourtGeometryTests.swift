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

@Suite("CourtGeometry aspect ratio")
struct CourtGeometryAspectRatioTests {

    @Test("aspectRatio is widthInMeters / depthInMeters, so x and y can share one drawing scale")
    func aspectRatioIsWidthOverDepth() {
        let geometry = CourtGeometry(widthInMeters: 20, depthInMeters: 15)
        #expect(tolerant(geometry.aspectRatio, 20.0 / 15.0))
    }

    @Test("A non-default geometry derives its own aspect ratio")
    func nonDefaultGeometryDerivesItsOwnRatio() {
        let geometry = CourtGeometry(widthInMeters: 16, depthInMeters: 20)
        #expect(tolerant(geometry.aspectRatio, 0.8))
    }
}

@Suite("CourtGeometry drawable distance line")
struct CourtGeometryLineTests {

    let geometry = CourtGeometry.standard

    @Test("Every point on the 9m line is at distance 9m from the goal mouth, matching depth(at:)'s own definition")
    func ninelineIsAtNineMetersFromGoalMouth() {
        let points = geometry.line(atDistanceInMeters: 9)
        #expect(!points.isEmpty)
        for point in points {
            #expect(tolerant(geometry.distanceToGoalMouth(for: point), 9, tolerance: 1e-6))
        }
    }

    @Test("Every point on the 6m line is at distance 6m from the goal mouth")
    func sixLineIsAtSixMetersFromGoalMouth() {
        let points = geometry.line(atDistanceInMeters: 6)
        #expect(!points.isEmpty)
        for point in points {
            #expect(tolerant(geometry.distanceToGoalMouth(for: point), 6, tolerance: 1e-6))
        }
    }

    @Test("The 9m line is a continuous polyline: no jump between consecutive points is larger than a small bound")
    func ninelineIsContinuous() {
        let points = geometry.line(atDistanceInMeters: 9)
        for i in 1..<points.count {
            let dx = geometry.xMeters(for: points[i]) - geometry.xMeters(for: points[i - 1])
            let dy = geometry.yMeters(for: points[i]) - geometry.yMeters(for: points[i - 1])
            let jump = (dx * dx + dy * dy).squareRoot()
            #expect(jump < 1.0)
        }
    }

    @Test("The 6m line is a continuous polyline")
    func sixLineIsContinuous() {
        let points = geometry.line(atDistanceInMeters: 6)
        for i in 1..<points.count {
            let dx = geometry.xMeters(for: points[i]) - geometry.xMeters(for: points[i - 1])
            let dy = geometry.yMeters(for: points[i]) - geometry.yMeters(for: points[i - 1])
            let jump = (dx * dx + dy * dy).squareRoot()
            #expect(jump < 1.0)
        }
    }

    @Test("The 9m line is symmetric: mirroring every point about the centre line yields the same point set")
    func ninelineIsSymmetric() {
        let points = geometry.line(atDistanceInMeters: 9)
        let mirroredXs = points.map { 1 - $0.x }.sorted()
        let originalXs = points.map(\.x).sorted()
        #expect(mirroredXs.count == originalXs.count)
        for (a, b) in zip(mirroredXs, originalXs) {
            #expect(tolerant(a, b, tolerance: 1e-6))
        }
    }

    @Test("A non-positive distance produces no line")
    func nonPositiveDistanceProducesNoLine() {
        #expect(geometry.line(atDistanceInMeters: 0).isEmpty)
        #expect(geometry.line(atDistanceInMeters: -1).isEmpty)
    }
}

@Suite("CourtGeometry sector boundary rays")
struct CourtGeometrySectorBoundaryRayTests {

    let geometry = CourtGeometry.standard

    @Test("Every ray starts at the goal centre")
    func everyRayStartsAtGoalCentre() {
        for ray in geometry.sectorBoundaryRays {
            #expect(tolerant(ray.from.x, 0.5))
            #expect(tolerant(ray.from.y, 0))
        }
    }

    @Test("There are exactly four rays, one per sector cut")
    func thereAreFourRays() {
        #expect(geometry.sectorBoundaryRays.count == 4)
    }

    @Test("Each ray's endpoint sits at the same angle sector(at:) uses as a boundary (18 or 54 degrees), so drawing and hit-testing share the same cut")
    func rayAnglesMatchSectorBoundaries() {
        let angles = geometry.sectorBoundaryRays.map { geometry.angleDegrees(for: $0.to) }.sorted()
        let expected = [-54.0, -18.0, 18.0, 54.0]
        #expect(angles.count == expected.count)
        for (a, e) in zip(angles, expected) {
            #expect(tolerant(a, e, tolerance: 1e-6))
        }
    }

    @Test("Each ray's endpoint leaves the drawn court exactly at its edge (a touchline or the far depth edge)")
    func rayEndpointsLeaveAtTheCourtEdge() {
        for ray in geometry.sectorBoundaryRays {
            let onTouchline = tolerant(ray.to.x, 0) || tolerant(ray.to.x, 1)
            let onFarEdge = tolerant(ray.to.y, 1)
            #expect(onTouchline || onFarEdge)
        }
    }

    @Test(
        "A point just on the central side of each ray's angle resolves to the more central sector, and just on the far side resolves to the neighbouring sector",
        arguments: [
            (rayAngle: 18.0, innerExpected: CourtSector.center, outerExpected: CourtSector.rightBack),
            (rayAngle: -18.0, innerExpected: CourtSector.center, outerExpected: CourtSector.leftBack),
            (rayAngle: 54.0, innerExpected: CourtSector.rightBack, outerExpected: CourtSector.rightWing),
            (rayAngle: -54.0, innerExpected: CourtSector.leftBack, outerExpected: CourtSector.leftWing)
        ]
    )
    func pointsJustInsideRayAngleResolveToExpectedSectorOnEachSide(input: (rayAngle: Double, innerExpected: CourtSector, outerExpected: CourtSector)) {
        // Derives the angle to probe from sectorBoundaryRays itself, rather
        // than the raw 18/54 literals, so this would catch the rays
        // drifting away from the constants sector(at:) actually uses.
        let ray = geometry.sectorBoundaryRays.first { tolerant(geometry.angleDegrees(for: $0.to), input.rayAngle, tolerance: 1e-6) }
        #expect(ray != nil)

        let inner = point(angleDegrees: input.rayAngle - (input.rayAngle < 0 ? -0.5 : 0.5), yMeters: 5, geometry: geometry)
        let outer = point(angleDegrees: input.rayAngle + (input.rayAngle < 0 ? -0.5 : 0.5), yMeters: 5, geometry: geometry)
        #expect(geometry.sector(at: inner) == input.innerExpected)
        #expect(geometry.sector(at: outer) == input.outerExpected)
    }
}

@Suite("CourtGeometry goal mouth")
struct CourtGeometryGoalMouthTests {

    let geometry = CourtGeometry.standard

    @Test("The goal mouth spans exactly the goal width, on the goal line")
    func goalMouthSpansGoalWidthOnGoalLine() {
        let mouth = geometry.goalMouth
        #expect(tolerant(geometry.xMeters(for: mouth.from), -geometry.goalWidthInMeters / 2))
        #expect(tolerant(geometry.xMeters(for: mouth.to), geometry.goalWidthInMeters / 2))
        #expect(tolerant(geometry.yMeters(for: mouth.from), 0))
        #expect(tolerant(geometry.yMeters(for: mouth.to), 0))
    }

    @Test("goalMouth.from is the shooter's left post, goalMouth.to is the shooter's right post")
    func goalMouthOrderingMatchesShooterPerspective() {
        let mouth = geometry.goalMouth
        #expect(mouth.from.x < mouth.to.x)
    }
}

@Suite("CourtGeometry seven meter mark hit area")
struct CourtGeometrySevenMeterHitAreaTests {

    let geometry = CourtGeometry.standard

    @Test("Defaults are 1.4m wide by 1.0m deep")
    func defaultsAreDocumented() {
        #expect(tolerant(geometry.sevenMeterMarkWidthInMeters, 1.4))
        #expect(tolerant(geometry.sevenMeterMarkDepthInMeters, 1.0))
    }

    @Test("The normalized region matches the metric rectangle centred on sevenMeterPoint")
    func normalizedRegionMatchesMetricRectangle() {
        let region = geometry.sevenMeterMarkRegion
        #expect(tolerant(region.x, 0.465))
        #expect(tolerant(region.width, 0.07))
        #expect(tolerant(region.y, 6.5 / 15.0))
        #expect(tolerant(region.height, 1.0 / 15.0))
    }

    @Test("sevenMeterPoint itself resolves to .sevenMeters")
    func sevenMeterPointResolvesToSevenMeters() {
        #expect(geometry.origin(at: geometry.sevenMeterPoint) == .sevenMeters)
    }

    @Test("The rectangle's boundary is inclusive: a point exactly on an edge is .sevenMeters")
    func boundaryIsInclusive() {
        let region = geometry.sevenMeterMarkRegion
        #expect(geometry.origin(at: CourtPoint(x: region.x, y: region.y)) == .sevenMeters)
        #expect(geometry.origin(at: CourtPoint(x: region.x + region.width, y: region.y + region.height)) == .sevenMeters)
        #expect(geometry.origin(at: CourtPoint(x: 0.5, y: region.y)) == .sevenMeters)
        #expect(geometry.origin(at: CourtPoint(x: 0.5, y: region.y + region.height)) == .sevenMeters)
    }

    @Test("Just outside the rectangle resolves to .zone(center, near), not .sevenMeters")
    func justOutsideResolvesToCenterNearZone() {
        let region = geometry.sevenMeterMarkRegion
        // All four sides: `origin(at:)` tests the left and right `x`
        // bounds with two structurally separate comparisons, so leaving
        // either one out leaves that edge of the hit area unproved.
        let justLeft = CourtPoint(x: region.x - 0.01, y: 0.5)
        let justRight = CourtPoint(x: region.x + region.width + 0.01, y: 0.5)
        let justAbove = CourtPoint(x: 0.5, y: region.y - 0.01)
        let justBelow = CourtPoint(x: 0.5, y: region.y + region.height + 0.01)
        #expect(geometry.origin(at: justLeft) == .zone(CourtZone(sector: .center, depth: .near)))
        #expect(geometry.origin(at: justRight) == .zone(CourtZone(sector: .center, depth: .near)))
        #expect(geometry.origin(at: justAbove) == .zone(CourtZone(sector: .center, depth: .near)))
        #expect(geometry.origin(at: justBelow) == .zone(CourtZone(sector: .center, depth: .near)))
    }

    @Test("Well outside the rectangle still resolves through zone(at:) normally")
    func wellOutsideResolvesNormally() {
        let p = point(xMeters: -8.0, yMeters: 3.0, geometry: geometry)
        #expect(geometry.origin(at: p) == .zone(CourtZone(sector: .leftWing, depth: .near)))
    }

    @Test("Custom dimensions are honored by both the region and origin(at:)")
    func customDimensionsAreHonored() {
        let custom = CourtGeometry(sevenMeterMarkWidthInMeters: 2.0, sevenMeterMarkDepthInMeters: 2.0)
        let region = custom.sevenMeterMarkRegion
        #expect(tolerant(region.width, 2.0 / custom.widthInMeters))
        #expect(tolerant(region.height, 2.0 / custom.depthInMeters))
        #expect(custom.origin(at: custom.sevenMeterPoint) == .sevenMeters)
    }
}
