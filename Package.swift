// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftUIPagingCollection",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "SwiftUIPagingCollection",
            targets: ["SwiftUIPagingCollection"]),
    ],
    targets: [
        .target(
            name: "SwiftUIPagingCollection"),
        .testTarget(
            name: "SwiftUIPagingCollectionTests",
            dependencies: ["SwiftUIPagingCollection"]),
    ]
)
