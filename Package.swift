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
        .executable(name: "AtlasScanApp", targets: ["AtlasScanApp"]),
    ],
    targets: [
        .target(
            name: "AtlasScan",
            path: "Sources/AtlasScan"
        ),
        .executableTarget(
            name: "AtlasScanApp",
            dependencies: ["AtlasScan"],
            path: "Sources/AtlasScanApp"
        ),
        .testTarget(
            name: "AtlasScanTests",
            dependencies: ["AtlasScan"],
            path: "Tests/AtlasScanTests"
        ),
    ]
)
