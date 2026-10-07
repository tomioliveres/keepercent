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

@Suite("CourtGeometryTests independent canvas oracle")
struct CourtGeometryTestsCanvasOracle {
    private struct Bounds {
        let minX: Double
        let minY: Double
        let width: Double
        let height: Double
        var maxX: Double { minX + width }
        var maxY: Double { minY + height }

        init(x: Double, y: Double, width: Double, height: Double) {
            minX = x
            minY = y
            self.width = width
            self.height = height
        }
    }

    // Solve (r sin(theta) - 1.5)^2 + (r cos(theta))^2 = d^2
    // independently of CourtGeometry's radius/clipping implementation.
    private func intersection(_ distance: Double, _ degrees: Double) -> (x: Double, y: Double) {
        let theta = degrees * .pi / 180
        let r = 1.5 * sin(theta) + sqrt(distance * distance - 2.25 * pow(cos(theta), 2))
        return (x: r * sin(theta), y: r * cos(theta))
    }

    private var expected: [(CourtZone, Bounds)] {
        let i18 = intersection(6, 18), i54 = intersection(6, 54)
        let o18 = intersection(9, 18), o54 = intersection(9, 54)
        let wing = Bounds(x: 0, y: 0, width: 0.5 - i54.x / 20, height: o54.y / 15)
        let back = Bounds(x: 0.5 - o54.x / 20, y: i54.y / 15,
                          width: (o54.x - i18.x) / 20, height: (o18.y - i54.y) / 15)
        let center = Bounds(x: 0.5 - o18.x / 20, y: i18.y / 15,
                            width: o18.x / 10, height: (9 - i18.y) / 15)
        let farBack = Bounds(x: 0, y: 0, width: 0.5 - o18.x / 20, height: 1)
        let farHalf = 15 * tan(Double.pi / 10) / 20
        let farCenter = Bounds(x: 0.5 - farHalf, y: o18.y / 15,
                               width: 2 * farHalf, height: 1 - o18.y / 15)
        func mirror(_ rect: Bounds) -> Bounds {
            Bounds(x: 1 - rect.maxX, y: rect.minY, width: rect.width, height: rect.height)
        }
        return [
            (CourtZone(sector: .leftWing, depth: .near), wing),
            (CourtZone(sector: .leftBack, depth: .near), back),
            (CourtZone(sector: .center, depth: .near), center),
            (CourtZone(sector: .rightBack, depth: .near), mirror(back)),
            (CourtZone(sector: .rightWing, depth: .near), mirror(wing)),
            (CourtZone(sector: .leftBack, depth: .far), farBack),
            (CourtZone(sector: .center, depth: .far), farCenter),
            (CourtZone(sector: .rightBack, depth: .far), mirror(farBack))
        ]
    }

    @Test("All eight actual polygon extrema match independent analytic bounds")
    func analyticExtrema() throws {
        #expect(expected.count == 8)
        for (zone, rect) in expected {
            let vertices = CourtGeometry.standard.shape(for: zone)
            let minX = try #require(vertices.map(\.x).min())
            let minY = try #require(vertices.map(\.y).min())
            let maxX = try #require(vertices.map(\.x).max())
            let maxY = try #require(vertices.map(\.y).max())
            #expect(tolerant(minX, rect.minX), "\(zone) minX")
            #expect(tolerant(minY, rect.minY), "\(zone) minY")
            #expect(tolerant(maxX, rect.maxX), "\(zone) maxX")
            #expect(tolerant(maxY, rect.maxY), "\(zone) maxY")
        }
    }

    @Test("Wing maximum is the inner 54-degree vertex; far backs retain collapsed goal-line ends")
    func criticalVertices() {
        let inner = intersection(6, 54)
        for (sector, sign) in [(CourtSector.leftWing, -1.0), (.rightWing, 1.0)] {
            let vertices = CourtGeometry.standard.shape(for: CourtZone(sector: sector, depth: .near))
            #expect(vertices.contains { tolerant($0.x, 0.5 + sign * inner.x / 20) && tolerant($0.y, inner.y / 15) })
        }
        for (sector, x) in [(CourtSector.leftBack, 0.0), (.rightBack, 1.0)] {
            let vertices = CourtGeometry.standard.shape(for: CourtZone(sector: sector, depth: .far))
            #expect(vertices.contains { tolerant($0.x, x) && tolerant($0.y, 0) })
        }
        #expect(0.5 - inner.x / 20 > 0.125)
    }

