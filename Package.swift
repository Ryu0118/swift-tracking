// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Tracking",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Tracking",
            targets: ["Tracking"]),
        .executable(
            name: "TrackingBenchmarks",
            targets: ["TrackingBenchmarks"]),
    ],
    dependencies: [
        .package(url: "https://github.com/google/swift-benchmark", from: "0.1.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Tracking"
        ),
        .executableTarget(
            name: "TrackingBenchmarks",
            dependencies: [
                "Tracking",
                .product(name: "Benchmark", package: "swift-benchmark")
            ]
        ),
        .testTarget(
            name: "TrackingTests",
            dependencies: ["Tracking"]
        ),
    ]
)
