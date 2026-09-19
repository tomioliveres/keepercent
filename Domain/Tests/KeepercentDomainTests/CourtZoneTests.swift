import Testing
@testable import KeepercentDomain

@Suite("CourtZone")
struct CourtZoneTests {

    @Test("5 sectors x 2 depths yields exactly 10 distinct zones")
    func gridYieldsTenDistinctZones() {
        let zones = CourtZone.allCases
        #expect(zones.count == 10)
        #expect(Set(zones).count == 10)
    }

    @Test("Every sector/depth combination is present exactly once")
    func everyCombinationIsPresent() {
        for sector in CourtSector.allCases {
            for depth in CourtDepth.allCases {
                let zone = CourtZone(sector: sector, depth: depth)
                #expect(CourtZone.allCases.contains(zone))
            }
        }
    }
}

@Suite("ShotOrigin")
struct ShotOriginTests {

    @Test("10 zones plus the 7m mark yields exactly 11 distinct origins")
    func allCasesHasElevenDistinctOrigins() {
        let origins = ShotOrigin.allCases
        #expect(origins.count == 11)
        #expect(Set(origins).count == 11)
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
