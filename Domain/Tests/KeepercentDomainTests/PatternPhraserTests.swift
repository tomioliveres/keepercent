import Foundation
import Testing
@testable import KeepercentDomain

@Suite("Pattern phraser")
struct PatternPhraserTests {
    private func sentence(
        _ kind: ScoutingPatternKind,
        _ successes: Int,
        _ attempts: Int,
        conversion: Tally? = nil,
        contrast: Tally? = nil
    ) -> String {
        PatternPhraser.sentence(for: ScoutingPattern(
            kind: kind,
            tally: Tally(successes: successes, attempts: attempts),
            conversion: conversion,
            contrast: contrast
        ), locale: Locale(identifier: "en"))
    }

    @Test("Line tendencies, overall and per sector and hand")
    func lines() {
        #expect(sentence(.line(.crossShot), 7, 10) == "Shoots cross-court 7 of 10")
        #expect(sentence(.line(.nearPost), 5, 6) == "Shoots near post 5 of 6")
        #expect(sentence(.lineFromSector(.crossShot, sector: .leftBack, hand: .left), 5, 6)
            == "Left-handed from left back: shoots cross-court 5 of 6")
        #expect(sentence(.lineFromSector(.nearPost, sector: .rightWing, hand: nil), 4, 5)
            == "From right wing: shoots near post 4 of 5")
    }

    @Test("Height and side tendencies")
    func heightAndSide() {
        #expect(sentence(.height(.bottom), 6, 9) == "Aims low 6 of 9")
        #expect(sentence(.height(.top), 3, 5) == "Aims high 3 of 5")
        #expect(sentence(.height(.middle), 3, 5) == "Aims mid-height 3 of 5")
        #expect(sentence(.side(.left), 4, 5) == "Aims left 4 of 5")
        #expect(sentence(.side(.center), 4, 5) == "Aims center 4 of 5")
    }

    @Test("Delivery tendencies add their conversion, singular and plural")
    func delivery() {
        #expect(sentence(.deliveryHeight(.standing, .bottom), 5, 6, conversion: Tally(successes: 3, attempts: 5))
            == "When standing, aims low 5 of 6 (3 goals)")
        #expect(sentence(.deliverySide(.jump, .right), 4, 5, conversion: Tally(successes: 1, attempts: 4))
            == "When jumping, aims right 4 of 5 (1 goal)")
    }

    @Test("Approach tendencies")
    func approach() {
        #expect(sentence(.approachSide(.fromLeft, .right), 4, 5) == "Coming from the left, aims right 4 of 5")
        #expect(sentence(.approachSide(.fromRight, .left), 4, 5) == "Coming from the right, aims left 4 of 5")
        #expect(sentence(.approachSide(.straight, .center), 4, 5) == "Coming straight, aims center 4 of 5")
    }

    @Test("7 m tendencies and the 7 m save record")
    func sevenMeters() {
        #expect(sentence(.sevenMeterSide(.right), 4, 5) == "7 m: aims right 4 of 5")
        #expect(sentence(.sevenMeterHeight(.top), 4, 5) == "7 m: aims high 4 of 5")
        #expect(sentence(.sevenMeterSaves, 2, 6) == "7 m: saves 2 of 6")
    }

    @Test("Origin, distance and repeat after scoring")
    func originDistanceRepeat() {
        #expect(sentence(.origin(CourtZone(sector: .leftBack, depth: .far)), 6, 10)
            == "Shoots from left back (far) 6 of 10")
        #expect(sentence(.distance, 5, 7, contrast: Tally(successes: 1, attempts: 6))
            == "Scores from near 5 of 7 vs far 1 of 6")
        #expect(sentence(.repeatAfterGoal, 3, 4) == "After scoring, repeats the same zone 3 of 4")
    }

    @Test("Goalkeeper weaknesses and the standing vs jump comparison")
    func goalkeeper() {
        #expect(sentence(.concededHeight(.bottom), 6, 8) == "Concedes low 6 of 8 goals")
        #expect(sentence(.concededSide(.right), 5, 7) == "Concedes right 5 of 7 goals")
        #expect(sentence(.deliverySaves, 5, 6, contrast: Tally(successes: 1, attempts: 5))
            == "Saves standing shots 5 of 6 vs jump shots 1 of 5")
    }
}
