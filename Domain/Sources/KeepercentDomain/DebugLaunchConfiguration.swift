/// Parsed values of the optional debug-only launch arguments. The app reads
/// UserDefaults; the domain only interprets its strings.
public enum DebugLaunchScreen: String, Sendable {
    case teams, sessions, scouting, shooterCard, goalkeeperCard
}

public enum DebugLaunchData: String, Sendable {
    case demo, empty
}

public struct DebugLaunchConfiguration: Equatable, Sendable {
    public let screen: DebugLaunchScreen
    public let data: DebugLaunchData

    /// Without either argument the app keeps its normal persistent store.
    /// Invalid values use safe, deterministic defaults rather than routing
    /// into a missing screen or an unexpected store.
    public static func parse(screen: String?, data: String?) -> Self? {
        guard screen != nil || data != nil else { return nil }
        return Self(
            screen: screen.flatMap(DebugLaunchScreen.init(rawValue:)) ?? .teams,
            data: data.flatMap(DebugLaunchData.init(rawValue:)) ?? .demo
        )
    }
}
