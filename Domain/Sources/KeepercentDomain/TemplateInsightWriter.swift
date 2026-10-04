import Foundation

/// A deterministic, offline fallback. It describes counts and their sample
/// without labeling a rate or extrapolating a trend from a single attempt.
/// Patterns are not repeated here: the card already lists them, phrased by
/// `PatternPhraser`.
///
/// It writes in `locale`'s language. Counted nouns ("3 goals", "1 save")
/// are their own catalog entries with plural variants, so each language
/// agrees them with the number its own way.
public struct TemplateInsightWriter: InsightWriter {
    private let locale: Locale

    public init(locale: Locale = .current) {
        self.locale = locale
    }

    public func write(_ facts: InsightFacts) -> String {
        switch facts {
        case .shooter(let overall, let leadingZone, _):
            guard overall.attempts > 0 else {
                return String(domain: "No shots recorded for this shooter.", locale: locale)
            }
            let shots = String(domain: "\(overall.attempts) recorded shots", locale: locale)
            let goals = String(domain: "\(overall.successes) goals", locale: locale)
            let count = String(domain: "In \(shots), \(goals).", locale: locale)
            guard let leadingZone else { return count }
            let sample = String(domain: "\(leadingZone.tally.attempts) shots", locale: locale)
            let zone = leadingZone.key.displayName(locale: locale)
            return count + " " + String(
                domain: "Most goals: \(zone) (\(leadingZone.tally.successes) of \(sample)).",
                locale: locale
            )

        case .goalkeeper(let overall, let weakZone, _):
            guard overall.attempts > 0 else {
                return String(domain: "No shots on target recorded for this goalkeeper.", locale: locale)
            }
            let shots = String(domain: "\(overall.attempts) shots on target", locale: locale)
            let saves = String(domain: "\(overall.successes) saves", locale: locale)
            let count = String(domain: "In \(shots), \(saves).", locale: locale)
            guard let weakZone else { return count }
            let sample = String(domain: "\(weakZone.tally.attempts) shots on target", locale: locale)
            let zone = weakZone.key.displayName(locale: locale)
            return count + " " + String(
                domain: "Most goals conceded: \(zone) (\(weakZone.tally.successes) of \(sample)).",
                locale: locale
            )
        }
    }
}
