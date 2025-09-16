// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "carsxe",
    platforms: [
        .macOS(.v12), 
        .iOS(.v15), 
        .tvOS(.v15), 
        .watchOS(.v8)
    ],
    products: [
        .library(
            name: "carsxe",
            targets: ["carsxe"]
        ),
    ],
    dependencies: [
        // No external dependencies needed
    ],
    targets: [
        .target(
            name: "carsxe",
            dependencies: []
        ),
        .testTarget(
            name: "carsxeTests",
            dependencies: ["carsxe"]
        ),
    ]
)