    @Test("Raw canvas bounds tolerate pixel snapping without small-mark scale amplification",
          arguments: [250.5, 338.0, 371.3333333333333, 516.0])
    func screenRounding(width: Double) {
        let canvas = Bounds(x: 32, y: 536.5, width: width, height: width * 0.75)
        for (_, rect) in expected {
            let raw = Bounds(x: canvas.minX + rect.minX * width,
                             y: canvas.minY + rect.minY * canvas.height,
                             width: rect.width * width, height: rect.height * canvas.height)
            for scale in [2.0, 3.0] {
                // Both nearest-edge and outward-edge snapping stay within the
                // exact one-point UI tolerance, even for fractional canvases.
                for outward in [false, true] {
                    let loX = (outward ? floor(raw.minX * scale) : (raw.minX * scale).rounded()) / scale
                    let hiX = (outward ? ceil(raw.maxX * scale) : (raw.maxX * scale).rounded()) / scale
                    let loY = (outward ? floor(raw.minY * scale) : (raw.minY * scale).rounded()) / scale
                    let hiY = (outward ? ceil(raw.maxY * scale) : (raw.maxY * scale).rounded()) / scale
                    #expect(abs(loX - raw.minX) <= 1 && abs(loY - raw.minY) <= 1)
                    #expect(abs(hiX - loX - raw.width) <= 1)
                    #expect(abs(hiY - loY - raw.height) <= 1)
                }
            }
            #expect(abs((0.5 - intersection(6, 54).x / 20 - 0.125) * width) > 1)
        }
        // Retained iPhone values: 338-point canvas, rounded 23 1/3-point mark.
        let inferredWidth = (70.0 / 3) * 20 / 1.4
        #expect(tolerant(inferredWidth, 333.3333333333333))
        #expect(abs(inferredWidth - 338) > 4)
        let markError = abs(338.0 * 1.4 / 20 - 70.0 / 3)
        #expect(markError < 1)
        #expect(abs((inferredWidth - 338) * 0.3) > 1) // Shooter x-offset drift.
    }

    @Test("Retained iPhone-light fractional region frames agree with the complete corrected oracle")
    func retainedFractionalFrames() {
        // f01c236 attachment C8F57E34-335F-4248-8CC9-4D779E78361C,
        // lines 1–9 and 86: 338-point full-width control; outer edges x=32,
        // y=535. This reconstructed fixture is offline consistency evidence,
        // NOT a replacement for fresh native canvas telemetry at runtime.
        let frames: [Bounds] = [
            Bounds(x: 32, y: 535, width: 71 + 1.0 / 3, height: 101),
            Bounds(x: 62, y: 606, width: 106, height: 79 + 1.0 / 3),
            Bounds(x: 152 + 1.0 / 3, y: 636, width: 97 + 1.0 / 3, height: 51),
            Bounds(x: 234, y: 606, width: 106, height: 79 + 1.0 / 3),
            Bounds(x: 298 + 2.0 / 3, y: 535, width: 71 + 1.0 / 3, height: 101),
            Bounds(x: 32, y: 535, width: 120 + 1.0 / 3, height: 253 + 1.0 / 3),
            Bounds(x: 118 + 2.0 / 3, y: 685 + 1.0 / 3, width: 164 + 2.0 / 3, height: 103),
            Bounds(x: 249 + 2.0 / 3, y: 535, width: 120 + 1.0 / 3, height: 253 + 1.0 / 3),
            Bounds(x: 189 + 1.0 / 3, y: 644 + 2.0 / 3, width: 70.0 / 3, height: 17)
        ]
        let normalized = expected.map { $0.1 } + [Bounds(x: 0.465, y: 6.5 / 15, width: 0.07, height: 1.0 / 15)]
        #expect(frames.count == normalized.count)
        for (actual, rect) in zip(frames, normalized) {
            #expect(abs(actual.minX - (32 + rect.minX * 338)) <= 1)
            #expect(abs(actual.minY - (535 + rect.minY * 253.5)) <= 1)
            #expect(abs(actual.width - rect.width * 338) <= 1)
            #expect(abs(actual.height - rect.height * 253.5) <= 1)
            #expect(actual.minX >= 31 && actual.maxX <= 371)
            #expect(actual.minY >= 534 && actual.maxY <= 789.5)
        }
    }

