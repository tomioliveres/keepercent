import XCTest

/// Inspects the application's rendered accessibility tree, not spoken VoiceOver traversal.
@MainActor
final class DrawnRegionsAccessibilityTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testSessionGoalAndCourtExposeNamedButtons() {
        let app = launch(screen: "sessions")
        reveal(app.buttons["goal.entry.inside.top.left"], in: app)
        let goals = regions(in: app, prefix: "goal.entry.")
        XCTAssertEqual(goals.count, 27)
        XCTAssertTrue(goals.allSatisfy { $0.elementType == .button })
        assertLabel("Goal, top left", of: app.buttons["goal.entry.inside.top.left"])
        assertLabel("Left post, top", of: app.buttons["goal.entry.post.leftPostTop"])
        assertLabel("Crossbar, center", of: app.buttons["goal.entry.post.crossbarCenter"])
        assertLabel("Miss, wide right, middle", of: app.buttons["goal.entry.out.wideRight.middle"])
        assertLabel("Miss, over, center", of: app.buttons["goal.entry.out.over.center"])

        reveal(app.buttons["court.entry.sevenMeters"], in: app)
        assertCourt(in: app, scope: "court.entry")
    }

    func testDrawingScaffoldActivationsReachExistingCallbacks() {
        let app = launch(screen: "teams", data: "empty")
        let scaffold = app.buttons["Drawing Scaffold (T2.x)"]
        // Secondary toolbar actions can live in the native overflow menu on iPhone.
        if !scaffold.waitForExistence(timeout: 3) || !scaffold.isHittable {
            let more = app.buttons["More"].firstMatch
            XCTAssertTrue(more.waitForExistence(timeout: 5))
            more.tap()
        }
        XCTAssertTrue(scaffold.waitForExistence(timeout: 5))
        scaffold.tap()
        XCTAssertTrue(app.buttons["Close"].waitForExistence(timeout: 5))

        for code in ["inside.top.left", "post.crossbarCenter", "out.wideRight.middle"] {
            let region = app.buttons["goal.entry.\(code)"]
            XCTAssertTrue(region.waitForExistence(timeout: 5))
            XCTAssertTrue(region.isHittable)
            region.tap()
            XCTAssertTrue(app.staticTexts["Last tap: \(code)"].waitForExistence(timeout: 5))
        }
        for code in ["zone.leftWing.near", "zone.rightBack.far", "sevenMeters"] {
            let region = app.buttons["court.entry.\(code)"]
            XCTAssertTrue(region.waitForExistence(timeout: 5))
            XCTAssertTrue(region.isHittable)
            region.tap()
            XCTAssertTrue(app.staticTexts["Last tap: \(code)"].waitForExistence(timeout: 5))
        }
    }

    func testScoutingRenderedQueryGroupsGoalBeforeCourt() {
        let app = launch(screen: "scouting")
        reveal(app.staticTexts["goal.linked.inside.top.left"], in: app)
        reveal(app.buttons["court.linked.sevenMeters"], in: app)
        let elements = app.descendants(matching: .any).allElementsBoundByIndex
        let goalIndices = elements.indices.filter { elements[$0].identifier.hasPrefix("goal.linked.") }
        let courtIndices = elements.indices.filter { elements[$0].identifier.hasPrefix("court.linked.") }
        XCTAssertEqual(goalIndices.count, 27)
        XCTAssertEqual(courtIndices.count, 9)
        guard let lastGoal = goalIndices.max(), let firstCourt = courtIndices.min() else {
            XCTFail("Both rendered groups must exist")
            return
        }
        // This is the explicit goal-column-before-court-column tree contract.
        // It says nothing about VoiceOver's spatial sorting or spoken order.
        XCTAssertLessThan(lastGoal, firstCourt)
        assertInertGoal(in: app, scope: "goal.linked")
        assertCourt(in: app, scope: "court.linked")
    }

    func testShooterSamplesAndLinkedFilterSelectClear() {
        let app = launch(screen: "shooterCard") // Existing router selects Jordi Ferrer (#3).
        XCTAssertTrue(app.staticTexts["#3 · Jordi Ferrer"].waitForExistence(timeout: 10))
        let goal = app.staticTexts["goal.linked.inside.top.right"]
        reveal(goal, in: app)
        assertValue("0 goals in 1 shot", of: goal)
        assertInertGoal(in: app, scope: "goal.linked")

        let origin = app.buttons["court.linked.zone.rightBack.far"]
        reveal(origin, in: app)
        assertValue("0 goals in 1 shot", of: origin) // The located miss still counts for effectiveness.
        origin.tap()
        assertFilter("From right back · far · 1 shot", in: app)
        reveal(goal, in: app, upwards: true)
        assertValue("No data", of: goal)
        reveal(origin, in: app)
        origin.tap()
        assertFilter("All field shots · 2 shots", in: app)
        reveal(goal, in: app, upwards: true)
        assertValue("0 goals in 1 shot", of: goal)
    }

    func testGoalkeeperOnTargetDenominatorAndSeparatePenaltyScope() {
        let app = launch(screen: "goalkeeperCard") // Existing router selects Marc Puig (#1).
        XCTAssertTrue(app.staticTexts["#1 · Marc Puig"].waitForExistence(timeout: 10))
        let fieldGoal = app.staticTexts["goal.linked.inside.bottom.left"]
        reveal(fieldGoal, in: app)
        assertValue("1 save in 6 shots on target", of: fieldGoal)
        assertInertGoal(in: app, scope: "goal.linked")
        let postAndSave = app.buttons["court.linked.zone.leftWing.near"]
        reveal(postAndSave, in: app)
        assertValue("1 save in 1 shot on target", of: postAndSave) // Post excluded, save retained.

        let penalty = app.buttons["court.linked.sevenMeters"]
        reveal(penalty, in: app)
        assertValue("0 saves in 1 shot on target", of: penalty)
        penalty.tap()
        assertFilter("7 m throws · 1 shot", in: app)
        reveal(fieldGoal, in: app, upwards: true)
        assertValue("0 saves in 1 shot on target", of: fieldGoal)
        reveal(penalty, in: app)
        penalty.tap()
        assertFilter("All field shots · 13 shots", in: app)

        let dedicatedGoal = app.staticTexts["goal.penalty.inside.bottom.left"]
        reveal(dedicatedGoal, in: app)
        assertValue("0 saves in 1 shot on target", of: dedicatedGoal)
        assertInertGoal(in: app, scope: "goal.penalty")
        XCTAssertTrue(app.staticTexts["Attempts: 1 · Goals: 1 · Saves: 0 · Posts: 0 · Out: 0"].exists)
    }

    func testZeroShotGoalkeeperUsesNoDataWithoutInventingEmptyPenaltyDrawing() {
        let app = launch(screen: "goalkeeperCard", data: "emptyGoalkeeper")
        XCTAssertTrue(app.staticTexts["No shots faced yet"].waitForExistence(timeout: 10))
        reveal(app.staticTexts["goal.linked.inside.top.left"], in: app)
        let insideGoals = regions(in: app, prefix: "goal.linked.inside.")
        XCTAssertEqual(insideGoals.count, 9)
        for goal in insideGoals {
            assertValue("No data", of: goal)
            XCTAssertEqual(goal.elementType, .staticText)
        }
        reveal(app.buttons["court.linked.sevenMeters"], in: app)
        let origins = regions(in: app, prefix: "court.linked.")
        XCTAssertEqual(origins.count, 9)
        for origin in origins { assertValue("No data", of: origin) }
        app.buttons["court.linked.sevenMeters"].tap()
        assertFilter("7 m throws · 0 shots", in: app)
        reveal(app.staticTexts["7 m: no shots"].firstMatch, in: app)
        XCTAssertTrue(regions(in: app, prefix: "goal.penalty.").isEmpty)
    }

    func testAccessibilityAuditOnSettledSessions() throws {
        let app = launch(screen: "sessions")
        reveal(app.buttons["goal.entry.inside.top.left"], in: app)
        try app.performAccessibilityAudit()
    }

    func testAccessibilityAuditOnSettledScouting() throws {
        let app = launch(screen: "scouting")
        reveal(app.staticTexts["goal.linked.inside.top.left"], in: app)
        try app.performAccessibilityAudit()
    }

    func testAccessibilityAuditOnSettledShooterCard() throws {
        let app = launch(screen: "shooterCard")
        reveal(app.staticTexts["goal.linked.inside.top.right"], in: app)
        try app.performAccessibilityAudit()
    }

    func testAccessibilityAuditOnSettledGoalkeeperCard() throws {
        let app = launch(screen: "goalkeeperCard")
        reveal(app.staticTexts["goal.linked.inside.bottom.left"], in: app)
        try app.performAccessibilityAudit()
    }

    func testAccessibilityAuditOnSettledZeroShotGoalkeeper() throws {
        let app = launch(screen: "goalkeeperCard", data: "emptyGoalkeeper")
        reveal(app.staticTexts["goal.linked.inside.top.left"], in: app)
        try app.performAccessibilityAudit()
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

    private func regions(in app: XCUIApplication, prefix: String) -> [XCUIElement] {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH %@", prefix))
            .allElementsBoundByIndex
    }

    private func assertCourt(in app: XCUIApplication, scope: String) {
        let origins = regions(in: app, prefix: "\(scope).")
        XCTAssertEqual(origins.count, 9) // Five near, three far, one separate penalty mark.
        XCTAssertTrue(origins.allSatisfy { $0.elementType == .button })
        let codes = [
            "zone.leftWing.near", "zone.leftBack.near", "zone.center.near",
            "zone.rightBack.near", "zone.rightWing.near", "zone.leftBack.far",
            "zone.center.far", "zone.rightBack.far", "sevenMeters"
        ]
        XCTAssertEqual(Set(origins.map(\.identifier)), Set(codes.map { "\(scope).\($0)" }))
        assertLabel("Court, left wing, near", of: app.buttons["\(scope).zone.leftWing.near"])
        assertLabel("Court, right back, far", of: app.buttons["\(scope).zone.rightBack.far"])
        assertLabel("7 m mark", of: app.buttons["\(scope).sevenMeters"])
        XCTAssertFalse(origins.contains { $0.label.contains("6 m") })
        XCTAssertFalse(app.buttons["\(scope).zone.leftWing.far"].exists)
        XCTAssertFalse(app.buttons["\(scope).zone.rightWing.far"].exists)
    }

    private func assertInertGoal(in app: XCUIApplication, scope: String) {
        let goals = regions(in: app, prefix: "\(scope).")
        XCTAssertEqual(goals.count, 27)
        XCTAssertTrue(goals.allSatisfy { $0.elementType == .staticText })
        assertLabel("Goal, top left", of: app.staticTexts["\(scope).inside.top.left"])
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "\(scope).")).count, 0)
    }

    private func assertLabel(_ expected: String, of element: XCUIElement) {
        XCTAssertTrue(element.waitForExistence(timeout: 5))
        XCTAssertEqual(element.label, expected)
    }

    private func assertValue(_ expected: String, of element: XCUIElement) {
        XCTAssertTrue(element.waitForExistence(timeout: 5))
        let predicate = NSPredicate(format: "value == %@", expected)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: 5), .completed)
        XCTAssertEqual(element.value as? String, expected)
    }

    private func assertFilter(_ expected: String, in app: XCUIApplication) {
        let caption = app.staticTexts["linked.filter"]
        reveal(caption, in: app)
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", expected), object: caption)
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: 5), .completed)
    }

    private func reveal(_ element: XCUIElement, in app: XCUIApplication, upwards: Bool = false) {
        // Bounded identifier-based scrolling; XCTest waits for each gesture to settle.
        if element.waitForExistence(timeout: 5), element.isHittable { return }
        let scroll = app.scrollViews.firstMatch
        XCTAssertTrue(scroll.waitForExistence(timeout: 5))
        for _ in 0..<12 {
            if upwards { scroll.swipeDown() } else { scroll.swipeUp() }
            if element.waitForExistence(timeout: 1), element.isHittable { return }
        }
        XCTFail("Could not reveal \(element) within twelve scroll gestures")
    }
}
