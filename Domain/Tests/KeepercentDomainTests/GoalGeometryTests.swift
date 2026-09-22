import Foundation
import Testing
@testable import KeepercentDomain

private func tolerant(_ a: Double, _ b: Double, tolerance: Double = 1e-9) -> Bool {
    abs(a - b) < tolerance
}

@Suite("GoalPoint construction")
struct GoalPointConstructionTests {

    @Test("Out-of-range values are kept untouched — unlike CourtPoint, a GoalPoint is never clamped")
    func outOfRangeValuesAreNotClamped() {
        let p = GoalPoint(x: -0.4, y: -0.3)
        #expect(tolerant(p.x, -0.4))
        #expect(tolerant(p.y, -0.3))

        let far = GoalPoint(x: 3.2, y: 5.7)
        #expect(tolerant(far.x, 3.2))
        #expect(tolerant(far.y, 5.7))
    }

    @Test("In-range values are kept untouched")
    func inRangeValuesAreUntouched() {
        let p = GoalPoint(x: 0.25, y: 0.75)
        #expect(tolerant(p.x, 0.25))
        #expect(tolerant(p.y, 0.75))
    }

    @Test("A NaN coordinate resolves to the documented midpoint 0.5, same defensible value as CourtPoint")
    func nanResolvesToMidpoint() {
        let p = GoalPoint(x: .nan, y: .nan)
        #expect(tolerant(p.x, 0.5))
        #expect(tolerant(p.y, 0.5))
        #expect(p.x.isFinite)
        #expect(p.y.isFinite)
    }
}

@Suite("GoalGeometry defaults")
struct GoalGeometryDefaultsTests {

    @Test("standard uses the handball goal mouth dimensions and a finger-sized frame band")
    func standardDefaults() {
        let geometry = GoalGeometry.standard
        #expect(tolerant(geometry.widthInMeters, 3))
        #expect(tolerant(geometry.heightInMeters, 2))
        #expect(tolerant(geometry.frameBandInMeters, 0.25))
    }

    @Test("Normalized frame band thickness is derived from frameBandInMeters and the mouth dimensions")
    func normalizedThicknessIsDerived() {
        let geometry = GoalGeometry(widthInMeters: 4, heightInMeters: 2, frameBandInMeters: 0.5)
        #expect(tolerant(geometry.normalizedFrameBandThicknessX, 0.125))
        #expect(tolerant(geometry.normalizedFrameBandThicknessY, 0.25))
    }
}

@Suite("GoalGeometry inside-the-mouth zones")
struct GoalGeometryInsideZoneTests {

    let geometry = GoalGeometry.standard

    @Test(
        "Every GoalZone is reachable from a representative point",
        arguments: [
            (x: 0.1, y: 0.1, zone: GoalZone(row: .top, column: .left)),
            (x: 0.5, y: 0.1, zone: GoalZone(row: .top, column: .center)),
            (x: 0.9, y: 0.1, zone: GoalZone(row: .top, column: .right)),
            (x: 0.1, y: 0.5, zone: GoalZone(row: .middle, column: .left)),
            (x: 0.5, y: 0.5, zone: GoalZone(row: .middle, column: .center)),
            (x: 0.9, y: 0.5, zone: GoalZone(row: .middle, column: .right)),
            (x: 0.1, y: 0.9, zone: GoalZone(row: .bottom, column: .left)),
            (x: 0.5, y: 0.9, zone: GoalZone(row: .bottom, column: .center)),
            (x: 0.9, y: 0.9, zone: GoalZone(row: .bottom, column: .right))
        ]
    )
    func everyZoneIsReachable(input: (x: Double, y: Double, zone: GoalZone)) {
        let target = geometry.target(at: GoalPoint(x: input.x, y: input.y))
        #expect(target == .inside(input.zone))
    }

    @Test("Exactly on a column boundary (1/3, 2/3) belongs to the center column (tie-break to the more central)")
    func columnBoundaryBelongsToCenter() {
        #expect(geometry.target(at: GoalPoint(x: 1.0 / 3.0, y: 0.5)) == .inside(GoalZone(row: .middle, column: .center)))
        #expect(geometry.target(at: GoalPoint(x: 2.0 / 3.0, y: 0.5)) == .inside(GoalZone(row: .middle, column: .center)))
    }