    @Test("Every physical scaffold origin and the shared shooter far point has independent interior proof")
    func physicalTargetContract() {
        let targets: [(String, Double, Double)] = [
            ("zone.leftWing.near", 0.075, 0.15), ("zone.leftBack.near", 0.25, 0.4),
            ("zone.center.near", 0.5, 0.55), ("zone.rightBack.near", 0.75, 0.4),
            ("zone.rightWing.near", 0.925, 0.15), ("zone.leftBack.far", 0.2, 0.8),
            ("zone.center.far", 0.5, 0.8), ("zone.rightBack.far", 0.8, 0.8),
            ("sevenMeters", 0.5, 7.0 / 15)
        ]
        for (code, x, y) in targets {
            let target = CourtPoint(x: x, y: y)
            #expect(CourtGeometry.standard.origin(at: target)?.code == code)
            if let (zone, bounds) = expected.first(where: { "zone.\($0.0.code)" == code }) {
                #expect(x > bounds.minX && x < bounds.maxX && y > bounds.minY && y < bounds.maxY)
                #expect(isPointInPolygon(target, CourtGeometry.standard.shape(for: zone)))
            }
        }
        let wing = expected[0].1
        let automaticWingCenter = CourtPoint(x: wing.minX + wing.width / 2, y: wing.minY + wing.height / 2)
        #expect(CourtGeometry.standard.origin(at: automaticWingCenter)?.code == "zone.leftWing.near")
        let angle = atan2(6.0, 12.0) * 180 / .pi
        #expect(angle > 18 && angle < 54)
        #expect(hypot(6 - 1.5, 12) > 9)
    }
}

@Suite("CourtGeometryTests native activation point contract")
struct CourtGeometryTestsActivationContract {
    private let geometry = CourtGeometry.standard

    private func strictlyInside(_ point: CourtPoint, polygon: [CourtPoint]) -> Bool {
        guard isPointInPolygon(point, polygon) else { return false }
        for index in polygon.indices {
            let a = polygon[index], b = polygon[(index + 1) % polygon.count]
            let dx = b.x - a.x, dy = b.y - a.y
            let lengthSquared = dx * dx + dy * dy
            let t = lengthSquared > 0
                ? min(1, max(0, ((point.x - a.x) * dx + (point.y - a.y) * dy) / lengthSquared)) : 0
            // Reject edges and repeated/collapsed vertices independently of
            // ray casting and the analytic origin classifier.
            if hypot(point.x - (a.x + t * dx), point.y - (a.y + t * dy)) <= 1e-9 { return false }
        }
        return true
    }

    @Test("All eight accepted callback points are strict polygon interiors with stable local activation coordinates",
          arguments: CourtZone.allCases)
    func acceptedActivationPoint(zone: CourtZone) throws {
        let polygon = geometry.shape(for: zone)
        let point = try #require(geometry.representativePoint(for: zone))
        #expect(point.x.isFinite && point.y.isFinite)
        #expect(geometry.origin(at: point) == .zone(zone)) // Excludes the 7 m override.
        #expect(strictlyInside(point, polygon: polygon))
        let minX = try #require(polygon.map(\.x).min()), maxX = try #require(polygon.map(\.x).max())
        let minY = try #require(polygon.map(\.y).min()), maxY = try #require(polygon.map(\.y).max())
        try #require(maxX > minX && maxY > minY)
        let localX = (point.x - minX) / (maxX - minX)
        let localY = (point.y - minY) / (maxY - minY)
        #expect(localX.isFinite && localY.isFinite)
        #expect(localX > 0 && localX < 1 && localY > 0 && localY < 1)
        // Normalized extrema avoid division by transient zero layout sizes.
        // Reconstruct through actual screen bounds at multiple canvas scales.
        for width in [250.5, 338.0, 516.0] {
            let height = width / geometry.aspectRatio
            let screenX = 32 + minX * width + localX * (maxX - minX) * width
            let screenY = 535 + minY * height + localY * (maxY - minY) * height
            #expect(tolerant(screenX, 32 + point.x * width))
            #expect(tolerant(screenY, 535 + point.y * height))
        }
    }

