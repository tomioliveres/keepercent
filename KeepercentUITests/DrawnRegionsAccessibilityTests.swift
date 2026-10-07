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
        assertEntryGoal(in: app)

        reveal(app.buttons["court.entry.sevenMeters"], in: app)
        assertCourt(in: app, scope: "court.entry")
    }

    func testDrawingScaffoldActivationsReachExistingCallbacks() throws {
        let app = openDrawingScaffold()
        assertEntryGoal(in: app)
        for (code, name) in goalContract {
            let region = app.buttons[entryIdentifier(for: code)]
            XCTAssertTrue(region.waitForExistence(timeout: 5))
            XCTAssertEqual(region.label, name)
            XCTAssertTrue(region.isHittable)
            region.tap()
            XCTAssertTrue(app.staticTexts["Last tap: \(code)"].waitForExistence(timeout: 5))
        }
        assertCourt(in: app, scope: "court.entry")
        let courtNames = [
            "zone.leftWing.near": "Court, left wing, near",
            "zone.leftBack.near": "Court, left back, near",
            "zone.center.near": "Court, center, near",
            "zone.rightBack.near": "Court, right back, near",
            "zone.rightWing.near": "Court, right wing, near",
            "zone.leftBack.far": "Court, left back, far",
            "zone.center.far": "Court, center, far",
            "zone.rightBack.far": "Court, right back, far",
            "sevenMeters": "7 m mark"
        ]
        for region in regions(in: app, prefix: "court.entry.") {
            let code = String(region.identifier.dropFirst("court.entry.".count))
            XCTAssertTrue(region.exists)
            XCTAssertEqual(region.elementType, .button)
            XCTAssertEqual(region.label, courtNames[code])
            // The scaffold supplies no tallies or notes: no sample is exposed.
            // Do not require a particular nil versus empty-string AX encoding.
            XCTAssertTrue(region.value == nil || (region.value as? String) == "",
                          "Unexpected scaffold sample: \(String(describing: region.value))")
        }
        let canvas = try assertCourtFrames(in: app, scope: "court.entry")
        let postControl = app.buttons[entryIdentifier(for: "post.leftPostTop")]
        // The aspect-fitted court can be height-limited on iPad, so compare centers rather than edges.
        XCTAssertEqual(canvas.midX, postControl.frame.midX, accuracy: 1)
        XCTAssertLessThanOrEqual(canvas.width, postControl.frame.width + 1)
        XCTAssertGreaterThan(canvas.minY, postControl.frame.maxY)
        // Court AX buttons are semantic representations; XCUI taps are physical.
        // Explicit interior touches verify classification and callbacks here;
        // VoiceOver semantic activation must be checked separately.
        // Fixtures have independent polygon proof in the read-only Domain
        // CourtGeometryTestsCanvasOracle.physicalTargetContract regression.
        for (code, normalized) in [
            ("zone.leftWing.near", CGPoint(x: 0.075, y: 0.15)),
            ("sevenMeters", CGPoint(x: 0.5, y: 7.0 / 15)),
            ("zone.rightBack.far", CGPoint(x: 0.8, y: 0.8))
        ] {
            let region = app.buttons["court.entry.\(code)"]
            let point = CGPoint(x: canvas.minX + canvas.width * normalized.x,
                                y: canvas.minY + canvas.height * normalized.y)
            let xMeters = (normalized.x - 0.5) * 20
            let yMeters = normalized.y * 15
            let angle = atan2(xMeters, yMeters) * 180 / .pi
            let nearestPostDistance = hypot(abs(xMeters) - 1.5, yMeters)
            let lastTap = app.staticTexts["Last tap: \(code)"]
            let evidence = [region, postControl, app.otherElements["testCanvas.court.entry"]]
            let callbackAlreadyExists = lastTap.exists
            retainEvidence("Court before physical touch: \(code); canvas=\(canvas), normalized=\(normalized), point=\(point), metric=(\(xMeters), \(yMeters)), angle=\(angle), distance=\(nearestPostDistance), expected Last tap exists=\(callbackAlreadyExists)",
                           in: app, elements: evidence + (callbackAlreadyExists ? [lastTap] : []))
            // Goal and court readings are independent; goal taps cannot reset
            // this reading. Distinct codes plus absence reject stale success.
            XCTAssertFalse(callbackAlreadyExists)
            XCTAssertTrue(region.waitForExistence(timeout: 5))
            XCTAssertTrue(canvas.contains(point))
            XCTAssertTrue(region.frame.contains(point))
            XCTAssertGreaterThan(point.x, region.frame.minX)
            XCTAssertLessThan(point.x, region.frame.maxX)
            XCTAssertGreaterThan(point.y, region.frame.minY)
            XCTAssertLessThan(point.y, region.frame.maxY)
            switch code {
            case "zone.leftWing.near":
                XCTAssertLessThan(angle, -54)
                XCTAssertGreaterThan(nearestPostDistance, 6)
                XCTAssertLessThan(nearestPostDistance, 9)
            case "sevenMeters":
                XCTAssertGreaterThan(xMeters, -0.7)
                XCTAssertLessThan(xMeters, 0.7)
                XCTAssertGreaterThan(yMeters, 6.5)
                XCTAssertLessThan(yMeters, 7.5)
            default: // Right-back far, not the bounding-box center.
                XCTAssertGreaterThan(angle, 18)
                XCTAssertLessThan(angle, 54)
                XCTAssertGreaterThan(nearestPostDistance, 9)
            }
            tap(point, in: app)
            let callbackReached = lastTap.waitForExistence(timeout: 5)
            retainEvidence("Court after physical touch: \(code); callback=\(callbackReached), canvas=\(canvas), normalized=\(normalized), point=\(point)",
                           in: app, elements: evidence + (callbackReached ? [lastTap] : []))
            XCTAssertTrue(callbackReached)
            XCTAssertEqual(lastTap.label, "Last tap: \(code)")
        }
        // Separately retain the complete nine-origin physical regression.
        for (code, point) in [
            ("zone.leftWing.near", CGPoint(x: 0.075, y: 0.15)),
            ("zone.leftBack.near", CGPoint(x: 0.25, y: 0.4)),
            ("zone.center.near", CGPoint(x: 0.5, y: 0.55)),
            ("zone.rightBack.near", CGPoint(x: 0.75, y: 0.4)),
            ("zone.rightWing.near", CGPoint(x: 0.925, y: 0.15)),
            ("zone.leftBack.far", CGPoint(x: 0.2, y: 0.8)),
            ("zone.center.far", CGPoint(x: 0.5, y: 0.8)),
            ("zone.rightBack.far", CGPoint(x: 0.8, y: 0.8)),
            ("sevenMeters", CGPoint(x: 0.5, y: 7.0 / 15))
        ] {
            tap(CGPoint(x: canvas.minX + point.x * canvas.width,
                        y: canvas.minY + point.y * canvas.height), in: app)
            XCTAssertTrue(app.staticTexts["Last tap: \(code)"].waitForExistence(timeout: 5))
        }
    }

    func testRelocatedLeftPostTopIsSingleSizedSeparatedActionAndPreservesDrawingTap() throws {
        let app = openDrawingScaffold()
        assertEntryGoal(in: app)
        let control = app.buttons[entryIdentifier(for: "post.leftPostTop")]
        _ = try assertCourtFrames(in: app, scope: "court.entry")
        let neighbours = regions(in: app, prefix: "goal.entry.")
            + regions(in: app, prefix: "court.entry.") + [app.buttons["Close"]]
        retainEvidence("Relocated post before size and overlap checks", in: app, elements: [control] + neighbours)
        XCTAssertTrue(control.isHittable)
        XCTAssertGreaterThanOrEqual(control.frame.width, 44)
        XCTAssertGreaterThanOrEqual(control.frame.height, 44)
        for neighbour in neighbours {
            let intersection = control.frame.intersection(neighbour.frame)
            XCTAssertFalse(intersection.width > 0 && intersection.height > 0,
                           "Relocated control overlaps \(neighbour.identifier): \(neighbour.frame)")
        }
        app.buttons["goal.entry.inside.top.right"].tap()
        XCTAssertTrue(app.staticTexts["Last tap: inside.top.right"].waitForExistence(timeout: 5))
        control.tap()
        XCTAssertTrue(app.staticTexts["Last tap: post.leftPostTop"].waitForExistence(timeout: 5))

        // Use the surviving post's x and the top inside cell's y. This is
        // the original physical strip, not the relocated accessible button.
        app.buttons["goal.entry.inside.top.right"].tap()
        XCTAssertTrue(app.staticTexts["Last tap: inside.top.right"].waitForExistence(timeout: 5))
        let post = app.buttons["goal.entry.post.leftPostMiddle"].frame
        let top = app.buttons["goal.entry.inside.top.left"].frame
        tap(CGPoint(x: post.midX, y: top.midY), in: app)
        XCTAssertTrue(app.staticTexts["Last tap: post.leftPostTop"].waitForExistence(timeout: 5))
        retainEvidence("Relocated post and physical-strip callback", in: app, elements: [control] + neighbours)
    }

    func testScoutingRenderedQueryGroupsGoalBeforeCourt() {
        let app = launch(screen: "scouting")
        reveal(app.staticTexts["goal.linked.inside.top.left"], in: app)
        reveal(app.buttons["court.linked.sevenMeters"], in: app)
        assertInertGoal(in: app, scope: "goal.linked")
        assertCourt(in: app, scope: "court.linked")
        let goals = regions(in: app, prefix: "goal.linked.")
        let goalHeading = app.staticTexts["Effectiveness"]
        let courtHeading = app.staticTexts["Origin"]
        let mark = app.buttons["court.linked.sevenMeters"]
        XCTAssertTrue(goalHeading.exists)
        XCTAssertTrue(courtHeading.exists)
        retainEvidence("Field grouping geometry", in: app, elements: [goalHeading, courtHeading, mark] + goals)
        // Retained iPad hierarchies interleave inflated court button frames.
        // Verify the field goal sits between its heading and the court's
        // heading, followed by the precisely framed mark; not flat query order
        // and not spoken VoiceOver traversal or a court-frame repair.
        XCTAssertLessThan(goalHeading.frame.maxY, courtHeading.frame.minY)
        for goal in goals {
            XCTAssertGreaterThanOrEqual(goal.frame.minY, goalHeading.frame.maxY)
            XCTAssertLessThanOrEqual(goal.frame.maxY, courtHeading.frame.minY)
        }
        XCTAssertLessThan(courtHeading.frame.maxY, mark.frame.minY)
    }

    func testShooterSamplesAndLinkedFilterSelectClear() throws {
        let app = launch(screen: "shooterCard", canvasProbe: true) // Existing router selects Jordi Ferrer (#3).
        XCTAssertTrue(app.staticTexts["#3 · Jordi Ferrer"].waitForExistence(timeout: 10))
        let goal = app.staticTexts["goal.linked.inside.top.right"]
        reveal(goal, in: app)
        assertValue("0 goals in 1 shot", of: goal)
        assertInertGoal(in: app, scope: "goal.linked")

        let origin = app.buttons["court.linked.zone.rightBack.far"]
        reveal(origin, in: app)
        assertValue("0 goals in 1 shot", of: origin) // The located miss still counts for effectiveness.
        try tapRightBackFar(in: app)
        assertFilter("From right back · far · 1 shot", in: app)
        reveal(goal, in: app, upwards: true)
        assertValue("No data", of: goal)
        reveal(origin, in: app)
        try tapRightBackFar(in: app)
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
        retainEvidence("Zero-shot keeper before original 7 m tap", in: app,
                       elements: origins + [app.staticTexts["linked.filter"]])
        app.buttons["court.linked.sevenMeters"].tap()
        assertFilter("7 m throws · 0 shots", in: app)
        reveal(app.staticTexts["7 m: no shots"].firstMatch, in: app)
        XCTAssertTrue(regions(in: app, prefix: "goal.penalty.").isEmpty)
    }

    func testAccessibilityAuditOnSettledSessions() throws {
        let app = launch(screen: "sessions")
        reveal(app.buttons["goal.entry.inside.top.left"], in: app)
        retainEvidence("Sessions pre-audit top-left drawing", in: app,
                       elements: [app.buttons["goal.entry.inside.top.left"]])
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
        retainEvidence("Keeper pre-audit field and 7 m viewport", in: app,
                       elements: [app.staticTexts["goal.linked.inside.bottom.left"], app.buttons["court.linked.sevenMeters"]])
        try app.performAccessibilityAudit()
    }

    func testAccessibilityAuditOnSettledZeroShotGoalkeeper() throws {
        let app = launch(screen: "goalkeeperCard", data: "emptyGoalkeeper")
        reveal(app.staticTexts["goal.linked.inside.top.left"], in: app)
        try app.performAccessibilityAudit()
    }

    private func launch(screen: String, data: String = "demo", canvasProbe: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-KPScreen", screen, "-KPData", data,
            "-AppleLanguages", "(en)", "-AppleLocale", "en_US"
        ]
        if canvasProbe { app.launchArguments.append("-KPUITestCanvasProbe") }
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
        return app
    }

    private func regions(in app: XCUIApplication, prefix: String) -> [XCUIElement] {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH %@", prefix))
            .allElementsBoundByIndex
    }

    private func openDrawingScaffold() -> XCUIApplication {
        let app = launch(screen: "teams", data: "empty", canvasProbe: true)
        let scaffold = app.buttons["Drawing Scaffold (T2.x)"]
        // Exact native label from the retained 42f66bb iPad Teams hierarchy.
        let sidebar = app.buttons["Show Sidebar"]
        retainScaffoldNavigationEvidence("Before sidebar navigation", in: app)
        if sidebar.exists && sidebar.isHittable { sidebar.tap() }
        if !scaffold.waitForExistence(timeout: 3) || !scaffold.isHittable {
            let more = app.buttons["More"].firstMatch
            retainScaffoldNavigationEvidence("Before More navigation", in: app)
            XCTAssertTrue(more.waitForExistence(timeout: 5))
            more.tap()
        }
        retainScaffoldNavigationEvidence("Before scaffold selection", in: app)
        XCTAssertTrue(scaffold.waitForExistence(timeout: 5))
        scaffold.tap()
        let closeExists = app.buttons["Close"].waitForExistence(timeout: 5)
        // Retain the failed presentation state before continueAfterFailure
        // aborts. The retained iPad-dark run does not establish a bad query,
        // wrong toolbar target or slow sheet; do not guess a navigation fix.
        retainScaffoldNavigationEvidence("After scaffold selection: Close exists=\(closeExists)", in: app)
        XCTAssertTrue(closeExists)
        return app
    }

    private func retainScaffoldNavigationEvidence(_ stage: String, in app: XCUIApplication) {
        let labels = ["Show Sidebar", "More", "Drawing Scaffold (T2.x)", "Close"]
        let candidates = labels.flatMap { label in
            app.buttons.matching(NSPredicate(format: "label == %@", label)).allElementsBoundByIndex
        }
        let counts = labels.map { label in
            "\(label)=\(app.buttons.matching(NSPredicate(format: "label == %@", label)).count)"
        }
        let readiness = candidates.map { "\($0.label): hittable=\($0.isHittable)" }
        retainEvidence("Scaffold navigation: \(stage); \(counts.joined(separator: ", ")); \(readiness.joined(separator: ", "))",
                       in: app, elements: candidates)
    }

    private var goalContract: [(code: String, name: String)] {
        var result: [(String, String)] = []
        for row in ["top", "middle", "bottom"] {
            for column in ["left", "center", "right"] {
                result.append(("inside.\(row).\(column)", "Goal, \(row) \(column)"))
            }
        }
        result += [
            ("post.leftPostTop", "Left post, top"),
            ("post.leftPostMiddle", "Left post, middle"),
            ("post.leftPostBottom", "Left post, bottom"),
            ("post.crossbarLeft", "Crossbar, left"),
            ("post.crossbarCenter", "Crossbar, center"),
            ("post.crossbarRight", "Crossbar, right"),
            ("post.rightPostTop", "Right post, top"),
            ("post.rightPostMiddle", "Right post, middle"),
            ("post.rightPostBottom", "Right post, bottom")
        ]
        for (direction, name) in [("wideLeft", "wide left"), ("wideRight", "wide right"), ("over", "over")] {
            for part in direction == "over" ? ["left", "center", "right"] : ["top", "middle", "bottom"] {
                result.append(("out.\(direction).\(part)", "Miss, \(name), \(part)"))
            }
        }
        return result
    }

    private func entryIdentifier(for code: String) -> String {
        code == "post.leftPostTop" ? "goalSupplementary.goal.entry.leftPostTop" : "goal.entry.\(code)"
    }

    private func assertEntryGoal(in app: XCUIApplication) {
        let actions = regions(in: app, prefix: "goal.entry.")
            + regions(in: app, prefix: "goalSupplementary.goal.entry.")
        XCTAssertEqual(goalContract.count, 27)
        XCTAssertEqual(actions.count, 27)
        XCTAssertTrue(actions.allSatisfy { $0.elementType == .button })
        XCTAssertEqual(Set(actions.map(\.identifier)), Set(goalContract.map { entryIdentifier(for: $0.code) }))
        XCTAssertEqual(Set(actions.map(\.label)), Set(goalContract.map(\.name)))
        XCTAssertEqual(Set(actions.map(\.label)).count, 27)
        XCTAssertFalse(app.descendants(matching: .any)["goal.entry.post.leftPostTop"].exists)
        for (code, name) in goalContract {
            let matches = app.buttons.matching(identifier: entryIdentifier(for: code))
            XCTAssertEqual(matches.count, 1)
            assertLabel(name, of: matches.element(boundBy: 0))
        }
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "label == %@", "Left post, top")).count, 1)
    }

    private func tapRightBackFar(in app: XCUIApplication) throws {
        let mark = app.buttons["court.linked.sevenMeters"]
        reveal(mark, in: app)
        var canvas = try measuredCanvas(in: app, scope: "court.linked")
        func point(in canvas: CGRect) -> CGPoint {
            CGPoint(x: canvas.minX + canvas.width * 0.8, y: canvas.minY + canvas.height * 0.8)
        }
        let scroll = app.scrollViews.firstMatch
        for _ in 0..<12 {
            if scroll.frame.insetBy(dx: 0, dy: 44).contains(point(in: canvas)) { break }
            scroll.swipeUp()
            // Requery current telemetry after every settled scroll; no cached
            // mark position, small-region scale, fallback or recovery retry.
            canvas = try measuredCanvas(in: app, scope: "court.linked")
        }
        let target = point(in: canvas)
        let far = app.buttons["court.linked.zone.rightBack.far"]
        retainEvidence("Right-back far raw canvas=\(canvas), target=\(target)", in: app,
                       elements: [mark, far, app.descendants(matching: .any)["testCanvas.court.linked"]])
        let xMeters = ((target.x - canvas.minX) / canvas.width - 0.5) * 20
        let yMeters = (target.y - canvas.minY) / canvas.height * 15
        let angle = atan2(xMeters, yMeters) * 180 / .pi
        XCTAssertGreaterThan(angle, 18)
        XCTAssertLessThan(angle, 54)
        XCTAssertGreaterThan(hypot(xMeters - 1.5, yMeters), 9)
        XCTAssertTrue(canvas.contains(target))
        XCTAssertTrue(far.frame.contains(target))
        XCTAssertGreaterThan(target.x, far.frame.minX)
        XCTAssertLessThan(target.x, far.frame.maxX)
        XCTAssertGreaterThan(target.y, far.frame.minY)
        XCTAssertLessThan(target.y, far.frame.maxY)
        XCTAssertTrue(scroll.frame.insetBy(dx: 0, dy: 44).contains(target))
        tap(target, in: app)
    }

    private func tap(_ point: CGPoint, in app: XCUIApplication) {
        XCTAssertTrue(app.frame.contains(point))
        app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: point.x, dy: point.y)).tap()
    }

    private func retainEvidence(_ name: String, in app: XCUIApplication, elements: [XCUIElement]) {
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "\(name) — viewport"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        let details = elements.map { "\($0.identifier) | \($0.label) | frame=\($0.frame) | value=\(String(describing: $0.value))" }
        let hierarchy = XCTAttachment(string: details.joined(separator: "\n") + "\n" + app.debugDescription)
        hierarchy.name = "\(name) — frames and hierarchy"
        hierarchy.lifetime = .keepAlways
        add(hierarchy)
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

    /// Independent metric expectations for CourtGeometry.standard's polygon
    /// extrema. Raw canvas telemetry supplies scale, never a rounded AX region.
    /// One point of tolerance covers XCTest's screen-coordinate rounding.
    @discardableResult
    private func assertCourtFrames(in app: XCUIApplication, scope: String) throws -> CGRect {
        let mark = app.buttons["\(scope).sevenMeters"]
        let origins = regions(in: app, prefix: "\(scope).")
        // Capture every frame BEFORE the mark-size assertion can abort.
        // Its semantic bounds represent the 1.4 x 1 m drawing/hit region,
        // not the intrinsic height of an unrendered Text button label.
        retainEvidence("Court frames before metric assertions", in: app, elements: origins)
        let canvas = try measuredCanvas(in: app, scope: scope)
        let width = canvas.width
        let height = canvas.height
        func arcPoint(distance: CGFloat, degrees: CGFloat) -> CGPoint {
            let angle = degrees * .pi / 180
            // Intersection of the sector ray with the post-centered arc.
            let radius = 1.5 * sin(angle)
                + sqrt(distance * distance - 2.25 * cos(angle) * cos(angle))
            return CGPoint(x: radius * sin(angle), y: radius * cos(angle))
        }
        let inner18 = arcPoint(distance: 6, degrees: 18)
        let inner54 = arcPoint(distance: 6, degrees: 54)
        let outer18 = arcPoint(distance: 9, degrees: 18)
        let outer54 = arcPoint(distance: 9, degrees: 54)
        let wing = CGRect(x: 0, y: 0, width: 0.5 - inner54.x / 20, height: outer54.y / 15)
        let back = CGRect(x: 0.5 - outer54.x / 20, y: inner54.y / 15,
                          width: (outer54.x - inner18.x) / 20,
                          height: (outer18.y - inner54.y) / 15)
        let center = CGRect(x: 0.5 - outer18.x / 20, y: inner18.y / 15,
                            width: outer18.x / 10, height: (9 - inner18.y) / 15)
        let farBack = CGRect(x: 0, y: 0, width: 0.5 - outer18.x / 20, height: 1)
        let farHalfWidth = 15 * tan(CGFloat.pi / 10) / 20
        let farCenter = CGRect(x: 0.5 - farHalfWidth, y: outer18.y / 15,
                               width: 2 * farHalfWidth, height: 1 - outer18.y / 15)
        func mirrored(_ rect: CGRect) -> CGRect {
            CGRect(x: 1 - rect.maxX, y: rect.minY, width: rect.width, height: rect.height)
        }
        let expected: [(String, CGRect)] = [
            ("zone.leftWing.near", wing), ("zone.leftBack.near", back),
            ("zone.center.near", center), ("zone.rightBack.near", mirrored(back)),
            ("zone.rightWing.near", mirrored(wing)), ("zone.leftBack.far", farBack),
            ("zone.center.far", farCenter), ("zone.rightBack.far", mirrored(farBack)),
            ("sevenMeters", CGRect(x: 0.465, y: 6.5 / 15, width: 1.4 / 20, height: 1.0 / 15))
        ]
        let comparisons = expected.map { code, rect in
            let raw = CGRect(x: canvas.minX + rect.minX * width, y: canvas.minY + rect.minY * height,
                             width: rect.width * width, height: rect.height * height)
            return "\(code): expected=\(raw), actual=\(app.buttons["\(scope).\(code)"].frame)"
        }.joined(separator: "; ")
        retainEvidence("Court raw canvas=\(canvas); \(comparisons)", in: app,
                       elements: origins + [app.descendants(matching: .any)["testCanvas.\(scope)"]])
        XCTAssertTrue(mark.exists)
        XCTAssertEqual(app.buttons.matching(identifier: "\(scope).sevenMeters").count, 1)
        XCTAssertEqual(mark.label, "7 m mark")
        XCTAssertGreaterThan(mark.frame.width, 0)
        XCTAssertEqual(mark.frame.height, height / 15, accuracy: 1)
        XCTAssertEqual(origins.count, expected.count)
        for (code, normalized) in expected {
            let frame = app.buttons["\(scope).\(code)"].frame
            XCTAssertGreaterThan(frame.width, 0, code)
            XCTAssertGreaterThan(frame.height, 0, code)
            XCTAssertGreaterThanOrEqual(frame.minX, canvas.minX - 1, code)
            XCTAssertGreaterThanOrEqual(frame.minY, canvas.minY - 1, code)
            XCTAssertLessThanOrEqual(frame.maxX, canvas.maxX + 1, code)
            XCTAssertLessThanOrEqual(frame.maxY, canvas.maxY + 1, code)
            XCTAssertEqual(frame.minX, canvas.minX + normalized.minX * width, accuracy: 1, code)
            XCTAssertEqual(frame.minY, canvas.minY + normalized.minY * height, accuracy: 1, code)
            XCTAssertEqual(frame.width, normalized.width * width, accuracy: 1, code)
            XCTAssertEqual(frame.height, normalized.height * height, accuracy: 1, code)
        }
        return canvas
    }

    private enum CanvasMeasurementError: Error { case unavailable(String) }

    /// Fail closed before any coordinate can be synthesized. No AX-frame or
    /// small-mark fallback; the value is native raw global-frame telemetry.
    private func measuredCanvas(in app: XCUIApplication, scope: String) throws -> CGRect {
        let id = "testCanvas.\(scope)"
        let probes = app.descendants(matching: .any).matching(identifier: id).allElementsBoundByIndex
        retainEvidence("Canvas telemetry before qualification: \(id), count=\(probes.count)",
                       in: app, elements: probes)
        guard probes.count == 1, let probe = probes.first,
              probe.elementType != .button,
              let value = probe.value as? String else {
            XCTFail("Expected one nonactionable canvas probe with numeric value: \(id)")
            throw CanvasMeasurementError.unavailable(id)
        }
        let fields = value.split(separator: ",", omittingEmptySubsequences: false)
        let numbers = fields.compactMap { Double($0) }
        guard fields.count == 4, numbers.count == 4, numbers.allSatisfy(\.isFinite),
              numbers[2] > 0, numbers[3] > 0,
              abs(numbers[2] / numbers[3] - 20.0 / 15) < 1e-6 else {
            XCTFail("Invalid/pending canvas telemetry for \(id): \(value)")
            throw CanvasMeasurementError.unavailable(id)
        }
        return CGRect(x: numbers[0], y: numbers[1], width: numbers[2], height: numbers[3])
    }

    private func assertInertGoal(in app: XCUIApplication, scope: String) {
        let goals = regions(in: app, prefix: "\(scope).")
        XCTAssertEqual(goals.count, 27)
        XCTAssertTrue(goals.allSatisfy { $0.elementType == .staticText })
        XCTAssertEqual(Set(goals.map(\.identifier)), Set(goalContract.map { "\(scope).\($0.code)" }))
        XCTAssertEqual(Set(goals.map(\.label)), Set(goalContract.map(\.name)))
        for (code, name) in goalContract { assertLabel(name, of: app.staticTexts["\(scope).\(code)"]) }
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
        retainEvidence("Filter expectation: \(expected)", in: app,
                       elements: [caption, app.buttons["court.linked.sevenMeters"]])
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", expected), object: caption)
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: 5), .completed)
        XCTAssertEqual(caption.label, expected)
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
