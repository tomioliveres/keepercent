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
}
