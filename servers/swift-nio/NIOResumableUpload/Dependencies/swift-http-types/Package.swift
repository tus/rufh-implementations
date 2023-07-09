// swift-tools-version: 5.8
/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A dependency of the sample code project.
*/

import PackageDescription

let package = Package(
    name: "http-types",
    products: [
        .library(name: "HTTPTypes", targets: ["HTTPTypes"]),
        .library(name: "HTTPTypesNIO", targets: ["HTTPTypesNIO"]),
        .library(name: "HTTPTypesNIOHTTP1", targets: ["HTTPTypesNIOHTTP1"]),
        .library(name: "HTTPTypesNIOHTTP2", targets: ["HTTPTypesNIOHTTP2"]),
        .library(name: "HTTPTypesFoundation", targets: ["HTTPTypesFoundation"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.53.0"),
        .package(url: "https://github.com/apple/swift-nio-http2.git", from: "1.26.0"),
    ],
    targets: [
        .target(name: "HTTPTypes"),
        .target(
            name: "HTTPTypesNIO",
            dependencies: [
                "HTTPTypes",
                .product(name: "NIOCore", package: "swift-nio"),
            ]),
        .target(
            name: "HTTPTypesNIOHTTP1",
            dependencies: [
                "HTTPTypesNIO",
                .product(name: "NIOHTTP1", package: "swift-nio"),
            ]),
        .target(
            name: "HTTPTypesNIOHTTP2",
            dependencies: [
                "HTTPTypesNIO",
                .product(name: "NIOHTTP2", package: "swift-nio-http2"),
            ]),
        .target(
            name: "HTTPTypesFoundation",
            dependencies: [
                "HTTPTypes",
            ]),
        .testTarget(
            name: "HTTPTypesTests",
            dependencies: [
                "HTTPTypes",
            ]),
        .testTarget(
            name: "HTTPTypesNIOHTTP1Tests",
            dependencies: [
                "HTTPTypesNIOHTTP1",
            ]),
        .testTarget(
            name: "HTTPTypesNIOHTTP2Tests",
            dependencies: [
                "HTTPTypesNIOHTTP2",
            ]),
        .testTarget(
            name: "HTTPTypesFoundationTests",
            dependencies: [
                "HTTPTypesFoundation",
            ]),
    ]
)
