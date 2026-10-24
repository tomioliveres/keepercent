import Foundation
import Testing
@testable import ProductionStore

struct MatchScopeLabelsTests {
    @Test func labelsAreShortAndOnlyDisambiguateSameDay() {
        let calendar = Calendar(identifier: .gregorian)
        let date = Date(timeIntervalSince1970: 1_790_000_000)
        let sameDay = date.addingTimeInterval(60)
        let previousDay = calendar.date(byAdding: .day, value: -1, to: date)!
        let dates = [date, sameDay, previousDay]
        #expect(MatchScopeLabels.needsOrdinal(for: date, among: dates, calendar: calendar))
        #expect(!MatchScopeLabels.needsOrdinal(for: previousDay, among: dates, calendar: calendar))
        #expect(MatchScopeLabels.label(date: "20 Sep", kind: "League", ordinal: nil) == "20 Sep · League")
        #expect(MatchScopeLabels.label(date: "20 Sep", kind: "League", ordinal: 2) == "20 Sep · League · Match 2")
        #expect(MatchScopeLabels.label(date: "20 Sep", kind: "League", opponent: "BM Serra", ordinal: nil)
            == "vs BM Serra · 20 Sep · League")
    }

    @Test func yearOnlyWhenSameDayAndMonthCollideAcrossYears() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        let sep2026 = calendar.date(from: DateComponents(year: 2026, month: 9, day: 20, hour: 0, minute: 1))!
        let sep2025 = calendar.date(from: DateComponents(year: 2025, month: 9, day: 20, hour: 23, minute: 59))!
        let sep2026Late = calendar.date(from: DateComponents(year: 2026, month: 9, day: 20, hour: 23, minute: 59))!
        let oct2026 = calendar.date(from: DateComponents(year: 2026, month: 10, day: 20))!
        #expect(MatchScopeLabels.needsYear(for: sep2026, among: [sep2026, sep2025], calendar: calendar))
        #expect(MatchScopeLabels.needsYear(for: sep2025, among: [sep2026, sep2025], calendar: calendar))
        #expect(!MatchScopeLabels.needsYear(for: sep2026, among: [sep2026, sep2026Late], calendar: calendar))
        #expect(!MatchScopeLabels.needsYear(for: sep2026, among: [sep2026, oct2026], calendar: calendar))
        #expect(!MatchScopeLabels.needsYear(for: sep2026, among: [sep2026], calendar: calendar))
    }
}
