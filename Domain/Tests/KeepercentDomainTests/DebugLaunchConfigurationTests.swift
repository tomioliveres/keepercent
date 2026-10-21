import Testing
@testable import KeepercentDomain

@Suite("Debug launch configuration")
struct DebugLaunchConfigurationTests {
    @Test("The orphan-session fixture opens Matches without falling back to demo")
    func orphanSessionVerificationMode() {
        let configuration = DebugLaunchConfiguration.parse(screen: nil, data: "orphanSession")
        #expect(configuration?.screen == .teams)
        #expect(configuration?.data.rawValue == "orphanSession")
    }

    @Test("The own-roster verification mode does not fall back to rival-only demo")
    func ownRosterVerificationMode() {
        let configuration = DebugLaunchConfiguration.parse(screen: nil, data: "demoOwnRoster")
        #expect(configuration?.screen == .teams)
        #expect(configuration?.data.rawValue == "demoOwnRoster")
    }

    @Test("No arguments preserve the normal launch")
    func noArguments() {
        #expect(DebugLaunchConfiguration.parse(screen: nil, data: nil) == nil)
    }

    @Test("Every screen is selectable", arguments: [
        ("teams", DebugLaunchScreen.teams),
        ("sessions", .sessions),
        ("scouting", .scouting),
        ("shooterCard", .shooterCard),
        ("goalkeeperCard", .goalkeeperCard)
    ])
    func screenValues(raw: String, expected: DebugLaunchScreen) {
        #expect(DebugLaunchConfiguration.parse(screen: raw, data: "demo")?.screen == expected)
    }

    @Test("All data modes are selectable without conflating empty stores", arguments: [
        ("demo", DebugLaunchData.demo), ("demoOwnRoster", .demoOwnRoster), ("empty", .empty),
        ("emptyGoalkeeper", .emptyGoalkeeper), ("orphanSession", .orphanSession)
    ])
    func dataValues(raw: String, expected: DebugLaunchData) {
        #expect(DebugLaunchConfiguration.parse(screen: "teams", data: raw)?.data == expected)
    }

    @Test("The zero-shot goalkeeper fixture retains the goalkeeper card route")
    func emptyGoalkeeperRoute() {
        let configuration = DebugLaunchConfiguration.parse(
            screen: "goalkeeperCard", data: "emptyGoalkeeper"
        )
        #expect(configuration?.screen == .goalkeeperCard)
        #expect(configuration?.data == .emptyGoalkeeper)
    }

    @Test("A missing or unknown screen falls back to teams")
    func screenFallback() {
        #expect(DebugLaunchConfiguration.parse(screen: nil, data: "empty")?.screen == .teams)
        #expect(DebugLaunchConfiguration.parse(screen: "unknown", data: "demo")?.screen == .teams)
        #expect(DebugLaunchConfiguration.parse(screen: "Teams", data: nil)?.screen == .teams)
    }

    @Test("A missing or unknown data value falls back to demo")
    func dataFallback() {
        #expect(DebugLaunchConfiguration.parse(screen: "sessions", data: nil)?.data == .demo)
        #expect(DebugLaunchConfiguration.parse(screen: "sessions", data: "unknown")?.data == .demo)
        #expect(DebugLaunchConfiguration.parse(screen: nil, data: "Empty")?.data == .demo)
        #expect(DebugLaunchConfiguration.parse(screen: nil, data: "DemoOwnRoster")?.data == .demo)
    }
}
