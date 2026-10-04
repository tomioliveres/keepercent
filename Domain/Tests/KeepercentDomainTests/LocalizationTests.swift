import Foundation
import Testing
@testable import KeepercentDomain

/// English is the development language; Spanish ships as Spain (`es`) and a
/// Latin American variant (`es-419`) that only differs in vocabulary. Each
/// test pins its locale, so the result never depends on the machine running
/// the suite.
@Suite("Spanish phrasing, Spain and Latin America")
struct LocalizationTests {
    private let spain = Locale(identifier: "es_ES")
    private let latinAmerica = Locale(identifier: "es_AR")

    private func pattern(_ kind: ScoutingPatternKind, _ successes: Int, _ attempts: Int,
                         conversion: Tally? = nil, contrast: Tally? = nil) -> ScoutingPattern {
        ScoutingPattern(kind: kind, tally: Tally(successes: successes, attempts: attempts),
                        conversion: conversion, contrast: contrast)
    }

    @Test("Pattern sentences use each variant's vocabulary")
    func patternSentences() {
        let crossCourt = pattern(.lineFromSector(.crossShot, sector: .leftBack, hand: .left), 5, 6)
        #expect(PatternPhraser.sentence(for: crossCourt, locale: spain)
            == "Zurdo desde lateral izquierdo: lanza cruzado 5 de 6")
        #expect(PatternPhraser.sentence(for: crossCourt, locale: latinAmerica)
            == "Zurdo desde lateral izquierdo: tira cruzado 5 de 6")

        let saves = pattern(.sevenMeterSaves, 2, 6)
        #expect(PatternPhraser.sentence(for: saves, locale: spain) == "7 m: para 2 de 6")
        #expect(PatternPhraser.sentence(for: saves, locale: latinAmerica) == "7 m: ataja 2 de 6")
    }

    @Test("Pattern conversions agree in number")
    func patternConversionPlural() {
        let one = pattern(.deliverySide(.jump, .right), 4, 5, conversion: Tally(successes: 1, attempts: 4))
        #expect(PatternPhraser.sentence(for: one, locale: spain)
            == "En suspensión, apunta a la derecha 4 de 5 (1 gol)")
        let three = pattern(.deliveryHeight(.standing, .bottom), 5, 6, conversion: Tally(successes: 3, attempts: 5))
        #expect(PatternPhraser.sentence(for: three, locale: latinAmerica)
            == "A pie firme, apunta abajo 5 de 6 (3 goles)")
    }

    @Test("Template insights are phrased per variant, with plurals")
    func templateInsights() async throws {
        let zone = RankedTally(key: GoalZone(row: .top, column: .left), tally: Tally(successes: 2, attempts: 4))
        let goalkeeper = InsightFacts.goalkeeper(overall: Tally(successes: 1, attempts: 1), weakZone: zone)
        #expect(try await TemplateInsightWriter(locale: spain).write(goalkeeper)
            == "En 1 lanzamiento a portería, 1 parada. Más goles encajados: arriba izquierda (2 de 4 lanzamientos a portería).")
        #expect(try await TemplateInsightWriter(locale: latinAmerica).write(goalkeeper)
            == "En 1 tiro al arco, 1 atajada. Más goles recibidos: arriba izquierda (2 de 4 tiros al arco).")

        let empty = InsightFacts.shooter(overall: Tally(successes: 0, attempts: 0), leadingZone: nil)
        #expect(try await TemplateInsightWriter(locale: latinAmerica).write(empty)
            == "No hay tiros registrados de este tirador.")
    }

    @Test("The last-shot card speaks each variant")
    func shotSummary() {
        let shot = Shot(attackingSide: .rival, shooter: Player(number: 7), isSevenMeters: true,
                        target: .post(.crossbarCenter), outcome: .post, date: Date(timeIntervalSince1970: 0))
        #expect(ShotSummary(shot: shot, locale: spain).text == "#7 · 7 m · larguero centro · POSTE")
        #expect(ShotSummary(shot: shot, locale: latinAmerica).text == "#7 · 7 m · travesaño centro · PALO")
    }
}