    @Test("Exactly on a row boundary (1/3, 2/3) belongs to the middle row (tie-break to the more central)")
    func rowBoundaryBelongsToMiddle() {
        #expect(geometry.target(at: GoalPoint(x: 0.5, y: 1.0 / 3.0)) == .inside(GoalZone(row: .middle, column: .center)))
        #expect(geometry.target(at: GoalPoint(x: 0.5, y: 2.0 / 3.0)) == .inside(GoalZone(row: .middle, column: .center)))
    }

    @Test("Just past a boundary lands in the outer bucket")
    func justPastBoundaryLandsOutside() {
        #expect(geometry.target(at: GoalPoint(x: 0.3, y: 0.5)) == .inside(GoalZone(row: .middle, column: .left)))
        #expect(geometry.target(at: GoalPoint(x: 0.7, y: 0.5)) == .inside(GoalZone(row: .middle, column: .right)))
        #expect(geometry.target(at: GoalPoint(x: 0.5, y: 0.3)) == .inside(GoalZone(row: .top, column: .center)))
        #expect(geometry.target(at: GoalPoint(x: 0.5, y: 0.7)) == .inside(GoalZone(row: .bottom, column: .center)))
    }
}

@Suite("GoalGeometry frame band — posts and crossbar")
struct GoalGeometryFrameBandTests {

    let geometry = GoalGeometry.standard

    @Test("A tap just left of the mouth, mid-height, is the left post middle segment")
    func justLeftOfMouthIsLeftPostMiddle() {
        let x = -geometry.normalizedFrameBandThicknessX / 2
        #expect(geometry.target(at: GoalPoint(x: x, y: 0.5)) == .post(.leftPostMiddle))
    }

    @Test("A tap just right of the mouth, mid-height, is the right post middle segment")
    func justRightOfMouthIsRightPostMiddle() {
        let x = 1 + geometry.normalizedFrameBandThicknessX / 2
        #expect(geometry.target(at: GoalPoint(x: x, y: 0.5)) == .post(.rightPostMiddle))
    }

    @Test("The left post band splits into top/middle/bottom by thirds of the mouth height")
    func leftPostBandSplitsByThirds() {
        let x = -geometry.normalizedFrameBandThicknessX / 2
        #expect(geometry.target(at: GoalPoint(x: x, y: 0.1)) == .post(.leftPostTop))
        #expect(geometry.target(at: GoalPoint(x: x, y: 0.5)) == .post(.leftPostMiddle))
        #expect(geometry.target(at: GoalPoint(x: x, y: 0.9)) == .post(.leftPostBottom))
    }

    @Test("The right post band splits into top/middle/bottom by thirds of the mouth height")
    func rightPostBandSplitsByThirds() {
        let x = 1 + geometry.normalizedFrameBandThicknessX / 2
        #expect(geometry.target(at: GoalPoint(x: x, y: 0.1)) == .post(.rightPostTop))
        #expect(geometry.target(at: GoalPoint(x: x, y: 0.5)) == .post(.rightPostMiddle))
        #expect(geometry.target(at: GoalPoint(x: x, y: 0.9)) == .post(.rightPostBottom))
    }

    @Test("A tap just above the mouth, centered, is the crossbar center segment")
    func justAboveMouthIsCrossbarCenter() {
        let y = -geometry.normalizedFrameBandThicknessY / 2
        #expect(geometry.target(at: GoalPoint(x: 0.5, y: y)) == .post(.crossbarCenter))
    }

    @Test("The crossbar band splits into left/center/right by thirds of the mouth width")
    func crossbarBandSplitsByThirds() {
        let y = -geometry.normalizedFrameBandThicknessY / 2
        #expect(geometry.target(at: GoalPoint(x: 0.1, y: y)) == .post(.crossbarLeft))
        #expect(geometry.target(at: GoalPoint(x: 0.5, y: y)) == .post(.crossbarCenter))
        #expect(geometry.target(at: GoalPoint(x: 0.9, y: y)) == .post(.crossbarRight))
    }
}

@Suite("GoalGeometry corner rule")
struct GoalGeometryCornerRuleTests {

    let geometry = GoalGeometry.standard

