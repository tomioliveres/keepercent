import Testing
@testable import KeepercentDomain

@Suite("GoalZone")
struct GoalZoneTests {

    @Test("The 3x3 grid yields exactly 9 distinct zones")
    func gridYieldsNineDistinctZones() {
        let zones = GoalZone.allCases
        #expect(zones.count == 9)
        #expect(Set(zones).count == 9)
    }

    @Test("Every row/column combination is present exactly once")
    func everyCombinationIsPresent() {
        for row in GoalRow.allCases {
            for column in GoalColumn.allCases {
                let zone = GoalZone(row: row, column: column)
                #expect(GoalZone.allCases.contains(zone))
            }
        }
    }
}

@Suite("GoalTarget code round-trip")
struct GoalTargetCodeTests {

    @Test("Every GoalTarget case round-trips losslessly through its code", arguments: GoalTarget.allCases)
    func codeRoundTrips(target: GoalTarget) {
        let code = target.code
        let decoded = GoalTarget(code: code)
        #expect(decoded == target)
    }

    @Test("Known code formats match the documented shape")
    func knownCodeFormats() {
        #expect(GoalTarget.inside(GoalZone(row: .top, column: .left)).code == "inside.top.left")
        #expect(GoalTarget.post(.crossbarCenter).code == "post.crossbarCenter")
        #expect(GoalTarget.out(.wideLeft, .top).code == "out.wideLeft.top")
        #expect(GoalTarget.out(.over, .center).code == "out.over.center")
    }

    @Test("A legacy miss with no recorded third keeps its two-part code", arguments: MissDirection.allCases)
    func legacyMissCodeRoundTrips(direction: MissDirection) {
        let legacy = GoalTarget.out(direction, nil)
        #expect(legacy.code == "out.\(direction.rawValue)")
        #expect(GoalTarget(code: "out.\(direction.rawValue)") == legacy)
    }

    @Test(
        "A third that does not belong to its miss direction is rejected",
        arguments: [
            "out.over.top",
            "out.over.middle",
            "out.over.bottom",
            "out.wideLeft.left",
            "out.wideLeft.center",
            "out.wideLeft.right",
            "out.wideRight.center"
        ]
    )
    func mismatchedMissThirdIsRejected(code: String) {
        #expect(GoalTarget(code: code) == nil)
    }

    @Test(
        "Malformed or unknown codes return nil",
        arguments: [
            "",
            "bogus",
            "inside",
            "inside.top",
            "inside.top.left.extra",
            "inside.unknown.left",
            "inside.top.unknown",
            "post",
            "post.unknown",
            "post.crossbarCenter.extra",
            "out",
            "out.unknown",
            "out.wideLeft.extra",
            "out.wideLeft.",
            "out.wideLeft.top.extra",
            "INSIDE.TOP.LEFT",
            "inside..left",
            "."
        ]
    )
    func malformedCodesReturnNil(code: String) {
        #expect(GoalTarget(code: code) == nil)
    }
}

@Suite("GoalTarget implied outcome")
struct GoalTargetImpliedOutcomeTests {

    @Test("Inside targets never imply an outcome", arguments: GoalZone.allCases)
    func insideImpliesNil(zone: GoalZone) {
        #expect(GoalTarget.inside(zone).impliedOutcome == nil)
    }

    @Test("Post targets always imply .post", arguments: PostSegment.allCases)
    func postImpliesPost(segment: PostSegment) {
        #expect(GoalTarget.post(segment).impliedOutcome == .post)
    }

    @Test("Out targets always imply .out, with or without a recorded third", arguments: MissDirection.allCases)
    func outImpliesOut(direction: MissDirection) {
        let parts: [MissPart?] = [nil] + direction.parts
        for part in parts {
            #expect(GoalTarget.out(direction, part).impliedOutcome == .out)
        }
    }
}

@Suite("Supporting enums")
struct SupportingEnumsTests {

    @Test("PostSegment has exactly 9 cases")
    func postSegmentHasNineCases() {
        #expect(PostSegment.allCases.count == 9)
    }

    @Test("MissDirection has exactly 3 cases")
    func missDirectionHasThreeCases() {
        #expect(MissDirection.allCases.count == 3)
    }

    @Test("Wide misses split by height, over splits by width")
    func missDirectionParts() {
        #expect(MissDirection.wideLeft.parts == [.top, .middle, .bottom])
        #expect(MissDirection.wideRight.parts == [.top, .middle, .bottom])
        #expect(MissDirection.over.parts == [.left, .center, .right])
    }

    @Test("Every target list names the nine concrete out zones and no legacy miss")
    func allCasesListsNineConcreteOutZones() {
        let misses = GoalTarget.allCases.filter { $0.impliedOutcome == .out }
        #expect(misses.count == 9)
        #expect(Set(misses).count == 9)
        #expect(!misses.contains { if case .out(_, nil) = $0 { true } else { false } })
    }

    @Test("ShotOutcome has exactly 4 cases")
    func shotOutcomeHasFourCases() {
        #expect(ShotOutcome.allCases.count == 4)
    }
}
