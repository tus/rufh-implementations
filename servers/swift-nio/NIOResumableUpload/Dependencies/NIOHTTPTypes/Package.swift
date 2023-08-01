// swift-tools-version: 5.7
/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A dependency of the sample code project.
*/

import PackageDescription

let package = Package(
    name: "swift-nio-extras",
    products: [
        .library(name: "NIOHTTPTypes", targets: ["NIOHTTPTypes"]),
        .library(name: "NIOHTTPTypesHTTP1", targets: ["NIOHTTPTypesHTTP1"]),
        .library(name: "NIOHTTPTypesHTTP2", targets: ["NIOHTTPTypesHTTP2"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-http-types", from: "0.1.1"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.55.0"),
        .package(url: "https://github.com/apple/swift-nio-http2.git", from: "1.27.0"),
    ],
    targets: [
        .target(
            name: "NIOHTTPTypes",
            dependencies: [
                .product(name: "HTTPTypes", package: "swift-http-types"),
                .product(name: "NIOCore", package: "swift-nio"),
            ]),
        .target(
            name: "NIOHTTPTypesHTTP1",
            dependencies: [
                "NIOHTTPTypes",
                .product(name: "NIOHTTP1", package: "swift-nio"),
            ]),
        .target(
            name: "NIOHTTPTypesHTTP2",
            dependencies: [
                "NIOHTTPTypes",
                .product(name: "NIOHTTP2", package: "swift-nio-http2"),
            ]),
        .testTarget(
            name: "NIOHTTPTypesHTTP1Tests",
            dependencies: [
                "NIOHTTPTypesHTTP1",
            ]),
        .testTarget(
            name: "NIOHTTPTypesHTTP2Tests",
            dependencies: [
                "NIOHTTPTypesHTTP2",
            ]),
    ]
)
