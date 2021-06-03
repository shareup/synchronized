// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "Synchronized",
    platforms: [
        .macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v5),
    ],
    products: [
        .library(
            name: "Synchronized",
            targets: ["Synchronized"]),
    ],
    dependencies: [ ],
    targets: [
        .target(
            name: "Synchronized",
            dependencies: []),
        .testTarget(
            name: "SynchronizedTests",
            dependencies: ["Synchronized"]),
    ]
)
