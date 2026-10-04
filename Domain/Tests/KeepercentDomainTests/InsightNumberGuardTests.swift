import Testing
@testable import KeepercentDomain

@Suite("Insight numeric safety")
struct InsightNumberGuardTests {
    @Test("Baseline counts stay required; pattern counts are optional")
    func baselineAndPatterns() {
        let baseline = "In 8 shots, 3 goals (2 of 4)."
        #expect(InsightNumberGuard.accepts("3 goals in 8 shots; 2 of 4.", baseline: baseline))
        #expect(InsightNumberGuard.accepts("8 shots, 3 goals, 2 of 4; 5 of 6.", baseline: baseline,
                                          optionalNotes: ["5 of 6"]))
        #expect(InsightNumberGuard.accepts("8 shots, 3 goals, 2 of 4.", baseline: baseline,
                                          optionalNotes: ["5 of 6"]))
        for text in ["8 shots, 3 goals, 2.", "8 shots, 3 goals, 2 of 4, 4.",
                     "8 shots, 3 goals, 2 of 9.", "", "No numbers"] {
            #expect(!InsightNumberGuard.accepts(text, baseline: baseline))
        }
    }

    @Test("Rates require both the supplied value and percentage kind")
    func suppliedRates() {
        for text in ["6 of 7, 86%", "6 of 7, 86 %", "6 of 7, 86\u{00a0}%"] {
            #expect(InsightNumberGuard.accepts(text, baseline: "6 of 7", optionalNotes: ["86% saves"]))
        }
        #expect(InsightNumberGuard.accepts("6 of 7, 85,7 %", baseline: "6 of 7",
                                          optionalNotes: ["85.7% saves"]))
        for text in ["6 of 7, 86%", "6 of 7, 85,7 %", "6% of 7"] {
            #expect(!InsightNumberGuard.accepts(text, baseline: "6 of 7", optionalNotes: ["86 shots"]))
        }
        #expect(!InsightNumberGuard.accepts("6 of 7, 86", baseline: "6 of 7", optionalNotes: ["86% saves"]))
    }

    @Test("Decimals cannot smuggle two counts and signs cannot invent values")
    func decimalsAndSigns() {
        for text in ["8.3 shots", "8,3 shots", "-8 shots, 3 goals", "+8 shots, 3 goals",
                     "−8 shots, 3 goals", "- 8 shots, 3 goals", "8 shots, -3 goals",
                     "8 shots, 3 goals, 8.3%"] {
            #expect(!InsightNumberGuard.accepts(text, baseline: "8 shots, 3 goals"))
        }
        #expect(!InsightNumberGuard.accepts("85 of 7", baseline: "85.7%"))
        #expect(!InsightNumberGuard.accepts("85.7% and 85,7 %", baseline: "85.7%"))
        #expect(InsightNumberGuard.accepts("85,70 %", baseline: "85.7%"))
    }

    @Test("A detached percent sign cannot turn a supplied count into a rate")
    func detachedPercent() {
        #expect(!InsightNumberGuard.accepts("8 shots, % 3 goals", baseline: "8 shots, 3 goals"))
        #expect(!InsightNumberGuard.accepts("8 shots, 3 goals %", baseline: "8 shots, 3 goals"))
    }

    @Test("Repeated baseline counts preserve multiplicity, including zero and 7 m")
    func multiplicity() {
        #expect(InsightNumberGuard.accepts("7 m: 0 of 7", baseline: "7 m: 0 of 7"))
        #expect(!InsightNumberGuard.accepts("7 m: 0", baseline: "7 m: 0 of 7"))
        #expect(!InsightNumberGuard.accepts("7 m: 0 of 7, 7", baseline: "7 m: 0 of 7"))
    }
}
