// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "StorageScopeCore",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "StorageScopeCore", targets: ["StorageScopeCore"])
    ],
    targets: [
        .target(
            name: "AuthorizationShim",
            path: "StorageScope/Core/AuthorizationShim",
            publicHeadersPath: "include"
        ),
        .target(
            name: "StorageScopeCore",
            dependencies: ["AuthorizationShim"],
            path: "StorageScope/Core",
            exclude: ["AuthorizationShim"],
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "StorageScopeCoreTests",
            dependencies: ["StorageScopeCore", "AuthorizationShim"],
            path: "Tests/StorageScopeCoreTests"
        )
    ]
)
