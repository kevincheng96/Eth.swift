// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Eth",
    platforms: [
        .macOS(.v10_15),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Eth",
            targets: ["Eth"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/attaswift/BigInt.git", from: "5.3.0"),
        .package(url: "https://github.com/bitflying/SwiftKeccak.git", from: "0.1.0"),
        .package(url: "https://github.com/apple/swift-syntax.git", from: "510.0.2"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Eth",
            dependencies: ["BigInt", "SwiftKeccak"]
        ),
        .target(
            name: "ABIGen",
            dependencies: [
                "Eth",
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
            ]
        ),
        .testTarget(
            name: "EthTests",
            dependencies: ["Eth"]
        ),
        .testTarget(
            name: "ABIGenTests",
            dependencies: ["ABIGen", "Eth"]
        ),
    ]
)
