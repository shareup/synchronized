// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "Synchronized",
    platforms: [
        .macOS(.v11), .iOS(.v14), .tvOS(.v14), .watchOS(.v7),
    ],
    products: [
        .library(
            name: "Synchronized",
            targets: ["Synchronized"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Synchronized",
            dependencies: []
        ),
        .testTarget(
            name: "SynchronizedTests",
            dependencies: ["Synchronized"]
        ),
    ]
)
