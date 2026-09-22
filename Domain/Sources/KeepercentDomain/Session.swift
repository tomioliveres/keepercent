// Session ties a session `kind` (live | video, see Shot.swift) to the date
// the match was actually played. That date is deliberately the MATCH date,
// not the entry date: a live session is recorded during the match so the
// two coincide, but video scouting happens days after the match was played,
// from footage reviewed later. See docs/mvp.md §5's `Session (date, kind,
// opponent)` and T3.2 in odd/tasks/keepercent.md for the decision this
// codifies.
//
// The active rival goalkeeper is deliberately NOT a session field: she can
// change mid-match (a substitution), so a single value on `Session` could
// not describe the whole session correctly. She is instead recorded per
// shot as `Shot.facingGoalkeeper` (see Shot.swift).
//
// There is also no rival-team field here. The opponent is the relationship
// a session hangs from — a session is created from that team's screen and
// belongs to it — rather than a value the session carries about itself, per
// docs/mvp.md §5.

import Foundation

/// What can go wrong constructing a `Session`, kept separate from
/// `RosterError` and `RivalTeamError` for the same reason those two are
/// split from each other: a session's own validity is a distinct concern
/// from a roster's or a team's, and folding it into either would make that
/// type's callers handle a case they can never produce.
public enum SessionError: Error, Equatable, Hashable, Sendable {
    /// `matchDate` falls on a calendar day later than `today`, in the
    /// calendar the caller supplied.
    case matchDateInFuture
}

/// One scouting session against a rival team: which `SessionKind` it was
/// recorded as, and the date the match was actually played.
public struct Session: Equatable, Hashable, Sendable {
    public let kind: SessionKind
    public let matchDate: Date

    /// Creates a session, rejecting a `matchDate` that falls on a calendar
    /// day after `today`'s day.
    ///
    /// Both `today` and `calendar` are supplied by the caller rather than
    /// read from `Date()` / `Calendar.current`: the domain never reads
    /// ambient system state (see CLAUDE.md), which is also what makes this
    /// rule deterministically testable across time zones.
    ///
    /// The comparison is by calendar DAY, not by instant: a match earlier
    /// today, or later today, must both be accepted, and only a `matchDate`
    /// whose day in `calendar` is strictly after `today`'s day in that same
    /// calendar is rejected. `matchDate` is stored exactly as given —
    /// unlike the day boundary used to validate it, the time of day within
    /// that day is not normalised away.
    public init(kind: SessionKind, matchDate: Date, today: Date, calendar: Calendar) throws {
        let matchDay = calendar.startOfDay(for: matchDate)
        let todayDay = calendar.startOfDay(for: today)
        guard matchDay <= todayDay else {
            throw SessionError.matchDateInFuture
        }
        self.kind = kind
        self.matchDate = matchDate
    }
}
