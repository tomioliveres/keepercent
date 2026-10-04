import Foundation
import FoundationModels
import KeepercentDomain

/// Phrases precomputed scouting facts on-device. The template remains the
/// authoritative result whenever generation cannot safely describe them.
struct FoundationModelsInsightWriter: InsightWriter {
    /// Resolve the app language, not the device's region or formatting locale.
    /// One variant drives model support, instructions and deterministic prose.
    static var appLocale: Locale {
        Locale(identifier: Bundle.main.preferredLocalizations.first ?? "en")
    }

    let locale: Locale

    init(locale: Locale = Self.appLocale) {
        self.locale = locale
    }

    func write(_ facts: InsightFacts) async throws -> String {
        let baseline = TemplateInsightWriter(locale: locale).write(facts)
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
        // A language the model cannot write keeps the template, which is
        // already in the scout's language.
        guard model.supportsLocale(locale) else { return baseline }

        // Patterns arrive already phrased by the same deterministic code the
        // card shows, so the model only ever sees finished, counted facts.
        let patternNotes = patterns.map { PatternPhraser.sentence(for: $0, locale: locale) }
        var prompt = "Rephrase this scouting note: \(baseline)"
        if !patternNotes.isEmpty {
            prompt += " You may also mention these patterns: \(patternNotes.joined(separator: "; "))."
        }

        do {
            let session = LanguageModelSession(model: model) {
                "You write brief handball scouting notes in \(noteLanguage). Rephrase only the supplied text. "
                + "Keep every count and its sample, preserve which outcome belongs to which player, "
                + "and do not invent statistics, rates, reasons, predictions, or new observations. "
                + "Use only these numbers. "
                + "Never describe a small sample as a proven tendency. Reply with two or three sentences only."
            }
            let response = try await session.respond(to: prompt)
            let text = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
            // No rates are supplied by today's templates or pattern sentences.
            // The guard therefore rejects generated rates, even if calculable.
            guard InsightNumberGuard.accepts(text, baseline: baseline, optionalNotes: patternNotes)
            else {
                return baseline
            }
            return text
        } catch {
            // Model refusal, download delay or generation failure never hides the facts.
            return baseline
        }
    }

    /// The language the app is showing, spelled out for the model with the
    /// variant's own handball vocabulary, so the note reads like the
    /// template it rephrases: Spain and Latin America name the goalkeeper,
    /// the save and the shot differently.
    private var noteLanguage: String {
        switch locale.identifier {
        case "es":
            "Spanish as used in Spain (portero, parada, lanzamiento, encajar)"
        case "es-419":
            "Latin American Spanish (arquero, atajada, tiro, recibir)"
        default:
            "English"
        }
    }

}
