import Foundation

/// Presentation only: match IDs, ordering and filtering belong to ScopedMatchData.
enum MatchScopeLabels {
    static func needsOrdinal(for date: Date, among dates: [Date], calendar: Calendar = .current) -> Bool {
        dates.filter { calendar.isDate($0, inSameDayAs: date) }.count > 1
    }

    /// True when another date shares this one's day and month in a different year.
    static func needsYear(for date: Date, among dates: [Date], calendar: Calendar = .current) -> Bool {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return dates.contains {
            let other = calendar.dateComponents([.year, .month, .day], from: $0)
            return other.month == parts.month && other.day == parts.day && other.year != parts.year
        }
    }

    static func dateText(for date: Date, among dates: [Date], calendar: Calendar = .current) -> String {
        needsYear(for: date, among: dates, calendar: calendar)
            ? date.formatted(.dateTime.day().month(.abbreviated).year())
            : date.formatted(.dateTime.day().month(.abbreviated))
    }

    static func label(date: String, kind: String, opponent: String? = nil, ordinal: Int?) -> String {
        let match = ordinal.map { String(localized: "\(date) · \(kind) · Match \($0)") } ?? "\(date) · \(kind)"
        return opponent.map { String(localized: "vs \($0) · \(match)") } ?? match
    }
}