    @Test("Overlapping far bounds do not make wing points far; center activation avoids the seven-meter action")
    func overlappingBoundsAndMark() throws {
        for (wing, back) in [(CourtSector.leftWing, CourtSector.leftBack), (.rightWing, .rightBack)] {
            let point = try #require(geometry.representativePoint(for: CourtZone(sector: wing, depth: .near)))
            let farPolygon = geometry.shape(for: CourtZone(sector: back, depth: .far))
            let minX = try #require(farPolygon.map(\.x).min()), maxX = try #require(farPolygon.map(\.x).max())
            let minY = try #require(farPolygon.map(\.y).min()), maxY = try #require(farPolygon.map(\.y).max())
            #expect(point.x > minX && point.x < maxX)
            #expect(point.y > minY && point.y < maxY)
            #expect(!isPointInPolygon(point, farPolygon))
        }
        let center = CourtZone(sector: .center, depth: .near)
        let point = try #require(geometry.representativePoint(for: center))
        #expect(geometry.origin(at: point) == .zone(center))
        #expect(geometry.origin(at: geometry.sevenMeterPoint) == .sevenMeters)
        #expect(isPointInPolygon(geometry.sevenMeterPoint, geometry.shape(for: center)))
        #expect(!strictlyInside(geometry.shape(for: center)[0], polygon: geometry.shape(for: center)))
    }
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

    @Test("Inside the 6m goal area has no depth, zone or shot origin, including the goal centre")
    func goalAreaCannotBeAShotOrigin() {
        for p in [point(xMeters: 0, yMeters: 0), point(xMeters: 0, yMeters: 5.9), point(xMeters: 2, yMeters: 5)] {
            #expect(geometry.depth(at: p) == nil)
            #expect(geometry.zone(at: p) == nil)
            #expect(geometry.origin(at: p) == nil)
        }
    }

    @Test("The curved 6m boundary belongs to near, but a point just inside it is rejected")
    func sixMeterBoundaryIsPlayable() {
        for x in [0.0, 1.5, -4.5, 4.5] {
            let y = abs(x) <= 1.5 ? 6.0 : (36 - pow(abs(x) - 1.5, 2)).squareRoot()
            let onLine = point(xMeters: x, yMeters: y)
            let inside = point(xMeters: x, yMeters: y - 0.01)
            #expect(geometry.depth(at: onLine) == .near)
            #expect(geometry.origin(at: onLine) != nil)
            #expect(geometry.origin(at: inside) == nil)
        }
    }

    @Test("The drawn 6m line follows the exact validity boundary")
    func sixMeterLineIsPlayable() {
        for p in geometry.line(atDistanceInMeters: geometry.sixMeterLine) {
            #expect(geometry.origin(at: p) != nil)
        }
    }

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
            (xMeters: -10.0, yMeters: 7.0, zone: CourtZone(sector: .leftBack, depth: .far)),
            (xMeters: -5.0, yMeters: 8.0, zone: CourtZone(sector: .leftBack, depth: .near)),
            (xMeters: -6.0, yMeters: 10.0, zone: CourtZone(sector: .leftBack, depth: .far)),
            (xMeters: 0.0, yMeters: 6.0, zone: CourtZone(sector: .center, depth: .near)),
            (xMeters: 0.0, yMeters: 11.0, zone: CourtZone(sector: .center, depth: .far)),
            (xMeters: 5.0, yMeters: 8.0, zone: CourtZone(sector: .rightBack, depth: .near)),
            (xMeters: 6.0, yMeters: 10.0, zone: CourtZone(sector: .rightBack, depth: .far)),
            (xMeters: 8.0, yMeters: 3.0, zone: CourtZone(sector: .rightWing, depth: .near)),
            (xMeters: 10.0, yMeters: 7.0, zone: CourtZone(sector: .rightBack, depth: .far))
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

