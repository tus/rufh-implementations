/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A dependency of the sample code project.
*/
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2023 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import XCTest
import NIOCore
import NIOEmbedded
import NIOHTTP1
import HTTPTypes
import HTTPTypesNIO
import HTTPTypesNIOHTTP1

/// A handler that keeps track of all reads made on a channel.
private final class InboundRecorder<Frame>: ChannelInboundHandler {
    typealias InboundIn = Frame

    var receivedFrames: [Frame] = []

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        self.receivedFrames.append(self.unwrapInboundIn(data))
    }
}

private extension HTTPField.Name {
    static let xFoo = Self("X-Foo")!
}

final class HTTPTypesNIOHTTP1Tests: XCTestCase {
    var channel: EmbeddedChannel!

    override func setUp() {
        super.setUp()
        self.channel = EmbeddedChannel()
    }

    override func tearDown() {
        self.channel = nil
        super.tearDown()
    }

    static let request = HTTPRequest(method: .get, scheme: "https", authority: "www.example.com", path: "/", headerFields: [
        .accept: "*/*",
        .acceptEncoding: "gzip",
        .acceptEncoding: "br",
        .cookie: "a=b",
        .cookie: "c=d",
        .trailer: "X-Foo"
    ])

    static let requestNoSplitCookie = HTTPRequest(method: .get, scheme: "https", authority: "www.example.com", path: "/", headerFields: [
        .accept: "*/*",
        .acceptEncoding: "gzip",
        .acceptEncoding: "br",
        .cookie: "a=b; c=d",
        .trailer: "X-Foo"
    ])

    static let oldRequest = HTTPRequestHead(version: .http1_1, method: .GET, uri: "/", headers: [
        "Host": "www.example.com",
        "Accept": "*/*",
        "Accept-Encoding": "gzip",
        "Accept-Encoding": "br",
        "Cookie": "a=b; c=d",
        "Trailer": "X-Foo"
    ])

    static let response = HTTPResponse(status: .ok, headerFields: [
        .server: "HTTPServer/1.0",
        .trailer: "X-Foo"
    ])

    static let oldResponse = HTTPResponseHead(version: .http1_1, status: .ok, headers: [
        "Server": "HTTPServer/1.0",
        "Trailer": "X-Foo"
    ])

    static let trailers: HTTPFields = [.xFoo: "Bar"]

    static let oldTrailers: HTTPHeaders = ["X-Foo": "Bar"]

    func testClientHTTP1ToHTTP() throws {
        let recorder = InboundRecorder<HTTPTypeClientResponsePart>()

        try self.channel.pipeline.addHandlers(HTTP1ToHTTPClientCodec(), recorder).wait()

        try self.channel.writeOutbound(HTTPTypeClientRequestPart.head(Self.request))
        try self.channel.writeOutbound(HTTPTypeClientRequestPart.end(Self.trailers))

        XCTAssertEqual(try self.channel.readOutbound(as: HTTPClientRequestPart.self), .head(Self.oldRequest))
        XCTAssertEqual(try self.channel.readOutbound(as: HTTPClientRequestPart.self), .end(Self.oldTrailers))

        try self.channel.writeInbound(HTTPClientResponsePart.head(Self.oldResponse))
        try self.channel.writeInbound(HTTPClientResponsePart.end(Self.oldTrailers))

        XCTAssertEqual(recorder.receivedFrames[0], .head(Self.response))
        XCTAssertEqual(recorder.receivedFrames[1], .end(Self.trailers))

        XCTAssertTrue(try channel.finish().isClean)
    }

    func testServerHTTP1ToHTTP() throws {
        let recorder = InboundRecorder<HTTPTypeServerRequestPart>()

        try self.channel.pipeline.addHandlers(HTTP1ToHTTPServerCodec(secure: true), recorder).wait()

        try self.channel.writeInbound(HTTPServerRequestPart.head(Self.oldRequest))
        try self.channel.writeInbound(HTTPServerRequestPart.end(Self.oldTrailers))

        XCTAssertEqual(recorder.receivedFrames[0], .head(Self.requestNoSplitCookie))
        XCTAssertEqual(recorder.receivedFrames[1], .end(Self.trailers))

        try self.channel.writeOutbound(HTTPTypeServerResponsePart.head(Self.response))
        try self.channel.writeOutbound(HTTPTypeServerResponsePart.end(Self.trailers))

        XCTAssertEqual(try self.channel.readOutbound(as: HTTPServerResponsePart.self), .head(Self.oldResponse))
        XCTAssertEqual(try self.channel.readOutbound(as: HTTPServerResponsePart.self), .end(Self.oldTrailers))

        XCTAssertTrue(try channel.finish().isClean)
    }

    func testClientHTTPToHTTP1() throws {
        let recorder = InboundRecorder<HTTPClientResponsePart>()

        try self.channel.pipeline.addHandlers(HTTPToHTTP1ClientCodec(secure: true), recorder).wait()

        try self.channel.writeOutbound(HTTPClientRequestPart.head(Self.oldRequest))
        try self.channel.writeOutbound(HTTPClientRequestPart.end(Self.oldTrailers))

        XCTAssertEqual(try self.channel.readOutbound(as: HTTPTypeClientRequestPart.self), .head(Self.request))
        XCTAssertEqual(try self.channel.readOutbound(as: HTTPTypeClientRequestPart.self), .end(Self.trailers))

        try self.channel.writeInbound(HTTPTypeClientResponsePart.head(Self.response))
        try self.channel.writeInbound(HTTPTypeClientResponsePart.end(Self.trailers))

        XCTAssertEqual(recorder.receivedFrames[0], .head(Self.oldResponse))
        XCTAssertEqual(recorder.receivedFrames[1], .end(Self.oldTrailers))

        XCTAssertTrue(try channel.finish().isClean)
    }

    func testServerHTTPToHTTP1() throws {
        let recorder = InboundRecorder<HTTPServerRequestPart>()

        try self.channel.pipeline.addHandlers(HTTPToHTTP1ServerCodec(), recorder).wait()

        try self.channel.writeInbound(HTTPTypeServerRequestPart.head(Self.request))
        try self.channel.writeInbound(HTTPTypeServerRequestPart.end(Self.trailers))

        XCTAssertEqual(recorder.receivedFrames[0], .head(Self.oldRequest))
        XCTAssertEqual(recorder.receivedFrames[1], .end(Self.oldTrailers))

        try self.channel.writeOutbound(HTTPServerResponsePart.head(Self.oldResponse))
        try self.channel.writeOutbound(HTTPServerResponsePart.end(Self.oldTrailers))

        XCTAssertEqual(try self.channel.readOutbound(as: HTTPTypeServerResponsePart.self), .head(Self.response))
        XCTAssertEqual(try self.channel.readOutbound(as: HTTPTypeServerResponsePart.self), .end(Self.trailers))

        XCTAssertTrue(try channel.finish().isClean)
    }
}
