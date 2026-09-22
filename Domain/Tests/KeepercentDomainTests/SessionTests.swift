import Foundation
import Testing
@testable import KeepercentDomain

/// Builds a fixed Gregorian calendar pinned to `identifier`, so a test that
/// cares about time-zone behaviour states its zone explicitly rather than
/// depending on wherever the test runner happens to execute.
private func calendar(_ identifier: String) -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: identifier)!
    return calendar
}

/// Builds a `Date` from explicit components in `calendar`, the same way
/// `DemoData.sessionDate` avoids a raw epoch offset landing on a day
/// boundary by accident.
private func date(
    year: Int,
    month: Int,
    day: Int,
    hour: Int = 12,
    minute: Int = 0,
    in calendar: Calendar
) -> Date {
    var components = DateComponents()
    components.year = year
    components.month = month
    components.day = day
    components.hour = hour
    components.minute = minute
    components.timeZone = calendar.timeZone
    return calendar.date(from: components)!
}

@Suite("Session.init")
struct SessionInitTests {
    private let utc = calendar("UTC")

    @Test("A match date on an earlier calendar day than today is accepted", arguments: [SessionKind.live, .video])
    func pastDayAccepted(kind: SessionKind) throws {
        let today = date(year: 2026, month: 9, day: 20, in: utc)
        let matchDate = date(year: 2026, month: 9, day: 18, hour: 21, minute: 30, in: utc)

        let session = try Session(kind: kind, matchDate: matchDate, today: today, calendar: utc)

        #expect(session.matchDate == matchDate)
    }

    @Test("Today at the very start of the day is accepted")
    func todayMidnightAccepted() throws {
        let today = date(year: 2026, month: 9, day: 20, hour: 15, minute: 0, in: utc)
        let matchDate = date(year: 2026, month: 9, day: 20, hour: 0, minute: 0, in: utc)

        let session = try Session(kind: .live, matchDate: matchDate, today: today, calendar: utc)

        #expect(session.matchDate == matchDate)
    }

    @Test("Today at the very end of the day is accepted")
    func todayLastMinuteAccepted() throws {
        let today = date(year: 2026, month: 9, day: 20, hour: 6, minute: 0, in: utc)
        let matchDate = date(year: 2026, month: 9, day: 20, hour: 23, minute: 59, in: utc)

        let session = try Session(kind: .live, matchDate: matchDate, today: today, calendar: utc)

        #expect(session.matchDate == matchDate)
    }

    @Test("Tomorrow at the very start of the day is rejected")
    func tomorrowMidnightRejected() throws {
        let today = date(year: 2026, month: 9, day: 20, hour: 23, minute: 0, in: utc)
        let matchDate = date(year: 2026, month: 9, day: 21, hour: 0, minute: 0, in: utc)

        #expect(throws: SessionError.matchDateInFuture) {
            try Session(kind: .live, matchDate: matchDate, today: today, calendar: utc)
        }
    }

    @Test("The comparison uses the injected calendar's time zone, not an absolute instant")
    func comparisonUsesInjectedTimeZone() throws {
        // `today` is 23:30 UTC on Sep 20, which is already 01:30 on Sep 21
        // in UTC+2. `matchDate` is 00:30 UTC on Sep 21, i.e. Sep 21 in both
        // zones. Read through UTC, `today` is still on Sep 20, so this
        // `matchDate` is strictly later and must be rejected. Read through
        // UTC+2, `today` has already rolled to Sep 21 too, so the very same
        // pair of instants must be accepted: the outcome depends on the
        // injected calendar's zone, not on comparing the instants directly.
        let today = date(year: 2026, month: 9, day: 20, hour: 23, minute: 30, in: utc)
        let matchDate = date(year: 2026, month: 9, day: 21, hour: 0, minute: 30, in: utc)

        #expect(throws: SessionError.matchDateInFuture) {
            try Session(kind: .live, matchDate: matchDate, today: today, calendar: utc)
        }

        let plusTwo = calendar("Europe/Paris") // UTC+2 in September (DST)
        let session = try Session(kind: .live, matchDate: matchDate, today: today, calendar: plusTwo)
        #expect(session.matchDate == matchDate)
    }

    @Test("The stored kind matches the input")
    func storesKind() throws {
        let today = date(year: 2026, month: 9, day: 20, in: utc)
        let matchDate = date(year: 2026, month: 9, day: 20, in: utc)

        let session = try Session(kind: .video, matchDate: matchDate, today: today, calendar: utc)

        #expect(session.kind == .video)
    }
}
