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
        switch facts {
        case .shooter(let overall, _), .goalkeeper(let overall, _):
            attempts = overall.attempts
        }

        // No evidence (or only one attempt) is not a trend to interpret.
        guard attempts > 1 else { return baseline }
        let model = SystemLanguageModel.default
        switch model.availability {
        case .available: break
        case .unavailable: return baseline
        }

        do {
            let session = LanguageModelSession(model: model) {
                "You write brief handball scouting notes in English. Rephrase only the supplied text. "
                + "Keep every count and its sample, preserve which outcome belongs to which player, "
                + "and do not invent statistics, rates, reasons, predictions, or new observations. "
                + "Never describe a small sample as a proven tendency. Reply with one or two sentences only."
            }
            let response = try await session.respond(to: "Rephrase this scouting note: \(baseline)")
            let text = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty, !text.contains("%"), numbers(in: text) == numbers(in: baseline) else {
                return baseline
            }
            return text
        } catch {
            // Model refusal, download delay or generation failure never hides the facts.
            return baseline
        }
    }

    /// Reject added, missing or repeated numeric samples, not just added rates.
    private func numbers(in text: String) -> [String] {
        let pattern = /[0-9]+/
        return text.matches(of: pattern).map { String($0.output) }.sorted()
    }
}
