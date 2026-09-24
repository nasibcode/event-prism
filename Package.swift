// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "EventPrism",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
    ],
    products: [
        .library(name: "EventPrism", targets: ["EventPrism"]),
    ],
    targets: [
        .target(
            name: "EventPrism",
            resources: [
                .copy("Catalog.schema.json"),
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
        .testTarget(
            name: "EventPrismTests",
            dependencies: ["EventPrism"],
            resources: [
                .copy("Fixtures"),
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
    ]
)
