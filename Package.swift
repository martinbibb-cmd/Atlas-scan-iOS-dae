// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AtlasScan",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "AtlasScan", targets: ["AtlasScan"]),
    ],
    targets: [
        .target(
            name: "AtlasScan",
            path: "Sources/AtlasScan"
        ),
        .testTarget(
            name: "AtlasScanTests",
            dependencies: ["AtlasScan"],
            path: "Tests/AtlasScanTests"
        ),
    ]
)
