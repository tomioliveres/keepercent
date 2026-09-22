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

/// Standard even-odd ray-casting point-in-polygon test, run in normalized
/// `CourtPoint` coordinates. Valid here even though `x` and `y` span
/// different real distances (20 m vs 15 m by default): ray casting only
/// ever compares coordinates against each other on the SAME axis, and
/// normalizing each axis independently (dividing by its own span) is a
/// monotonic per-axis rescaling, which preserves every such comparison.
/// The polygon is treated as implicitly closed (last point connects back
/// to the first), matching `CourtGeometry.shape(for:)`'s own documented
/// convention.
private func isPointInPolygon(_ point: CourtPoint, _ polygon: [CourtPoint]) -> Bool {
    guard polygon.count >= 3 else { return false }
    var inside = false
    var j = polygon.count - 1
    for i in 0..<polygon.count {
        let xi = polygon[i].x, yi = polygon[i].y
        let xj = polygon[j].x, yj = polygon[j].y
        if (yi > point.y) != (yj > point.y) {
            let xIntersect = xi + (point.y - yi) / (yj - yi) * (xj - xi)
            if point.x < xIntersect {
                inside.toggle()
            }
        }
        j = i
    }
    return inside
}

/// The distance, in metres, from a normalized `CourtPoint` to the goal mouth
/// segment — re-derived here (rather than calling the `internal`
/// `CourtGeometry.distanceToGoalMouth(for:)`, which this test target cannot
/// see even with `@testable import`, since it is `private`) using the exact
/// same formula documented on that function: clamp the metric x-offset onto
/// the goal mouth's own half-width, then take the hypotenuse.
private func distanceToGoalMouthMeters(_ point: CourtPoint, geometry: CourtGeometry) -> Double {
    let x = (point.x - 0.5) * geometry.widthInMeters
    let y = point.y * geometry.depthInMeters
    let halfGoal = geometry.goalWidthInMeters / 2
    let nearestX = min(max(x, -halfGoal), halfGoal)
    return hypot(x - nearestX, y)
}

/// Above the measured worst-case chord-vs-arc error (the "sagitta") that
/// `shape(for:)`'s polygon carries even after every real piecewise join is
/// forced to be an exact vertex, and an order of magnitude below the ~15 cm
/// gap a MISSING critical angle used to leave at the court's own corner
/// before that fix (see `CourtGeometry.swift`'s `radialArcPoints` and
/// `shape(for:)` comments for the fix itself).
///
/// Measured with a throwaway script: for the standard geometry and every
/// non-default fixture `shapeRoundTripsOnNonDefaultGeometry` uses, sweep
/// the same dense grid this file already samples, and for every point that
/// still fails the strict round-trip/tiling check, record its distance to
/// the 9 m curve. The worst observed value across all six fixtures was
/// ~0.36 mm (on the 30 m-wide, 8 m-deep fixture) - matching the analytic
/// sagitta of a circular arc of radius 9 m sampled every ~1 degree,
/// `r * (1 - cos(0.5 deg)) ~= 0.343 mm`, the one irreducible error
/// `radialArcPoints`'s header explains no polygon can remove (no polygon
/// equals an arc). 5 mm sits >10x above that measured 0.36 mm and >10x
/// below the ~15 cm structural gap.
private let boundaryToleranceMeters = 0.005

/// True when `point` sits within tolerance of the ONLY boundary of
/// `shape(for:)` that is genuinely curved: the 9 m near/far line, whose
/// post-centred quarter arcs a polygon can only ever chord. A round-trip
/// or tiling assertion skips a point here - never anywhere else - because
/// the polygon's edge there carries the unavoidable sagitta
/// `boundaryToleranceMeters` documents, not because the classification or
/// the polygon is wrong.
///
/// Deliberately no tolerance for the sector cuts or the court edges, even
/// though both are also polygon boundaries. Both are straight, and both
/// are sampled at their own exact angle, so the polygon's edge IS the
/// analytic boundary there and no sagitta exists to forgive. This was not
/// assumed: each clause was written, then removed after the whole suite
/// stayed green without it. A tolerance nothing needs is a tolerance that
/// only hides the next defect - the same reasoning that removed the dead
/// upper bound from `GoalGeometry.insideMouthY` in T2.1. Re-typing the 18
/// and 54 degree cuts here to build such a clause would also re-introduce
/// exactly the drift `centerBoundaryDegrees`/`backBoundaryDegrees` exist
/// to prevent, in the one file whose job is to catch that drift.
private func isNearTheNineMeterCurve(_ point: CourtPoint, geometry: CourtGeometry) -> Bool {
    abs(distanceToGoalMouthMeters(point, geometry: geometry) - geometry.nineMeterLine) <= boundaryToleranceMeters
}