    @Test("Above the crossbar AND left of the left post (within both bands) belongs to the post, not the crossbar")
    func topLeftCornerBelongsToPost() {
        let x = -geometry.normalizedFrameBandThicknessX / 2
        let y = -geometry.normalizedFrameBandThicknessY / 2
        #expect(geometry.target(at: GoalPoint(x: x, y: y)) == .post(.leftPostTop))
    }

    @Test("Above the crossbar AND right of the right post (within both bands) belongs to the post, not the crossbar")
    func topRightCornerBelongsToPost() {
        let x = 1 + geometry.normalizedFrameBandThicknessX / 2
        let y = -geometry.normalizedFrameBandThicknessY / 2
        #expect(geometry.target(at: GoalPoint(x: x, y: y)) == .post(.rightPostTop))
    }

    @Test("Below the ground line at the left post band resolves to the bottom post segment, not off the frame")
    func bottomOfLeftPostBandResolvesToBottom() {
        let x = -geometry.normalizedFrameBandThicknessX / 2
        #expect(geometry.target(at: GoalPoint(x: x, y: 1.4)) == .post(.leftPostBottom))
    }

    @Test("Below the ground line at the right post band resolves to the bottom post segment, not off the frame")
    func bottomOfRightPostBandResolvesToBottom() {
        let x = 1 + geometry.normalizedFrameBandThicknessX / 2
        #expect(geometry.target(at: GoalPoint(x: x, y: 1.4)) == .post(.rightPostBottom))
    }

    // These two pin the post band's own top bound (`-normalizedFrameBandThicknessY`,
    // the same edge `region(for:)` draws to) from both sides. Without an
    // upper y bound on the post band, a tap that is only a hair left/right
    // of a post but far above the frame would still hit-test as that
    // post's top segment even though `region(for:)` never draws that far
    // up — drawing and hit-testing would disagree. This is exactly the
    // regression these tests exist to catch.

    @Test("Just above the top of the left post band (still band-width in x) is a miss, not the post")
    func justAboveLeftPostBandTopIsWideLeft() {
        let x = -geometry.normalizedFrameBandThicknessX / 2
        let y = -geometry.normalizedFrameBandThicknessY - 0.01
        #expect(geometry.target(at: GoalPoint(x: x, y: y)) == .out(.wideLeft))
    }

    @Test("Just above the top of the right post band (still band-width in x) is a miss, not the post")
    func justAboveRightPostBandTopIsWideRight() {
        let x = 1 + geometry.normalizedFrameBandThicknessX / 2
        let y = -geometry.normalizedFrameBandThicknessY - 0.01
        #expect(geometry.target(at: GoalPoint(x: x, y: y)) == .out(.wideRight))
    }

    @Test("Just below that same bound, still inside the corner square, is still the left post top segment")
    func justBelowLeftPostBandTopIsStillPost() {
        let x = -geometry.normalizedFrameBandThicknessX / 2
        let y = -geometry.normalizedFrameBandThicknessY + 0.01
        #expect(geometry.target(at: GoalPoint(x: x, y: y)) == .post(.leftPostTop))
    }

    @Test("Just below that same bound, still inside the corner square, is still the right post top segment")
    func justBelowRightPostBandTopIsStillPost() {
        let x = 1 + geometry.normalizedFrameBandThicknessX / 2
        let y = -geometry.normalizedFrameBandThicknessY + 0.01
        #expect(geometry.target(at: GoalPoint(x: x, y: y)) == .post(.rightPostTop))
    }
}

@Suite("GoalGeometry misses")
struct GoalGeometryMissTests {

    let geometry = GoalGeometry.standard

    @Test("Beyond the post band on the left is wideLeft")
    func beyondLeftPostBandIsWideLeft() {
        let x = -geometry.normalizedFrameBandThicknessX * 2
        #expect(geometry.target(at: GoalPoint(x: x, y: 0.5)) == .out(.wideLeft))
    }

    @Test("Beyond the post band on the right is wideRight")
    func beyondRightPostBandIsWideRight() {
        let x = 1 + geometry.normalizedFrameBandThicknessX * 2
        #expect(geometry.target(at: GoalPoint(x: x, y: 0.5)) == .out(.wideRight))
    }

