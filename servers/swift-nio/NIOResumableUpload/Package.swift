// swift-tools-version: 5.7
/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Package declaration.
*/

import PackageDescription

let package = Package(
    name: "swift-nio-resumable-upload",
    products: [
        .library(name: "NIOResumableUpload", targets: ["NIOResumableUpload"]),
    ],
    dependencies: [
        .package(path: "Dependencies/NIOHTTPTypes"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.53.0"),
        .package(url: "https://github.com/apple/swift-http-types", exact: "0.1.1"),
        .package(url: "https://github.com/apple/swift-http-structured-headers.git", from: "0.3.0"),
        .package(url: "https://github.com/apple/swift-atomics.git", from: "1.1.0"),
    ],
    targets: [
        .target(
            name: "NIOResumableUpload",
            dependencies: [
                .product(name: "HTTPTypes", package: "swift-http-types"),
                .product(name: "NIOHTTPTypes", package: "NIOHTTPTypes"),
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "StructuredFieldValues", package: "swift-http-structured-headers"),
                .product(name: "Atomics", package: "swift-atomics"),
            ]),
        .testTarget(
            name: "NIOResumableUploadTests",
            dependencies: [
                "NIOResumableUpload",
                .product(name: "NIOEmbedded", package: "swift-nio"),
            ]),
    ]
)