@Suite("CourtGeometry shape(for: CourtZone)")
struct CourtGeometryShapeTests {

    /// A dense grid over the court, deliberately offset by an irrational
    /// fraction so it almost never lands exactly on a sector ray, the 9 m
    /// curve, or a court edge — the same class of boundary this file's
    /// other tests probe explicitly with hand-picked points, avoided here
    /// so a coverage/round-trip test over the WHOLE court does not trip on
    /// floating-point boundary noise instead of a real defect.
    private func denseGridPoints(columns: Int = 401, rows: Int = 307) -> [CourtPoint] {
        var points: [CourtPoint] = []
        for column in 0..<columns {
            for row in 0..<rows {
                let x = (Double(column) + 0.31) / Double(columns)
                let y = (Double(row) + 0.31) / Double(rows)
                points.append(CourtPoint(x: x, y: y))
            }
        }
        return points
    }

    @Test(
        "Every point strictly inside shape(for:) for a CourtZone resolves back to that same zone (round-trip)",
        arguments: CourtZone.allCases
    )
    func zoneShapeRoundTrips(zone: CourtZone) {
        let geometry = CourtGeometry.standard
        let polygon = geometry.shape(for: zone)
        var sampledAtLeastOnePoint = false
        for point in denseGridPoints() where isPointInPolygon(point, polygon) {
            sampledAtLeastOnePoint = true
            // A point strictly inside the polygon but within tolerance
            // of the 9 m curve can legitimately fall on the wrong side of
            // that curve - see `boundaryToleranceMeters` for why this is
            // the unavoidable sagitta, not a defect.
            guard !isNearTheNineMeterCurve(point, geometry: geometry) else { continue }
            #expect(geometry.zone(at: point) == zone, "\(point) inside \(zone)'s polygon resolved to \(geometry.zone(at: point))")
        }
        #expect(sampledAtLeastOnePoint, "no sampled point landed inside \(zone)'s polygon — it may be empty or malformed")
    }

    @Test("The 10 zone polygons tile the whole court: every sampled point's zone(at:) result contains that point in its own polygon")
    func zonePolygonsCoverTheCourt() {
        let geometry = CourtGeometry.standard
        let shapes = Dictionary(uniqueKeysWithValues: CourtZone.allCases.map { ($0, geometry.shape(for: $0)) })
        for point in denseGridPoints() {
            let zone = geometry.zone(at: point)
            guard let polygon = shapes[zone] else {
                Issue.record("no polygon recorded for \(zone)")
                continue
            }
            guard !isNearTheNineMeterCurve(point, geometry: geometry) else { continue }
            #expect(isPointInPolygon(point, polygon), "\(point) classified as \(zone) but falls outside its own polygon")
        }
    }

    @Test(
        "shape(for:) round-trips and tiles on a non-default geometry too",
        arguments: [
            CourtGeometry(widthInMeters: 16, depthInMeters: 10),
            CourtGeometry(widthInMeters: 30, depthInMeters: 8),
            CourtGeometry(widthInMeters: 12, depthInMeters: 22),
            CourtGeometry(widthInMeters: 20, depthInMeters: 15, goalWidthInMeters: 1.0, nineMeterLine: 6),
            // A deliberate degenerate probe: the 9 m line never occurs on a
            // 15 m deep court (`nineMeterLine` exceeds `depthInMeters`), so
            // every point is `.near` and every `.far` polygon legitimately
            // collapses to empty. No grid point is ever classified into a
            // `.far` zone here, so `shapes[zone]` for those zones is looked
            // up but never asked to contain a point — an empty polygon for
            // a zone nothing classifies into is fine, not a fixture to
            // soften away.
            CourtGeometry(widthInMeters: 20, depthInMeters: 15, nineMeterLine: 20)
        ]
    )
    func shapeRoundTripsOnNonDefaultGeometry(geometry: CourtGeometry) {
        let shapes = Dictionary(uniqueKeysWithValues: CourtZone.allCases.map { ($0, geometry.shape(for: $0)) })
        for point in denseGridPoints(columns: 137, rows: 101) {
            let zone = geometry.zone(at: point)
            guard let polygon = shapes[zone] else {
                Issue.record("no polygon recorded for \(zone)")
                continue
            }
            guard !isNearTheNineMeterCurve(point, geometry: geometry) else { continue }
            #expect(isPointInPolygon(point, polygon), "\(point) classified as \(zone) but falls outside its own polygon on \(geometry)")
        }
    }