    @Test("Above the crossbar band, within the mouth's horizontal extent, is over")
    func aboveCrossbarBandWithinMouthIsOver() {
        let y = -geometry.normalizedFrameBandThicknessY * 2
        #expect(geometry.target(at: GoalPoint(x: 0.5, y: y)) == .out(.over))
    }

    @Test(
        "A tap both high AND wide (beyond the post band in x, above the crossbar band in y) resolves to wideLeft/wideRight, never over",
        arguments: [
            (x: -1.0, expected: MissDirection.wideLeft),
            (x: 2.0, expected: MissDirection.wideRight)
        ]
    )
    func highAndWideResolvesToWide(input: (x: Double, expected: MissDirection)) {
        let y = -geometry.normalizedFrameBandThicknessY * 5
        #expect(geometry.target(at: GoalPoint(x: input.x, y: y)) == .out(input.expected))
    }
}

@Suite("GoalGeometry below the ground line")
struct GoalGeometryBelowGroundTests {

    let geometry = GoalGeometry.standard

    @Test("A y beyond the ground line, inside the mouth's x extent, resolves as if it were on the ground line")
    func belowGroundInsideMouthResolvesToBottomRow() {
        #expect(geometry.target(at: GoalPoint(x: 0.1, y: 3.0)) == .inside(GoalZone(row: .bottom, column: .left)))
        #expect(geometry.target(at: GoalPoint(x: 0.5, y: 3.0)) == .inside(GoalZone(row: .bottom, column: .center)))
        #expect(geometry.target(at: GoalPoint(x: 0.9, y: 3.0)) == .inside(GoalZone(row: .bottom, column: .right)))
    }
}

@Suite("GoalGeometry region round-trip")
struct GoalGeometryRegionRoundTripTests {

    let geometry = GoalGeometry.standard

    /// Points just inside each of a region's four edges (left/right/top/bottom
    /// midpoints, inset perpendicular to that edge), not just its center.
    ///
    /// The center-only round-trip test previously in this suite missed the
    /// unbounded-post-band regression precisely because it never looked at
    /// the space near a region's edges — only its middle, which is nowhere
    /// near where drawing and hit-testing could disagree. Insetting from
    /// each edge, rather than testing the edge coordinate itself, keeps
    /// every point unambiguously inside the region under test: none of
    /// these nine zones or nine segments share a boundary LINE with a
    /// same-type neighbour that an inset point could land on both sides
    /// of — the thirds tie-break (`thirdIndex`) always assigns a shared
    /// boundary to one specific side, and insetting away from it never
    /// crosses back over. The inset is capped at a quarter of the
    /// region's own width/height so it can never escape the region even
    /// for the narrowest one (the post bands, `normalizedFrameBandThicknessX`
    /// wide), while staying many orders of magnitude larger than
    /// `boundaryTolerance`.
    private func edgeInsetPoints(in region: GoalRegion) -> [GoalPoint] {
        let insetX = min(0.01, region.width / 4)
        let insetY = min(0.01, region.height / 4)
        let midX = region.x + region.width / 2
        let midY = region.y + region.height / 2
        return [
            GoalPoint(x: region.x + insetX, y: midY),                        // left edge
            GoalPoint(x: region.x + region.width - insetX, y: midY),         // right edge
            GoalPoint(x: midX, y: region.y + insetY),                        // top edge
            GoalPoint(x: midX, y: region.y + region.height - insetY)         // bottom edge
        ]
    }

    @Test(
        "The center AND every edge-inset point of region(for:) for every GoalZone resolve back to that same zone",
        arguments: GoalZone.allCases
    )
    func zoneRegionRoundTrips(zone: GoalZone) {
        let region = geometry.region(for: zone)
        let center = GoalPoint(x: region.x + region.width / 2, y: region.y + region.height / 2)
        #expect(geometry.target(at: center) == .inside(zone))

        for point in edgeInsetPoints(in: region) {
            #expect(geometry.target(at: point) == .inside(zone))
        }
    }

