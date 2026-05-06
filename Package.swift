// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "The Friendly Fitness Companion",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "The Friendly Fitness Companion",
            targets: ["The Friendly Fitness Companion"]),
    ],
    targets: [
        .target(
            name: "The Friendly Fitness Companion",
            path: "The Friendly Fitness Companion/The Friendly Fitness Companion",
            exclude: [
                "Assets.xcassets",
                "Info.plist",
                "Preview Content"
            ]
        )
    ]
)
