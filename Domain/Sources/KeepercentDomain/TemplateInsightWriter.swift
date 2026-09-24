/// A deterministic, offline fallback. It describes counts and their sample
/// without labeling a rate or extrapolating a trend from a single attempt.
public struct TemplateInsightWriter: InsightWriter {
    public init() {}

    public func write(_ facts: InsightFacts) -> String {
        switch facts {
        case .shooter(let overall, let leadingZone):
            guard overall.attempts > 0 else { return "No shots recorded for this shooter." }
            let count = "In \(overall.attempts) recorded \(plural(overall.attempts, "shot")), "
                + "\(overall.successes) \(plural(overall.successes, "goal"))."
            guard let leadingZone else { return count }
            return count + " Most goals: \(name(leadingZone.key)) "
                + "(\(leadingZone.tally.successes) of \(leadingZone.tally.attempts) "
                + "\(plural(leadingZone.tally.attempts, "shot")))."

        case .goalkeeper(let overall, let weakZone):
            guard overall.attempts > 0 else { return "No shots on target recorded for this goalkeeper." }
            let count = "In \(overall.attempts) \(plural(overall.attempts, "shot")) on target, "
                + "\(overall.successes) \(plural(overall.successes, "save"))."
            guard let weakZone else { return count }
            return count + " Most goals conceded: \(name(weakZone.key)) "
                + "(\(weakZone.tally.successes) of \(weakZone.tally.attempts) "
                + "\(plural(weakZone.tally.attempts, "shot")) on target)."
        }
    }

    private func plural(_ count: Int, _ singular: String) -> String {
        count == 1 ? singular : singular + "s"
    }

    private func name(_ zone: GoalZone) -> String {
        let row: String
        switch zone.row {
        case .top: row = "top"
        case .middle: row = "middle"
        case .bottom: row = "bottom"
        }
        let column: String
        switch zone.column {
        case .left: column = "left"
        case .center: column = "center"
        case .right: column = "right"
        }
        return "\(row) \(column)"
    }
}
