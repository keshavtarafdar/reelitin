// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "GodotPlugin",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        // Defines the dynamic library that will be built for Godot
        .library(
            name: "GodotPlugin",
            type: .dynamic,
            targets: ["GodotPlugin"]
        ),
    ],
    dependencies: [
        // Main SwiftGodot dependency
        .package(url: "https://github.com/migueldeicaza/SwiftGodot", branch: "main")
    ],
    targets: [
        .target(
            name: "GodotPlugin",
            dependencies: [
                .product(name: "SwiftGodot", package: "SwiftGodot")
            ],
            swiftSettings: [
                .unsafeFlags(["-suppress-warnings"])
            ]
        ),
    ]
)
