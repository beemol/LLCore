// swift-tools-version: 6.0.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LLCore",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15) // macOS Catalina or newer
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "LLCore",
            targets: ["LLCore"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/beemol/LLApiService.git", branch: "main")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "LLCore",
            dependencies: [.product(name: "LLApiService", package: "LLApiService")]
        ),
        .testTarget(
            name: "LLCoreTests",
            dependencies: ["LLCore"]
        ),
    ]
)
