import Testing
@testable import KeepercentDomain

@Suite("CourtZone")
struct CourtZoneTests {

    @Test("Five near sectors and three far sectors yield eight selectable zones")
    func gridYieldsEightDistinctZones() {
        let zones = CourtZone.allCases
        #expect(zones.count == 8)
        #expect(Set(zones).count == 8)
    }

    @Test("Every near sector and only the three far bands are selectable")
    func everyCombinationIsPresent() {
        for sector in CourtSector.allCases {
            for depth in CourtDepth.allCases {
                let zone = CourtZone(sector: sector, depth: depth)
                #expect(CourtZone.allCases.contains(zone) == (depth == .near || (sector != .leftWing && sector != .rightWing)))
            }
        }
    }
}

@Suite("ShotOrigin")
struct ShotOriginTests {

    @Test("Eight zones plus the 7m mark yield nine distinct origins")
    func allCasesHasNineDistinctOrigins() {
        let origins = ShotOrigin.allCases
        #expect(origins.count == 9)
        #expect(Set(origins).count == 9)
    }
}

@Suite("CourtZone code round-trip")
struct CourtZoneCodeTests {

    @Test("Every CourtZone case round-trips losslessly through its code", arguments: CourtZone.allCases)
    func codeRoundTrips(zone: CourtZone) {
        let code = zone.code
        let decoded = CourtZone(code: code)
        #expect(decoded == zone)
    }

    @Test("Known code formats match the documented shape")
    func knownCodeFormats() {
        #expect(CourtZone(sector: .leftWing, depth: .near).code == "leftWing.near")
        #expect(CourtZone(sector: .center, depth: .far).code == "center.far")
    }

    @Test("Legacy far-wing codes still decode without losing their original code")
    func legacyFarWingCodes() {
        for side in ["leftWing", "rightWing"] {
            let code = "\(side).far"
            #expect(CourtZone(code: code)?.code == code)
            #expect(ShotOrigin(code: "zone.\(code)")?.code == "zone.\(code)")
        }
    }

    @Test(
        "Malformed or unknown codes return nil",
        arguments: [
            "",
            "bogus",
            "leftWing",
            "leftWing.near.extra",
            "unknown.near",
            "leftWing.unknown",
            "LEFTWING.NEAR",
            "leftWing..near",
            ".",
            ".."
        ]
    )
    func malformedCodesReturnNil(code: String) {
        #expect(CourtZone(code: code) == nil)
    }
}

@Suite("ShotOrigin code round-trip")
struct ShotOriginCodeTests {

    @Test("Every ShotOrigin case round-trips losslessly through its code", arguments: ShotOrigin.allCases)
    func codeRoundTrips(origin: ShotOrigin) {
        let code = origin.code
        let decoded = ShotOrigin(code: code)
        #expect(decoded == origin)
    }

    @Test("Known code formats match the documented shape")
    func knownCodeFormats() {
        #expect(ShotOrigin.zone(CourtZone(sector: .leftWing, depth: .near)).code == "zone.leftWing.near")
        #expect(ShotOrigin.zone(CourtZone(sector: .center, depth: .far)).code == "zone.center.far")
        #expect(ShotOrigin.sevenMeters.code == "sevenMeters")
    }

    @Test(
        "Malformed or unknown codes return nil",
        arguments: [
            "",
            "bogus",
            "zone",
            "zone.",
            "zone.center",
            "zone.leftWing.near.extra",
            "zone.unknown.near",
            "zone.leftWing.unknown",
            "ZONE.leftWing.near",
            "sevenMeters.extra",
            "SEVENMETERS",
            ".",
            ".."
        ]
    )
    func malformedCodesReturnNil(code: String) {
        #expect(ShotOrigin(code: code) == nil)
    }
}