    @Test(
        "The center AND every edge-inset point of region(for:) for every PostSegment resolve back to that same segment",
        arguments: PostSegment.allCases
    )
    func postSegmentRegionRoundTrips(segment: PostSegment) {
        let region = geometry.region(for: segment)
        let center = GoalPoint(x: region.x + region.width / 2, y: region.y + region.height / 2)
        #expect(geometry.target(at: center) == .post(segment))

        for point in edgeInsetPoints(in: region) {
            #expect(geometry.target(at: point) == .post(segment))
        }
    }

    @Test("Zone regions tile the mouth exactly: widths and heights sum to 1")
    func zoneRegionsTileTheMouth() {
        let leftWidth = geometry.region(for: GoalZone(row: .top, column: .left)).width
        let centerWidth = geometry.region(for: GoalZone(row: .top, column: .center)).width
        let rightWidth = geometry.region(for: GoalZone(row: .top, column: .right)).width
        #expect(tolerant(leftWidth + centerWidth + rightWidth, 1))

        let topHeight = geometry.region(for: GoalZone(row: .top, column: .left)).height
        let middleHeight = geometry.region(for: GoalZone(row: .middle, column: .left)).height
        let bottomHeight = geometry.region(for: GoalZone(row: .bottom, column: .left)).height
        #expect(tolerant(topHeight + middleHeight + bottomHeight, 1))
    }

    @Test("Post band regions sit just outside the mouth, with the band's normalized thickness")
    func postRegionsSitOutsideMouth() {
        let leftMiddle = geometry.region(for: .leftPostMiddle)
        #expect(tolerant(leftMiddle.x, -geometry.normalizedFrameBandThicknessX))
        #expect(tolerant(leftMiddle.width, geometry.normalizedFrameBandThicknessX))

        let rightMiddle = geometry.region(for: .rightPostMiddle)
        #expect(tolerant(rightMiddle.x, 1))
        #expect(tolerant(rightMiddle.width, geometry.normalizedFrameBandThicknessX))

        let crossbarCenter = geometry.region(for: .crossbarCenter)
        #expect(tolerant(crossbarCenter.y, -geometry.normalizedFrameBandThicknessY))
        #expect(tolerant(crossbarCenter.height, geometry.normalizedFrameBandThicknessY))
    }
}

@Suite("GoalGeometry target(at:) on a non-default geometry")
struct GoalGeometryNonDefaultGeometryTests {

    // A 4x2 mouth with a 0.5 m frame band — deliberately not `.standard`,
    // so these tests catch a regression that only shows up once `target(at:)`
    // is exercised on band thicknesses other than the default ones
    // (normalizedFrameBandThicknessX = 0.125, normalizedFrameBandThicknessY = 0.25).
    let geometry = GoalGeometry(widthInMeters: 4, heightInMeters: 2, frameBandInMeters: 0.5)

    @Test("A point inside the mouth resolves to the expected zone")
    func insideMouthResolvesToExpectedZone() {
        #expect(geometry.target(at: GoalPoint(x: 0.5, y: 0.5)) == .inside(GoalZone(row: .middle, column: .center)))
    }

    @Test("A point in the left post band resolves to the expected post segment")
    func leftPostBandResolvesToExpectedSegment() {
        let x = -geometry.normalizedFrameBandThicknessX / 2
        #expect(geometry.target(at: GoalPoint(x: x, y: 0.5)) == .post(.leftPostMiddle))
    }

    @Test("A point beyond the left post band resolves to wideLeft")
    func beyondLeftPostBandResolvesToWideLeft() {
        let x = -geometry.normalizedFrameBandThicknessX * 2
        #expect(geometry.target(at: GoalPoint(x: x, y: 0.5)) == .out(.wideLeft))
    }

    @Test("A point above the crossbar band, inside the mouth, resolves to over")
    func aboveCrossbarBandResolvesToOver() {
        let y = -geometry.normalizedFrameBandThicknessY * 2
        #expect(geometry.target(at: GoalPoint(x: 0.5, y: y)) == .out(.over))
    }

    // `GoalPoint` deliberately does not clamp, so a `y` below the ground
    // line reaches `target(at:)` unchanged and the resolution onto the
    // floor happens inside it. The two tests below pin that BEHAVIOUR —
    // the ball cannot pass under the floor — rather than whichever
    // internal step currently upholds it, so the guarantee survives a
    // refactor of the clamping itself.