    @Test("shape(for:) never cuts a hole for the 7 m mark: a point inside the mark's hit area still belongs to its ordinary zone's polygon")
    func shapeDoesNotExcludeTheSevenMeterMark() {
        let geometry = CourtGeometry.standard
        let point = geometry.sevenMeterPoint
        let zone = geometry.zone(at: point)
        #expect(zone == CourtZone(sector: .center, depth: .near))
        let polygon = geometry.shape(for: zone)
        #expect(isPointInPolygon(point, polygon))
    }

    @Test("Every returned polygon has at least 3 vertices")
    func everyPolygonHasAtLeastThreeVertices() {
        let geometry = CourtGeometry.standard
        for zone in CourtZone.allCases {
            #expect(geometry.shape(for: zone).count >= 3, "\(zone)'s polygon is degenerate")
        }
    }

    @Test("Every vertex of the center sector's near/far boundary sits at exactly nineMeterLine from the goal mouth")
    func nearFarBoundaryVerticesSitExactlyOnTheNineMeterLine() {
        let geometry = CourtGeometry.standard
        // The center sector never gets clamped to the court's own edge
        // before reaching the 9 m line on the standard geometry (straight
        // ahead, the far depth edge alone is 15 m away — well past 9 m),
        // so EVERY vertex of both its near/far boundary polygons must sit
        // exactly on `radiusAtGoalMouthDistance`'s solved radius, i.e.
        // exactly `distanceToGoalMouth == nineMeterLine` (up to float
        // epsilon, not the sagitta tolerance above — this is the exact
        // equation being solved, not a sampled curve).
        for zone in [CourtZone(sector: .center, depth: .near), CourtZone(sector: .center, depth: .far)] {
            let polygon = geometry.shape(for: zone)
            // Each polygon also carries one non-boundary point: `.near`'s
            // single goal-centre inner point (distance 0), `.far`'s
            // court-exit outer arc (distance > nineMeterLine). Both are
            // identified by NOT sitting near `nineMeterLine`, so filtering
            // to points that DO isolates exactly the shared boundary.
            let boundaryVertices = polygon.filter { tolerant(distanceToGoalMouthMeters($0, geometry: geometry), geometry.nineMeterLine, tolerance: 1e-6) }
            #expect(!boundaryVertices.isEmpty, "\(zone)'s polygon has no vertex on the 9 m line")
            for vertex in boundaryVertices {
                let distance = distanceToGoalMouthMeters(vertex, geometry: geometry)
                #expect(tolerant(distance, geometry.nineMeterLine), "\(vertex) at distance \(distance) is not exactly on the 9 m curve")
            }
        }
    }

    @Test("Every vertex of every zone's polygon lies on or inside the drawn court")
    func everyVertexLiesOnOrInsideTheDrawnCourt() {
        let geometry = CourtGeometry.standard
        for zone in CourtZone.allCases {
            for vertex in geometry.shape(for: zone) {
                #expect(vertex.x >= 0 && vertex.x <= 1, "\(vertex) in \(zone)'s polygon has x outside 0...1")
                #expect(vertex.y >= 0 && vertex.y <= 1, "\(vertex) in \(zone)'s polygon has y outside 0...1")
            }
        }
    }

    @Test("The court's own corner is an actual vertex of the polygon of the zone that owns it")
    func courtCornerIsAnActualVertexOfItsOwnZonesPolygon() {
        let geometry = CourtGeometry.standard
        // The right corner is exactly (1, 1) in normalized coordinates by
        // construction of `xMeters(for:)`/`yMeters(for:)` (x = 0.5 at the
        // goal centre, spanning to 1 at the right touchline; y = 0 at the
        // goal line, spanning to 1 at the far depth edge) — no internal
        // access needed to state it. Before the critical-angle fix, this
        // exact point was never a sample of `shape(for:)`'s polygon: it
        // fell between two ~1-degree samples, so the chord cut this corner
        // off by ~15 cm. It must now be an actual vertex.
        let rightCorner = CourtPoint(x: 1, y: 1)
        let zone = geometry.zone(at: rightCorner)
        let polygon = geometry.shape(for: zone)
        #expect(
            polygon.contains { tolerant($0.x, rightCorner.x) && tolerant($0.y, rightCorner.y) },
            "\(zone)'s polygon has no vertex at the court corner \(rightCorner); vertices: \(polygon)"
        )

        let leftCorner = CourtPoint(x: 0, y: 1)
        let mirroredZone = geometry.zone(at: leftCorner)
        let mirroredPolygon = geometry.shape(for: mirroredZone)
        #expect(
            mirroredPolygon.contains { tolerant($0.x, leftCorner.x) && tolerant($0.y, leftCorner.y) },
            "\(mirroredZone)'s polygon has no vertex at the court corner \(leftCorner); vertices: \(mirroredPolygon)"
        )
    }
}
