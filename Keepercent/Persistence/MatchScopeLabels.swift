import Foundation

/// Presentation only: match IDs, ordering and filtering belong to ScopedMatchData.
enum MatchScopeLabels {
    static func needsOrdinal(for date: Date, among dates: [Date], calendar: Calendar = .current) -> Bool {
        dates.filter { calendar.isDate($0, inSameDayAs: date) }.count > 1
    }

    static func label(date: String, kind: String, opponent: String? = nil, ordinal: Int?) -> String {
        let match = ordinal.map { String(localized: "\(date) · \(kind) · Match \($0)") } ?? "\(date) · \(kind)"
        return opponent.map { String(localized: "vs \($0) · \(match)") } ?? match
    }
}
