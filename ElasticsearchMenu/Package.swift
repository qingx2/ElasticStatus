// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "ElasticsearchMenu",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "ElasticsearchMenu",
            path: "Sources"
        )
    ]
)
