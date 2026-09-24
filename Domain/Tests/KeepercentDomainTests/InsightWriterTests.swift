import Testing
@testable import KeepercentDomain

@Suite("Template insight writer")
struct InsightWriterTests {
    private let writer: any InsightWriter = TemplateInsightWriter()

    @Test("No shooter shots do not imply a zero-percent performance")
    func emptyShooter() async throws {
        let facts = InsightFacts.shooter(overall: Tally(successes: 0, attempts: 0), leadingZone: nil)
        #expect(try await writer.write(facts) == "No shots recorded for this shooter.")
    }

    @Test("No shots on target do not imply a goalkeeper weakness")
    func emptyGoalkeeper() async throws {
        let facts = InsightFacts.goalkeeper(overall: Tally(successes: 0, attempts: 0), weakZone: nil)
        #expect(try await writer.write(facts) == "No shots on target recorded for this goalkeeper.")
    }

    @Test("A single goal is reported as a count, not a tendency")
    func singleShooterShot() async throws {
        let zone = GoalZone(row: .bottom, column: .right)
        let facts = InsightFacts.shooter(
            overall: Tally(successes: 1, attempts: 1),
            leadingZone: RankedTally(key: zone, tally: Tally(successes: 1, attempts: 1))
        )
        #expect(try await writer.write(facts) ==
            "In 1 recorded shot, 1 goal. Most goals: bottom right (1 of 1 shot).")
    }

    @Test("Shooter ranking uses the supplied counts and labels the zone")
    func shooterRanking() async throws {
        let zone = GoalZone(row: .top, column: .left)
        let facts = InsightFacts.shooter(
            overall: Tally(successes: 3, attempts: 6),
            leadingZone: RankedTally(key: zone, tally: Tally(successes: 2, attempts: 4))
        )
        let expected = "In 6 recorded shots, 3 goals. Most goals: top left (2 of 4 shots)."
        #expect(try await writer.write(facts) == expected)
        #expect(try await writer.write(facts) == expected)
    }

    @Test("Zero goals are stated without claiming any zone is dangerous")
    func noShooterGoals() async throws {
        let facts = InsightFacts.shooter(overall: Tally(successes: 0, attempts: 2), leadingZone: nil)
        #expect(try await writer.write(facts) == "In 2 recorded shots, 0 goals.")
    }

    @Test("Goalkeeper weakness is explicitly a count of conceded goals, not a rate")
    func goalkeeperWeakZone() async throws {
        let zone = GoalZone(row: .middle, column: .center)
        let facts = InsightFacts.goalkeeper(
            overall: Tally(successes: 1, attempts: 4),
            weakZone: RankedTally(key: zone, tally: Tally(successes: 2, attempts: 3))
        )
        #expect(try await writer.write(facts) ==
            "In 4 shots on target, 1 save. Most goals conceded: middle center (2 of 3 shots on target).")
    }

    @Test("A single faced shot is a sample, not evidence of a trend")
    func singleGoalkeeperShot() async throws {
        let facts = InsightFacts.goalkeeper(overall: Tally(successes: 1, attempts: 1), weakZone: nil)
        #expect(try await writer.write(facts) == "In 1 shot on target, 1 save.")
    }

    @Test("Both cards can pass their filtered StatsEngine facts without passing raw shots")
    func demoCardFacts() async throws {
        let engine = StatsEngine(shots: DemoData.shots)
        let shooter = engine.shots(by: DemoData.leftBackPauVidal.number)
        let goalkeeper = engine.shots(facing: DemoData.goalkeeperMarcPuig.number)

        let shooterText = try await writer.write(.shooter(
            overall: shooter.effectiveness,
            leadingZone: shooter.topGoalZones(limit: 1).first
        ))
        let goalkeeperText = try await writer.write(.goalkeeper(
            overall: goalkeeper.saveRate,
            weakZone: goalkeeper.weakGoalZones(limit: 1).first
        ))

        #expect(shooterText.contains("\(shooter.effectiveness.attempts) recorded shots"))
        #expect(shooterText.contains("Most goals:"))
        #expect(goalkeeperText.contains("\(goalkeeper.saveRate.attempts) shots on target"))
        #expect(goalkeeperText.contains("Most goals conceded:"))
        #expect(!shooterText.contains("%"))
        #expect(!goalkeeperText.contains("%"))
    }
}
