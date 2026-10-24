import Foundation
import Testing
@testable import ProductionStore

struct VerifierMatchScopeLabelsTests {
    @Test func uniqueAndUnavailableLabels() {
        #expect(MatchScopeLabels.label(date: "20 Sep", kind: "League", ordinal: nil) == "20 Sep · League")
        #expect(MatchScopeLabels.label(date: "20 Sep", kind: "League", opponent: "BM Serra", ordinal: nil) == "vs BM Serra · 20 Sep · League")
        #expect(MatchScopeLabels.label(date: "20 Sep", kind: "Unknown kind", opponent: "Opponent unavailable", ordinal: nil) == "vs Opponent unavailable · 20 Sep · Unknown kind")
        #expect(MatchScopeLabels.label(date: "20 Sep", kind: "League", opponent: "BM Serra", ordinal: 2) == "vs BM Serra · 20 Sep · League · Match 2")
    }

    @Test func emptySingletonAndDuplicateDates() {
        let d = Date(timeIntervalSince1970: 1_790_000_000)
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(secondsFromGMT: 0)!
        #expect(!MatchScopeLabels.needsOrdinal(for: d, among: [], calendar: c))
        #expect(!MatchScopeLabels.needsOrdinal(for: d, among: [d], calendar: c))
        #expect(MatchScopeLabels.needsOrdinal(for: d, among: [d, d], calendar: c))
    }

    @Test func localDayNotElapsedTimeOrUTC() {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        let d = c.date(from: DateComponents(year: 2026, month: 9, day: 20, hour: 0, minute: 1))!
        let late = c.date(from: DateComponents(year: 2026, month: 9, day: 20, hour: 23, minute: 59))!
        let next = c.date(from: DateComponents(year: 2026, month: 9, day: 21, hour: 0, minute: 1))!
        #expect(MatchScopeLabels.needsOrdinal(for: d, among: [d, late], calendar: c))
        #expect(!MatchScopeLabels.needsOrdinal(for: late, among: [late, next], calendar: c))
        let otherYear = c.date(from: DateComponents(year: 2025, month: 9, day: 20, hour: 0, minute: 1))!
        #expect(!MatchScopeLabels.needsOrdinal(for: d, among: [d, otherYear], calendar: c))
    }

    @Test func formattingPreservesUserText() {
        #expect(MatchScopeLabels.label(date: "20 Sep", kind: "Video", opponent: "BM · Serra 🧤", ordinal: 1) == "vs BM · Serra 🧤 · 20 Sep · Video · Match 1")
    }
}
