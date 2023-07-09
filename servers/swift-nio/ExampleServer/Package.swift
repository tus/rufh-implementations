// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ExampleServer",
    platforms: [
        .macOS(.v10_15),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.0.0"),
        .package(url: "https://github.com/apple/swift-nio-transport-services.git", from: "1.13.0"),
        .package(path: "../NIOResumableUpload"),
        .package(path: "../NIOResumableUpload/Dependencies/swift-http-types"),
    ],

    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "ExampleServer",
            dependencies: [
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOHTTP1", package: "swift-nio"),
                .product(name: "NIOTransportServices", package: "swift-nio-transport-services"),
                .product(name: "NIOResumableUpload", package: "NIOResumableUpload"),
                .product(name: "HTTPTypesNIOHTTP1", package: "swift-http-types"),
                .product(name: "HTTPTypesNIO", package: "swift-http-types"),
                .product(name: "HTTPTypes", package: "swift-http-types"),
            ],
            path: "Sources"),
    ]
)