    @Test("Drawable cuts start at 6m; outer cuts stop at 9m while center cuts reach the edge")
    func playableRaysExcludeTheGoalArea() {
        let rays = geometry.playableSectorBoundaryRays
        #expect(rays.count == geometry.sectorBoundaryRays.count)
        for (playable, full) in zip(rays, geometry.sectorBoundaryRays) {
            #expect(tolerant(geometry.distanceToGoalMouth(for: playable.from), geometry.sixMeterLine))
            #expect(geometry.zone(at: playable.from) != nil)
            if abs(geometry.angleDegrees(for: full.to)) > 50 {
                #expect(tolerant(geometry.distanceToGoalMouth(for: playable.to), geometry.nineMeterLine))
            } else {
                #expect(playable.to == full.to)
            }
            let halfway = CourtPoint(x: (playable.from.x + playable.to.x) / 2, y: (playable.from.y + playable.to.y) / 2)
            #expect(geometry.zone(at: halfway) != nil)
        }
    }

    @Test("Far strips and adjacent bands resolve to the same three origins, while near touchlines remain wings")
    func mergedFarOriginsKeepNearBoundary() {
        let left = CourtZone(sector: .leftBack, depth: .far)
        let right = CourtZone(sector: .rightBack, depth: .far)
        for (x, band, expected) in [(-10.0, -6.0, left), (10.0, 6.0, right)] {
            #expect(geometry.origin(at: point(xMeters: x, yMeters: 7)) == .zone(expected))
            #expect(geometry.origin(at: point(xMeters: band, yMeters: 10)) == .zone(expected))
            let nearTouchline = point(xMeters: x, yMeters: 2)
            #expect(geometry.depth(at: nearTouchline) == .near)
            #expect(geometry.origin(at: nearTouchline) == .zone(CourtZone(sector: x < 0 ? .leftWing : .rightWing, depth: .near)))
        }
        #expect(geometry.origin(at: point(xMeters: 0, yMeters: 11)) == .zone(CourtZone(sector: .center, depth: .far)))
        #expect(geometry.origin(at: geometry.sevenMeterPoint) == .sevenMeters)
    }

    @Test("Touchline near/far follows the curved 9m goal-mouth boundary, not its y-coordinate or angle")
    func touchlineNineMeterBoundary() {
        let x = geometry.widthInMeters / 2
        let y = (pow(geometry.nineMeterLine, 2) - pow(x - geometry.goalWidthInMeters / 2, 2)).squareRoot()
        for sign in [-1.0, 1.0] {
            let side = sign < 0 ? CourtSector.leftWing : .rightWing
            let farSide = sign < 0 ? CourtSector.leftBack : .rightBack
            #expect(geometry.zone(at: point(xMeters: sign * x, yMeters: y - 0.01)) == CourtZone(sector: side, depth: .near))
            #expect(geometry.zone(at: point(xMeters: sign * x, yMeters: y + 0.01)) == CourtZone(sector: farSide, depth: .far))
        }
    }

    @Test("The far side polygon includes both strip and band without an interior wing boundary")
    func mergedFarSidePolygon() {
        for (x, band, sector) in [(-10.0, -6.0, CourtSector.leftBack), (10.0, 6.0, CourtSector.rightBack)] {
            let polygon = geometry.shape(for: CourtZone(sector: sector, depth: .far))
            #expect(isPointInPolygon(point(xMeters: x + (x < 0 ? 0.05 : -0.05), yMeters: 7), polygon))
            #expect(isPointInPolygon(point(xMeters: band, yMeters: 10), polygon))
            #expect(!isPointInPolygon(point(xMeters: x + (x < 0 ? 0.05 : -0.05), yMeters: 2), polygon))
        }
    }

    @Test("Both touchline strips outside the 6m area remain selectable near zones")
    func touchlineStripsAreNearZones() {
        for x in [-9.5, 9.5] {
            let p = point(xMeters: x, yMeters: 1)
            let zone = CourtZone(sector: x < 0 ? .leftWing : .rightWing, depth: .near)
            #expect(geometry.origin(at: p) == .zone(zone))
            #expect(isPointInPolygon(p, geometry.shape(for: zone)))
        }
        #expect(geometry.origin(at: point(xMeters: 0, yMeters: 1)) == nil)
    }

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

/// True when `point` sits within tolerance of the curved 9 m near/far line,
/// whose post-centred quarter arcs a polygon can only ever chord. A round-trip
/// or tiling assertion skips a point here because the polygon's edge carries
/// the unavoidable sagitta
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
    abs(geometry.distanceToGoalMouth(for: point) - geometry.nineMeterLine) <= boundaryToleranceMeters
}

