// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "Appwrite",
    products: [
        .library(
            name: "Appwrite",
            targets: [
                "Appwrite",
                "AppwriteEnums",
                "AppwriteModels",
                "JSONCodable"
            ]
        ),
    ],
    dependencies: [
        // WASM-incompatible NIO dependencies removed
    ],
    targets: [
        .target(
            name: "Appwrite",
            dependencies: [
                "AppwriteModels",
                "AppwriteEnums",
                "JSONCodable"
            ]
        ),
        .target(
            name: "AppwriteModels",
            dependencies: [
                "AppwriteEnums",
                "JSONCodable"
            ]
        ),
        .target(
            name: "AppwriteEnums"
        ),
        .target(
            name: "JSONCodable"
        ),
        .testTarget(
            name: "AppwriteTests",
            dependencies: [
                "Appwrite"
            ]
        )
    ],
    swiftLanguageVersions: [.v5]
)