import Foundation
import Testing
@testable import KeepercentDomain

@Suite("Delivery conversion comparison")
struct DeliveryConversionComparisonTests {
    private func sample(_ delivery: ShotDelivery?, goals: Int, attempts: Int,
                        sevenMeters: Bool = false) -> [Shot] {
        (0..<attempts).map { index in
            let outcome: ShotOutcome = index < goals ? .goal : [.saved, .post, .out][index % 3]
            let target: GoalTarget = outcome == .post ? .post(.crossbarCenter)
                : outcome == .out ? .out(.wideLeft, .middle)
                : .inside(GoalZone(row: .middle, column: .center))
            return Shot(attackingSide: .rival, isSevenMeters: sevenMeters, target: target,
                        outcome: outcome, delivery: delivery, date: Date(timeIntervalSince1970: 0))
        }
    }

    @Test(arguments: [true, false])
    func namedDirectionAndAllAttemptDenominator(standingHigher: Bool) throws {
        let shots = sample(.standing, goals: standingHigher ? 3 : 1, attempts: 4)
            + sample(.jump, goals: standingHigher ? 1 : 3, attempts: 4)
        let comparison = try #require(StatsEngine(shots: shots).deliveryConversionComparison())
        #expect(comparison.standing == Tally(successes: standingHigher ? 3 : 1, attempts: 4))
        #expect(comparison.jump == Tally(successes: standingHigher ? 1 : 3, attempts: 4))
    }

    @Test func exclusionsAndThresholds() throws {
        let noise = sample(nil, goals: 10, attempts: 10)
            + sample(.jump, goals: 10, attempts: 10, sevenMeters: true)
        let field = sample(.standing, goals: 3, attempts: 4) + sample(.jump, goals: 1, attempts: 4)
        #expect(StatsEngine(shots: field + noise).deliveryConversionComparison()
            == StatsEngine(shots: field).deliveryConversionComparison())
        #expect(StatsEngine(shots: noise).deliveryConversionComparison() == nil)
        for delivery in ShotDelivery.allCases {
            let small = sample(delivery, goals: 3, attempts: 3)
                + sample(delivery == .standing ? .jump : .standing, goals: 0, attempts: 4)
            #expect(StatsEngine(shots: small + noise).deliveryConversionComparison() == nil)
        }
        let below = sample(.standing, goals: 3, attempts: 4) + sample(.jump, goals: 2, attempts: 4)
        #expect(StatsEngine(shots: below).deliveryConversionComparison() == nil)
        #expect(StatsEngine(shots: []).deliveryConversionComparison() == nil)
    }

    @Test(arguments: [true, false])
    func exactRoundedGap(standingHigher: Bool) throws {
        let shots = sample(.standing, goals: standingHigher ? 7 : 4, attempts: 10)
            + sample(.jump, goals: standingHigher ? 4 : 7, attempts: 10)
        #expect(try #require(StatsEngine(shots: shots).deliveryConversionComparison()).standing.attempts == 10)
    }
}