private func isNearTheSixMeterCurve(_ point: CourtPoint, geometry: CourtGeometry) -> Bool {
    // The new inner polygon edge is chorded too; use the same bounded
    // sagitta allowance, never a blanket tolerance for the goal area.
    abs(geometry.distanceToGoalMouth(for: point) - geometry.sixMeterLine) <= boundaryToleranceMeters
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
            // of either curved line can legitimately fall on the wrong side
            // of its polygon chord; straight edges have no allowance.
            guard !isNearTheNineMeterCurve(point, geometry: geometry), !isNearTheSixMeterCurve(point, geometry: geometry) else { continue }
            #expect(geometry.zone(at: point) == zone, "\(point) inside \(zone)'s polygon resolved to \(geometry.zone(at: point))")
        }
        #expect(sampledAtLeastOnePoint, "no sampled point landed inside \(zone)'s polygon — it may be empty or malformed")
    }

    @Test("The eight zone polygons tile the playable court, but none covers the goal area")
    func zonePolygonsCoverThePlayableCourt() {
        let geometry = CourtGeometry.standard
        let shapes = Dictionary(uniqueKeysWithValues: CourtZone.allCases.map { ($0, geometry.shape(for: $0)) })
        for point in denseGridPoints() {
            guard let zone = geometry.zone(at: point) else {
                guard !isNearTheSixMeterCurve(point, geometry: geometry) else { continue }
                #expect(shapes.values.allSatisfy { !isPointInPolygon(point, $0) }, "goal area point is highlighted")
                continue
            }
            guard let polygon = shapes[zone] else {
                Issue.record("no polygon recorded for \(zone)")
                continue
            }
            guard !isNearTheNineMeterCurve(point, geometry: geometry), !isNearTheSixMeterCurve(point, geometry: geometry) else { continue }
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
            guard let zone = geometry.zone(at: point) else {
                guard !isNearTheSixMeterCurve(point, geometry: geometry) else { continue }
                #expect(shapes.values.allSatisfy { !isPointInPolygon(point, $0) }, "goal area point is highlighted on \(geometry)")
                continue
            }
            guard let polygon = shapes[zone] else {
                Issue.record("no polygon recorded for \(zone)")
                continue
            }
            guard !isNearTheNineMeterCurve(point, geometry: geometry), !isNearTheSixMeterCurve(point, geometry: geometry) else { continue }
            #expect(isPointInPolygon(point, polygon), "\(point) classified as \(zone) but falls outside its own polygon on \(geometry)")
        }
    }

    @Test("shape(for:) never cuts a hole for the 7 m mark: a point inside the mark's hit area still belongs to its ordinary zone's polygon")
    func shapeDoesNotExcludeTheSevenMeterMark() throws {
        let geometry = CourtGeometry.standard
        let point = geometry.sevenMeterPoint
        let zone = geometry.zone(at: point)
        #expect(zone == CourtZone(sector: .center, depth: .near))
        let polygon = geometry.shape(for: try #require(zone))
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
            let boundaryVertices = polygon.filter { tolerant(geometry.distanceToGoalMouth(for: $0), geometry.nineMeterLine, tolerance: 1e-6) }
            #expect(!boundaryVertices.isEmpty, "\(zone)'s polygon has no vertex on the 9 m line")
            for vertex in boundaryVertices {
                let distance = geometry.distanceToGoalMouth(for: vertex)
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
    func courtCornerIsAnActualVertexOfItsOwnZonesPolygon() throws {
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
        let zone = try #require(geometry.zone(at: rightCorner))
        let polygon = geometry.shape(for: zone)
        #expect(
            polygon.contains { tolerant($0.x, rightCorner.x) && tolerant($0.y, rightCorner.y) },
            "\(zone)'s polygon has no vertex at the court corner \(rightCorner); vertices: \(polygon)"
        )

        let leftCorner = CourtPoint(x: 0, y: 1)
        let mirroredZone = try #require(geometry.zone(at: leftCorner))
        let mirroredPolygon = geometry.shape(for: mirroredZone)
        #expect(
            mirroredPolygon.contains { tolerant($0.x, leftCorner.x) && tolerant($0.y, leftCorner.y) },
            "\(mirroredZone)'s polygon has no vertex at the court corner \(leftCorner); vertices: \(mirroredPolygon)"
        )
    }
}
