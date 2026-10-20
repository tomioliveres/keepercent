/// Observed field-shot goals over all attempts for standing and jump delivery.
/// Named samples preserve direction without implying causation or prediction.
public struct DeliveryConversionComparison: Equatable, Sendable {
    public let standing: Tally
    public let jump: Tally

    fileprivate init(standing: Tally, jump: Tally) {
        self.standing = standing
        self.jump = jump
    }
}

extension StatsEngine {
    /// Compares supplied shots; the caller owns person and match scoping.
    /// Excludes 7 m and unknown delivery. Saves, posts and misses remain attempts.
    public func deliveryConversionComparison() -> DeliveryConversionComparison? {
        let field = fieldShots.shots
        let standing = StatsEngine(shots: field.filter { $0.delivery == .standing }).effectiveness
        let jump = StatsEngine(shots: field.filter { $0.delivery == .jump }).effectiveness

        guard standing.attempts >= ScoutingPattern.comparisonMinimumSample,
              jump.attempts >= ScoutingPattern.comparisonMinimumSample,
              let standingRate = standing.rate,
              let jumpRate = jump.rate,
              // Match existing comparisons' tolerance for 0.7 - 0.4 rounding.
              abs(standingRate - jumpRate) + 1e-9 >= ScoutingPattern.comparisonGap
        else { return nil }

        return DeliveryConversionComparison(standing: standing, jump: jump)
    }
}
