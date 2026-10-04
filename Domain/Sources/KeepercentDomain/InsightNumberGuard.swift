import Foundation

/// Validates numeric values and their count/percentage kind, not prose semantics.
/// Baseline occurrences are required; optional notes may supply extra occurrences.
/// This cannot prove that a count remains associated with the correct player or
/// outcome: the prompt and external model-wording verification still own that check.
public enum InsightNumberGuard {
    public static func accepts(_ text: String, baseline: String, optionalNotes: [String] = []) -> Bool {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let actual = tokens(in: text), let required = tokens(in: baseline),
              let supplied = tokens(in: ([baseline] + optionalNotes).joined(separator: " "))
        else { return false }
        return isSubset(required, of: actual) && isSubset(actual, of: supplied)
    }

    private struct Token: Equatable {
        let value: Decimal
        let isPercentage: Bool
    }

    private static func tokens(in text: String) -> [Token]? {
        // A decimal is ONE token. Treating its digits separately would allow
        // "8.3" to replace the two supplied counts "8" and "3". A sign, even
        // detached ("- 8"), is captured so it can be rejected: no supplied
        // statistic is signed.
        let pattern = /(?:[+−-]\s*)?[0-9]+(?:[.,][0-9]+)?(?:\s*%)?/
        var result: [Token] = []
        for match in text.matches(of: pattern) {
            let raw = String(match.output)
            guard !raw.hasPrefix("-"), !raw.hasPrefix("+"), !raw.hasPrefix("−") else { return nil }
            let number = raw.replacingOccurrences(of: "%", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: ",", with: ".")
            guard let value = Decimal(string: number, locale: Locale(identifier: "en_US_POSIX"))
            else { return nil }
            result.append(Token(value: value, isPercentage: raw.hasSuffix("%")))
        }
        // Every percent sign must belong to a rate. A stray one ("% 3",
        // "3 goals %") would let a reader take a supplied count for a rate.
        let percentSigns = text.filter { $0 == "%" }.count
        guard percentSigns == result.filter(\.isPercentage).count else { return nil }
        return result
    }

    private static func isSubset(_ part: [Token], of whole: [Token]) -> Bool {
        var remaining = whole
        for token in part {
            guard let index = remaining.firstIndex(of: token) else { return false }
            remaining.remove(at: index)
        }
        return true
    }
}
