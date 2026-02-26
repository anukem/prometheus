// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Parchment",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-markdown.git", branch: "main"),
    ],
    targets: [
        .executableTarget(
            name: "Parchment",
            dependencies: [
                .product(name: "Markdown", package: "swift-markdown"),
            ],
            path: "Sources/Parchment",
            exclude: ["Info.plist"],
            resources: [
                .process("Resources"),
            ]
        ),
        .testTarget(
            name: "ParchmentTests",
            dependencies: ["Parchment"],
            path: "Tests/ParchmentTests"
        ),
    ]
)
