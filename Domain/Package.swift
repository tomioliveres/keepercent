// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "KeepercentDomain",
    platforms: [
        .iOS(.v26),
        .macOS(.v26)
    ],
    products: [
        .library(
            name: "KeepercentDomain",
            targets: ["KeepercentDomain"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "KeepercentDomain",
            dependencies: []
        ),
        .testTarget(
            name: "KeepercentDomainTests",
            dependencies: ["KeepercentDomain"]
        )
    ]
)
