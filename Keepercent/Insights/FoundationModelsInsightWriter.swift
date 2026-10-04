import Foundation
import FoundationModels
import KeepercentDomain

/// Phrases precomputed scouting facts on-device. The template remains the
/// authoritative result whenever generation cannot safely describe them.
struct FoundationModelsInsightWriter: InsightWriter {
    private let fallback = TemplateInsightWriter()

    func write(_ facts: InsightFacts) async throws -> String {
        let baseline = fallback.write(facts)
        let attempts: Int
        let patterns: [ScoutingPattern]
        switch facts {
        case .shooter(let overall, _, let found), .goalkeeper(let overall, _, let found):
            attempts = overall.attempts
            patterns = found
        }

        // No evidence (or only one attempt) is not a trend to interpret.
        guard attempts > 1 else { return baseline }
        let model = SystemLanguageModel.default
        switch model.availability {
        case .available: break
        case .unavailable: return baseline
        }

        // Patterns arrive already phrased by the same deterministic code the
        // card shows, so the model only ever sees finished, counted facts.
        let patternNotes = patterns.map { PatternPhraser.sentence(for: $0) }
        var prompt = "Rephrase this scouting note: \(baseline)"
        if !patternNotes.isEmpty {
            prompt += " You may also mention these patterns: \(patternNotes.joined(separator: "; "))."
        }

        do {
            let session = LanguageModelSession(model: model) {
                "You write brief handball scouting notes in English. Rephrase only the supplied text. "
                + "Keep every count and its sample, preserve which outcome belongs to which player, "
                + "and do not invent statistics, rates, reasons, predictions, or new observations. "
                + "Use only these numbers. "
                + "Never describe a small sample as a proven tendency. Reply with two or three sentences only."
            }
            let response = try await session.respond(to: prompt)
            let text = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
            let supplied = numbers(in: ([baseline] + patternNotes).joined(separator: " "))
            guard !text.isEmpty,
                  !text.contains("%"),
                  isSubset(numbers(in: baseline), of: numbers(in: text)),
                  isSubset(numbers(in: text), of: supplied)
            else {
                return baseline
            }
            return text
        } catch {
            // Model refusal, download delay or generation failure never hides the facts.
            return baseline
        }
    }

    /// Every numeric token in the text, so added, missing or repeated
    /// samples can be detected, not just added rates.
    private func numbers(in text: String) -> [String] {
        let pattern = /[0-9]+/
        return text.matches(of: pattern).map { String($0.output) }
    }

    /// Whether every number in `part` appears in `whole`, counting
    /// repeats: the note must keep the baseline's counts, and may only use
    /// numbers that were supplied — mentioning a pattern is optional.
    private func isSubset(_ part: [String], of whole: [String]) -> Bool {
        var remaining = whole
        for number in part {
            guard let index = remaining.firstIndex(of: number) else { return false }
            remaining.remove(at: index)
        }
        return true
    }
}