    @Test("A point below the ground line, inside the mouth, resolves onto the floor")
    func belowGroundLineInsideMouthResolvesToBottomRow() {
        #expect(geometry.target(at: GoalPoint(x: 0.5, y: 1.5)) == .inside(GoalZone(row: .bottom, column: .center)))
    }

    @Test("A point below the ground line, in a post band, resolves to that post's bottom segment")
    func belowGroundLineInPostBandResolvesToBottomSegment() {
        let x = -geometry.normalizedFrameBandThicknessX / 2
        #expect(geometry.target(at: GoalPoint(x: x, y: 1.5)) == .post(.leftPostBottom))
    }
}

@Suite("GoalGeometry regions(for: MissDirection, within:) — bounded tiling")
struct GoalGeometryMissDirectionRegionsTests {

    let geometry = GoalGeometry.standard

    /// A drawable bounds standing in for whatever finite area a caller
    /// (the view) actually draws into — generous enough to reach well past
    /// the frame band on every side, the way `GoalView`'s own canvas does.
    private func generousBounds(for geometry: GoalGeometry, margin: Double = 0.5) -> GoalRegion {
        let bandX = geometry.normalizedFrameBandThicknessX
        let bandY = geometry.normalizedFrameBandThicknessY
        return GoalRegion(
            x: -(bandX + margin),
            y: -(bandY + margin),
            width: 1 + 2 * (bandX + margin),
            height: 1 + bandY + margin
        )
    }

    /// A dense grid over `bounds`, offset by an irrational fraction so it
    /// almost never lands exactly on a boundary — the same technique
    /// `CourtGeometryShapeTests.denseGridPoints` uses for `shape(for:)`.
    private func denseGridPoints(in bounds: GoalRegion, columns: Int = 231, rows: Int = 197) -> [GoalPoint] {
        var points: [GoalPoint] = []
        for column in 0..<columns {
            for row in 0..<rows {
                let x = bounds.x + bounds.width * (Double(column) + 0.31) / Double(columns)
                let y = bounds.y + bounds.height * (Double(row) + 0.31) / Double(rows)
                points.append(GoalPoint(x: x, y: y))
            }
        }
        return points
    }

    /// Half-open containment ([x, x+width) x [y, y+height)), matching how
    /// the returned rects are meant to tile without overlapping at a
    /// shared edge.
    private func isPointInRegion(_ point: GoalPoint, _ region: GoalRegion) -> Bool {
        point.x >= region.x && point.x < region.x + region.width &&
        point.y >= region.y && point.y < region.y + region.height
    }

