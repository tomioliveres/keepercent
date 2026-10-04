/// Facts for one card, already counted and ranked by `StatsEngine`. The
/// shooter tally is goals over shots; the goalkeeper tally is saves over
/// shots on target. A weak-zone tally counts goals conceded over shots on
/// target in that zone. `patterns` are the top `ScoutingPattern`s, already
/// ranked: the template leaves them to the patterns list, and the on-device
/// model may mention them. No writer needs the raw shots or computes a rate.
public enum InsightFacts: Equatable, Sendable {
    case shooter(overall: Tally, leadingZone: RankedTally<GoalZone>?, patterns: [ScoutingPattern] = [])
    case goalkeeper(overall: Tally, weakZone: RankedTally<GoalZone>?, patterns: [ScoutingPattern] = [])
}

/// Turns supplied scouting facts into text. The asynchronous, throwing
/// boundary also accommodates an on-device language model in T5.2; the
/// template implementation never fails and needs no model or network.
public protocol InsightWriter: Sendable {
    func write(_ facts: InsightFacts) async throws -> String
}
