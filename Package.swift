// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "Inkwell",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "Inkwell",
            dependencies: [],
            path: "Sources/Inkwell",
            resources: [
                .copy("Resources/editor.html")
            ]
        ),
    ]
)