    @Test(
        "Every point inside a regions(for:within:) rect resolves through target(at:) back to that same direction (round-trip)",
        arguments: MissDirection.allCases
    )
    func directionRegionsRoundTrip(direction: MissDirection) {
        let bounds = generousBounds(for: geometry)
        let rects = geometry.regions(for: direction, within: bounds)
        #expect(!rects.isEmpty, "\(direction) returned no rects for a generous bounds")

        for rect in rects {
            var sampledAtLeastOnePoint = false
            for point in denseGridPoints(in: bounds) where isPointInRegion(point, rect) {
                sampledAtLeastOnePoint = true
                #expect(
                    geometry.target(at: point) == .out(direction),
                    "\(point) inside \(direction)'s rect \(rect) resolved to \(geometry.target(at: point))"
                )
            }
            #expect(sampledAtLeastOnePoint, "no sampled point landed inside \(direction)'s rect \(rect) — bounds/grid too coarse")
        }
    }

    @Test(
        "Every point in bounds that target(at:) resolves to a miss lands inside exactly one rect of that direction's set — no gap, no overlap"
    )
    func missPointsTileExactlyOneRect() {
        let bounds = generousBounds(for: geometry)
        let rectsByDirection = Dictionary(
            uniqueKeysWithValues: MissDirection.allCases.map { ($0, geometry.regions(for: $0, within: bounds)) }
        )

        for point in denseGridPoints(in: bounds) {
            guard case .out(let direction) = geometry.target(at: point) else { continue }

            // The gap half is the regression test for the original defect:
            // a miss point that landed in NONE of its own direction's
            // rects, left undrawn in the plain gray margin while still
            // hit-testing as that miss.
            let ownMatches = (rectsByDirection[direction] ?? []).filter { isPointInRegion(point, $0) }
            #expect(ownMatches.count == 1, "\(point), resolved to \(direction), landed in \(ownMatches.count) of its own rects (expected exactly 1)")

            // The overlap half: the same point must never also land inside
            // a DIFFERENT direction's rect.
            for otherDirection in MissDirection.allCases where otherDirection != direction {
                let otherMatches = (rectsByDirection[otherDirection] ?? []).filter { isPointInRegion(point, $0) }
                #expect(otherMatches.isEmpty, "\(point), resolved to \(direction), also landed inside \(otherDirection)'s rect \(otherMatches)")
            }
        }
    }

    @Test("regions(for:within:) round-trips and tiles on a non-default geometry too")
    func regionsTileOnNonDefaultGeometry() {
        let custom = GoalGeometry(widthInMeters: 4, heightInMeters: 2, frameBandInMeters: 0.5)
        let bounds = generousBounds(for: custom)
        let rectsByDirection = Dictionary(
            uniqueKeysWithValues: MissDirection.allCases.map { ($0, custom.regions(for: $0, within: bounds)) }
        )

        for point in denseGridPoints(in: bounds, columns: 151, rows: 127) {
            guard case .out(let direction) = custom.target(at: point) else { continue }
            let ownMatches = (rectsByDirection[direction] ?? []).filter { isPointInRegion(point, $0) }
            #expect(ownMatches.count == 1, "\(point), resolved to \(direction), landed in \(ownMatches.count) rects on a non-default geometry")
        }
    }

    @Test("A bounds that never reaches past the frame band returns no rects for any direction — not an invented fallback rect")
    func degenerateBoundsReturnsNoRects() {
        // Bounds exactly the mouth plus the frame band itself, no margin
        // beyond it: there is no drawable miss area left to tile.
        let bandX = geometry.normalizedFrameBandThicknessX
        let bandY = geometry.normalizedFrameBandThicknessY
        let tightBounds = GoalRegion(x: -bandX, y: -bandY, width: 1 + 2 * bandX, height: 1 + bandY)

        #expect(geometry.regions(for: .wideLeft, within: tightBounds).isEmpty)
        #expect(geometry.regions(for: .wideRight, within: tightBounds).isEmpty)
        #expect(geometry.regions(for: .over, within: tightBounds).isEmpty)
    }

    @Test("A bounds a hair past the frame band still returns the documented rect count — two per wide side, one for over")
    func slightlyPastFrameBandReturnsExpectedRectCount() {
        let bounds = generousBounds(for: geometry, margin: 0.05)
        #expect(geometry.regions(for: .wideLeft, within: bounds).count == 2)
        #expect(geometry.regions(for: .wideRight, within: bounds).count == 2)
        #expect(geometry.regions(for: .over, within: bounds).count == 1)
    }
}

@Suite("GoalGeometry regions(for: GoalTarget, within:) dispatcher")
struct GoalGeometryTargetDispatcherTests {

    let geometry = GoalGeometry.standard
    // An arbitrary generous bounds; only that it reaches well past the
    // frame band on every side matters for these tests.
    let bounds = GoalRegion(x: -0.6, y: -0.6, width: 2.2, height: 1.6)

    @Test("Dispatching on .inside matches region(for: GoalZone), as a single-element list")
    func dispatchesInsideToZoneRegion() {
        let zone = GoalZone(row: .top, column: .left)
        #expect(geometry.regions(for: GoalTarget.inside(zone), within: bounds) == [geometry.region(for: zone)])
    }

    @Test("Dispatching on .post matches region(for: PostSegment), as a single-element list")
    func dispatchesPostToSegmentRegion() {
        #expect(geometry.regions(for: GoalTarget.post(.crossbarCenter), within: bounds) == [geometry.region(for: PostSegment.crossbarCenter)])
    }

    @Test("Dispatching on .out matches regions(for: MissDirection, within:)")
    func dispatchesOutToDirectionRegions() {
        #expect(
            geometry.regions(for: GoalTarget.out(.wideLeft), within: bounds)
                == geometry.regions(for: MissDirection.wideLeft, within: bounds)
        )
    }
}
