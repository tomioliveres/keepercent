// swift-tools-version: 6.2
import PackageDescription

// Development-only disk compatibility harness. This package is not linked by
// the iOS project and depends only on Apple's SDK and the local Domain package.
let package = Package(
    name: "StoreCompatibility",
    platforms: [.macOS(.v26)],
    dependencies: [.package(path: "Domain")],
    targets: [
        .executableTarget(name: "LegacyStore", path: "Tools/StoreCompatibility/Legacy"),
        .target(name: "ProductionStore", dependencies: [.product(name: "KeepercentDomain", package: "Domain")],
                path: "Keepercent/Persistence", exclude: ["DemoDataSeeder.swift", "ScopedMatchData.swift"],
                sources: ["StoredRivalTeam.swift", "StoredPlayer.swift", "StoredSession.swift", "StoredShot.swift",
                          "StoredMatchParticipant.swift", "MatchHistoryUpgrade.swift", "KeepercentSchema.swift"]),
        .testTarget(name: "StoreCompatibilityTests", dependencies: ["ProductionStore"], path: "Tools/StoreCompatibility/Tests")
    ],
    swiftLanguageModes: [.v5]
)
