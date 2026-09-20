import Testing
@testable import KeepercentDomain

@Suite("ShotClassification origin side")
struct ShotClassificationOriginSideTests {

    @Test(
        "Origin side follows sector: wings and backs take their side, centre is neutral",
        arguments: [
            (CourtSector.leftWing, ShotSide.left),
            (CourtSector.leftBack, ShotSide.left),
            (CourtSector.center, ShotSide.center),
            (CourtSector.rightBack, ShotSide.right),
            (CourtSector.rightWing, ShotSide.right)
        ]
    )
    func originSideFollowsSector(sector: CourtSector, expected: ShotSide) {
        for depth in CourtDepth.allCases {
            let origin = ShotOrigin.zone(CourtZone(sector: sector, depth: depth))
            #expect(ShotClassification.originSide(origin) == expected)
        }
    }

    @Test("A seven-metre throw has no lateral side")
    func sevenMetersHasNoSide() {
        #expect(ShotClassification.originSide(.sevenMeters) == nil)
    }
}

@Suite("ShotClassification target side")
struct ShotClassificationTargetSideTests {

    @Test("Inside target side follows its column", arguments: GoalZone.allCases)
    func insideSideFollowsColumn(zone: GoalZone) {
        let expected: ShotSide
        switch zone.column {
        case .left: expected = .left
        case .center: expected = .center
        case .right: expected = .right
        }
        #expect(ShotClassification.targetSide(.inside(zone)) == expected)
    }

    @Test(
        "Post segment side follows its post, and crossbar segments follow their own column",
        arguments: [
            (PostSegment.leftPostTop, ShotSide.left),
            (PostSegment.leftPostMiddle, ShotSide.left),
            (PostSegment.leftPostBottom, ShotSide.left),
            (PostSegment.crossbarLeft, ShotSide.left),
            (PostSegment.crossbarCenter, ShotSide.center),
            (PostSegment.crossbarRight, ShotSide.right),
            (PostSegment.rightPostTop, ShotSide.right),
            (PostSegment.rightPostMiddle, ShotSide.right),
            (PostSegment.rightPostBottom, ShotSide.right)
        ]
    )
    func postSideFollowsSegment(segment: PostSegment, expected: ShotSide) {
        #expect(ShotClassification.targetSide(.post(segment)) == expected)
    }

    @Test(
        "Out direction side follows the miss direction, and `over` is centre",
        arguments: [
            (MissDirection.wideLeft, ShotSide.left),
            (MissDirection.wideRight, ShotSide.right),
            (MissDirection.over, ShotSide.center)
        ]
    )
    func outSideFollowsDirection(direction: MissDirection, expected: ShotSide) {
        #expect(ShotClassification.targetSide(.out(direction)) == expected)
    }
}

@Suite("ShotClassification target height")
struct ShotClassificationTargetHeightTests {

    @Test("Inside target height follows its row", arguments: GoalZone.allCases)
    func insideHeightFollowsRow(zone: GoalZone) {
        let expected: ShotHeight
        switch zone.row {
        case .top: expected = .top
        case .middle: expected = .middle
        case .bottom: expected = .bottom
        }
        #expect(ShotClassification.targetHeight(.inside(zone)) == expected)
    }

    @Test(
        "Post segment height follows its own band, and crossbar segments are top",
        arguments: [
            (PostSegment.leftPostTop, ShotHeight.top),
            (PostSegment.leftPostMiddle, ShotHeight.middle),
            (PostSegment.leftPostBottom, ShotHeight.bottom),
            (PostSegment.crossbarLeft, ShotHeight.top),
            (PostSegment.crossbarCenter, ShotHeight.top),
            (PostSegment.crossbarRight, ShotHeight.top),
            (PostSegment.rightPostTop, ShotHeight.top),
            (PostSegment.rightPostMiddle, ShotHeight.middle),
            (PostSegment.rightPostBottom, ShotHeight.bottom)
        ]
    )
    func postHeightFollowsSegment(segment: PostSegment, expected: ShotHeight) {
        #expect(ShotClassification.targetHeight(.post(segment)) == expected)
    }

    @Test("Out targets never have a height, including `over`", arguments: MissDirection.allCases)
    func outHasNoHeight(direction: MissDirection) {
        #expect(ShotClassification.targetHeight(.out(direction)) == nil)
    }
}

@Suite("ShotClassification shot line")
struct ShotClassificationLineTests {

    private static let leftOrigin = ShotOrigin.zone(CourtZone(sector: .leftWing, depth: .near))
    private static let centerOrigin = ShotOrigin.zone(CourtZone(sector: .center, depth: .near))
    private static let rightOrigin = ShotOrigin.zone(CourtZone(sector: .rightWing, depth: .near))

    private static let leftTarget = GoalTarget.inside(GoalZone(row: .middle, column: .left))
    private static let centerTarget = GoalTarget.inside(GoalZone(row: .middle, column: .center))
    private static let rightTarget = GoalTarget.inside(GoalZone(row: .middle, column: .right))

    @Test(
        "The origin/target side matrix determines cross-shot, near-post, or neutral",
        arguments: [
            (leftOrigin, leftTarget, ShotLine.nearPost),
            (leftOrigin, centerTarget, ShotLine.neutral),
            (leftOrigin, rightTarget, ShotLine.crossShot),
            (centerOrigin, leftTarget, ShotLine.neutral),
            (centerOrigin, centerTarget, ShotLine.neutral),
            (centerOrigin, rightTarget, ShotLine.neutral),
            (rightOrigin, leftTarget, ShotLine.crossShot),
            (rightOrigin, centerTarget, ShotLine.neutral),
            (rightOrigin, rightTarget, ShotLine.nearPost),
            (ShotOrigin.sevenMeters, leftTarget, ShotLine.neutral),
            (ShotOrigin.sevenMeters, centerTarget, ShotLine.neutral),
            (ShotOrigin.sevenMeters, rightTarget, ShotLine.neutral)
        ]
    )
    func lineMatrix(origin: ShotOrigin, target: GoalTarget, expected: ShotLine) {
        #expect(ShotClassification.line(from: origin, to: target) == expected)
    }

    @Test("Line classification also integrates with post and out targets, via their derived side")
    func lineIntegratesWithPostAndOutTargets() {
        #expect(ShotClassification.line(from: Self.leftOrigin, to: .post(.rightPostTop)) == .crossShot)
        #expect(ShotClassification.line(from: Self.rightOrigin, to: .out(.wideRight)) == .nearPost)
        #expect(ShotClassification.line(from: Self.leftOrigin, to: .out(.over)) == .neutral)
    }
}

@Suite("ShotClassification supporting enums")
struct ShotClassificationSupportingEnumsTests {

    @Test("ShotSide has exactly 3 cases")
    func shotSideHasThreeCases() {
        #expect(ShotSide.allCases.count == 3)
    }

    @Test("ShotHeight has exactly 3 cases")
    func shotHeightHasThreeCases() {
        #expect(ShotHeight.allCases.count == 3)
    }

    @Test("ShotLine has exactly 3 cases")
    func shotLineHasThreeCases() {
        #expect(ShotLine.allCases.count == 3)
    }
}
