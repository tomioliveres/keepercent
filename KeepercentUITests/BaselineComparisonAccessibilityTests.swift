import XCTest

/// Diagnostic overlay shared byte-for-byte by the baseline and candidate.
/// Successful setup or compilation is not an audit pass or viewport equivalence proof.
@MainActor
final class BaselineComparisonAccessibilityTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testAuditSessionsDemo() throws {
        let app = launch(screen: "sessions")
        XCTAssertTrue(app.buttons["Shot Log"].waitForExistence(timeout: 10))
        try audit(app, label: "Goal, top left", type: .button)
    }

    func testAuditScoutingDemo() throws {
        let app = launch(screen: "scouting")
        XCTAssertTrue(app.buttons["Effectiveness"].waitForExistence(timeout: 10))
        try audit(app, label: "Goal, top left", type: .staticText)
    }

    func testAuditShooterCardDemo() throws {
        let app = launch(screen: "shooterCard")
        XCTAssertTrue(app.staticTexts["#3 · Jordi Ferrer"].waitForExistence(timeout: 10))
        try audit(app, label: "Goal, top right", type: .staticText, value: "0 goals in 1 shot")
    }

    func testAuditGoalkeeperCardDemo() throws {
        let app = launch(screen: "goalkeeperCard")
        XCTAssertTrue(app.staticTexts["#1 · Marc Puig"].waitForExistence(timeout: 10))
        // Field and penalty drawings share labels, but not this sample value.
        try audit(app, label: "Goal, bottom left", type: .staticText, value: "1 save in 6 shots on target")
    }

    func testAuditGoalkeeperCardEmpty() throws {
        let app = launch(screen: "goalkeeperCard", data: "emptyGoalkeeper")
        XCTAssertTrue(app.staticTexts["No shots faced yet"].waitForExistence(timeout: 10))
        try audit(app, label: "Goal, top left", type: .staticText, value: "No data")
    }

    private func launch(screen: String, data: String = "demo") -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-KPScreen", screen, "-KPData", data,
            "-AppleLanguages", "(en)", "-AppleLocale", "en_US"
        ]
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
        return app
    }

    private func audit(
        _ app: XCUIApplication,
        label: String,
        type: XCUIElement.ElementType,
        value: String? = nil
    ) throws {
        let alternatives = app.descendants(matching: type)
            .matching(NSPredicate(format: "label == %@", label))
        let candidates: XCUIElementQuery
        if let value {
            candidates = alternatives.matching(NSPredicate(format: "value == %@", value))
        } else {
            candidates = alternatives
        }

        // Same initial route and upward-only scroll policy as the original audits.
        // Scouting may expose both field and penalty labels. Deliberately choose
        // the first query match (field drawing precedes penalties in source),
        // never an arbitrary hittable duplicate. Counts/frames below must be
        // checked externally; tree order alone does not prove paired viewports.
        let anchor = candidates.firstMatch
        reveal(anchor, in: app)
        let settled = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == true AND hittable == true"),
            object: anchor
        )
        XCTAssertEqual(XCTWaiter.wait(for: [settled], timeout: 5), .completed)
        XCTAssertEqual(anchor.label, label)
        if let value { XCTAssertEqual(anchor.value as? String, value) }
        attachEvidence(app, anchor: anchor, alternatives: alternatives, candidates: candidates)
        if value != nil || type == .button {
            XCTAssertEqual(candidates.count, 1, "Semantic anchor must identify only the intended drawing")
        }
        // Default .all, no handler, no catch: audit issues remain failures.
        try app.performAccessibilityAudit()
    }

    private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        if element.waitForExistence(timeout: 5), element.isHittable { return }
        let scroll = app.scrollViews.firstMatch
        XCTAssertTrue(scroll.waitForExistence(timeout: 5))
        for _ in 0..<12 {
            scroll.swipeUp()
            if element.waitForExistence(timeout: 1), element.isHittable { return }
        }
        keep(XCTAttachment(string: app.debugDescription), name: "Setup failure hierarchy")
        keep(XCTAttachment(screenshot: app.screenshot()), name: "Setup failure viewport")
        XCTFail("Could not reveal semantic anchor within twelve scroll gestures")
    }

    private func attachEvidence(
        _ app: XCUIApplication,
        anchor: XCUIElement,
        alternatives: XCUIElementQuery,
        candidates: XCUIElementQuery
    ) {
        let viewport = app.frame
        let matches = alternatives.allElementsBoundByIndex
        let details = matches.enumerated().map { index, element in
            let visible = element.frame.intersects(viewport) && !element.frame.isEmpty
            return "alternative[\(index)]: \(describe(element)); intersectsViewport=\(visible)"
        }
        let report = [
            "Selection: label/type, optional exact value, then first query match",
            "Label matches: \(matches.count); semantic candidates: \(candidates.count)",
            "Chosen anchor: \(describe(anchor))",
            "Application frame: \(viewport)",
            "Viewport equivalence UNVERIFIED: compare paired screenshot and hierarchy",
            "Intersection is geometry evidence, not proof of visibility or lack of occlusion"
        ] + details
        keep(XCTAttachment(string: report.joined(separator: "\n")), name: "Pre-audit anchor and alternatives")
        keep(XCTAttachment(screenshot: app.screenshot()), name: "Pre-audit viewport")
        keep(XCTAttachment(string: app.debugDescription), name: "Pre-audit hierarchy")
    }

    private func describe(_ element: XCUIElement) -> String {
        "label=\(element.label); value=\(String(describing: element.value)); frame=\(element.frame); hittable=\(element.isHittable)"
    }

    private func keep(_ attachment: XCTAttachment, name: String) {
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
